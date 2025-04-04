import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

import 'package:flutter_chat_app/core/services/connectivity_service.dart';
import 'package:flutter_chat_app/core/services/local_storage_service.dart';
import 'package:flutter_chat_app/core/services/media_cache.dart';
import 'package:flutter_chat_app/domain/entities/attachment_queue_status.dart';
import 'package:flutter_chat_app/domain/entities/message_error_type.dart';
import 'package:flutter_chat_app/domain/events/message_queue_event.dart';
import 'package:flutter_chat_app/domain/models/message_queue_metrics.dart';
import 'package:flutter_chat_app/domain/models/queued_attachment.dart';
import 'package:flutter_chat_app/domain/repositories/i_attachment_repository.dart';

/// Lớp triển khai hàng đợi tập tin đính kèm
@lazySingleton
class AttachmentQueueService {
  /// Số lần thử lại tối đa trước khi đánh dấu lỗi vĩnh viễn
  static const int _maxRetryCount = 5;
  
  /// Thời gian trễ cơ bản giữa các lần thử lại (ms)
  static const int _baseRetryDelayMs = 2000;
  
  /// Thời gian trễ tối đa giữa các lần thử lại (ms)
  static const int _maxRetryDelayMs = 120000; // 2 phút
  
  /// Kích thước lô tối đa để xử lý tập tin đính kèm
  static const int _maxBatchSize = 3;
  
  /// Khóa lưu trữ cho việc lưu hàng đợi
  static const String _storageKey = 'attachment_queue';
  
  /// Dung lượng tối đa cho một tập tin để có thể tải lên đồng thời (5MB)
  static const int _maxConcurrentUploadSize = 5 * 1024 * 1024;
  
  /// Repository để tương tác với server
  final IAttachmentRepository _attachmentRepository;
  
  /// Service kết nối mạng
  final ConnectivityService _connectivityService;
  
  /// Service lưu trữ cục bộ
  final LocalStorageService _localStorageService;
  
  /// Service quản lý cache media
  final MediaCache _mediaCache;
  
  /// Danh sách các attachment đang chờ xử lý
  final List<QueuedAttachment> _pendingAttachments = [];
  
  /// Danh sách các attachment đang được xử lý
  final Map<String, QueuedAttachment> _processingAttachments = {};
  
  /// Stream controller cho việc cập nhật trạng thái
  final _attachmentStatusController = BehaviorSubject<QueuedAttachment>();
  
  /// Stream controller cho việc phát sự kiện
  final _eventController = BehaviorSubject<MessageQueueEvent>();
  
  /// Timer xử lý hàng đợi
  Timer? _processingTimer;
  
  /// Cờ đánh dấu đang xử lý
  bool _isProcessing = false;
  
  /// Cờ đánh dấu hàng đợi bị tạm dừng
  bool _isPaused = false;
  
  /// Đối tượng theo dõi metrics
  final MessageQueueMetrics _metrics = MessageQueueMetrics();
  
  /// Các upload đang hoạt động
  final Map<String, StreamSubscription> _activeUploads = {};
  
  /// Các download đang hoạt động
  final Map<String, StreamSubscription> _activeDownloads = {};
  
  /// Cờ đánh dấu đã khởi tạo
  bool _initialized = false;
  
  /// Constructor
  AttachmentQueueService(
    this._attachmentRepository, 
    this._connectivityService,
    this._localStorageService,
    this._mediaCache,
  );
  
  /// Stream cập nhật trạng thái tập tin đính kèm
  Stream<QueuedAttachment> get attachmentStatusStream => 
      _attachmentStatusController.stream;
      
  /// Stream sự kiện từ hàng đợi
  Stream<MessageQueueEvent> get events => _eventController.stream;
  
  /// Metrics hiện tại
  MessageQueueMetrics get metrics => _metrics;
  
  /// Khởi tạo service
  Future<void> initialize() async {
    if (_initialized) return;
    
    await _restoreQueue();
    
    // Bắt đầu xử lý hàng đợi
    _startProcessingQueue();
    
    _initialized = true;
  }
  
  /// Thêm tập tin đính kèm vào hàng đợi
  Future<String> enqueueAttachment({
    required String messageId,
    required String chatId,
    required String filePath,
    required AttachmentType type,
  }) async {
    // Tạo attachment mới
    final attachment = QueuedAttachment.create(
      messageId: messageId,
      chatId: chatId,
      filePath: filePath,
      type: type,
    );
    
    // Thêm vào danh sách chờ
    _pendingAttachments.add(attachment);
    
    // Cập nhật metrics
    _metrics.recordEnqueued();
    
    // Thông báo sự kiện
    _notifyAttachmentStatusChanged(attachment);
    _emitEvent(MessageQueueEventType.attachmentEnqueued, 
      attachmentId: attachment.localId,
      messageId: messageId,
    );
    
    // Lưu hàng đợi
    await _saveQueue();
    
    // Đảm bảo xử lý được bắt đầu
    _ensureProcessing();
    
    return attachment.localId;
  }
  
  /// Khôi phục hàng đợi từ bộ nhớ cục bộ
  Future<void> _restoreQueue() async {
    try {
      final queueJsonString = _localStorageService.getString(_storageKey);
      
      if (queueJsonString != null) {
        final queueData = jsonDecode(queueJsonString) as List<dynamic>;
        
        // Khôi phục attachments
        for (final attachmentData in queueData) {
          try {
            final attachment = QueuedAttachment.fromMap(
              Map<String, dynamic>.from(attachmentData));
            
            // Kiểm tra xem file còn tồn tại không
            final file = File(attachment.filePath);
            if (!file.existsSync()) {
              debugPrint('File không tồn tại, bỏ qua: ${attachment.filePath}');
              continue;
            }
            
            // Đặt lại trạng thái đang xử lý về chờ xử lý
            if (attachment.status == AttachmentQueueStatus.uploading || 
                attachment.status == AttachmentQueueStatus.downloading) {
              _pendingAttachments.add(attachment.copyWith(
                status: AttachmentQueueStatus.pending,
                updatedAt: DateTime.now(),
              ));
            } else if (!attachment.isTerminal) {
              _pendingAttachments.add(attachment);
            }
          } catch (e) {
            debugPrint('Lỗi phân tích attachment: $e');
          }
        }
        
        debugPrint('Đã khôi phục ${_pendingAttachments.length} attachments');
      }
    } catch (e) {
      debugPrint('Lỗi khôi phục hàng đợi attachment: $e');
    }
  }
  
  /// Lưu hàng đợi vào bộ nhớ cục bộ
  Future<void> _saveQueue() async {
    try {
      // Kết hợp cả danh sách chờ và đang xử lý
      final allAttachments = [..._pendingAttachments, ..._processingAttachments.values];
      
      // Chỉ lưu các attachment chưa hoàn thành
      final incompleteAttachments = allAttachments
          .where((a) => !a.isTerminal)
          .toList();
      
      final attachmentJsonList = incompleteAttachments
          .map((a) => a.toMap())
          .toList();
      
      final queueJson = jsonEncode(attachmentJsonList);
      
      // Lưu vào bộ nhớ
      await _localStorageService.setString(_storageKey, queueJson);
    } catch (e) {
      debugPrint('Lỗi lưu hàng đợi attachment: $e');
    }
  }
  
  /// Tổng kích thước đang xử lý
  int get _processingSize {
    int total = 0;
    for (final attachment in _processingAttachments.values) {
      total += attachment.fileSize;
    }
    return total;
  }
  
  /// Bắt đầu xử lý hàng đợi
  void _startProcessingQueue() {
    if (_processingTimer != null) {
      _processingTimer!.cancel();
    }
    
    // Xử lý hàng đợi mỗi 2 giây
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processQueue();
    });
    
    // Xử lý ngay lập tức
    _processQueue();
  }
  
  /// Dừng xử lý hàng đợi
  void _stopProcessingQueue() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }
  
  /// Đảm bảo bắt đầu xử lý
  void _ensureProcessing() {
    if (!_isProcessing && !_isPaused) {
      _processQueue();
    }
  }
  
  /// Xử lý hàng đợi
  Future<void> _processQueue() async {
    // Bỏ qua nếu đã đang xử lý hoặc bị tạm dừng
    if (_isProcessing || _isPaused) return;
    
    _isProcessing = true;
    
    try {
      // Kiểm tra kết nối mạng
      final isConnected = await _connectivityService.checkNetworkStatus();
      if (!isConnected) {
        debugPrint('Không có kết nối mạng, bỏ qua xử lý hàng đợi');
        
        // Đánh dấu các attachment đang xử lý sang trạng thái chờ mạng
        _updateAttachmentsWaitingForNetwork();
        
        return;
      }
      
      // Xử lý các attachment sẵn sàng
      await _processReadyAttachments();
      
      // Kiểm tra các lần thử lại đã lên lịch
      _checkScheduledRetries();
      
    } catch (e) {
      debugPrint('Lỗi xử lý hàng đợi: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  /// Đánh dấu các attachment đang xử lý sang trạng thái chờ mạng
  void _updateAttachmentsWaitingForNetwork() {
    final keys = _processingAttachments.keys.toList();
    for (final key in keys) {
      final attachment = _processingAttachments[key]!;
      
      // Tạm dừng các upload/download đang chạy
      _activeUploads[key]?.cancel();
      _activeUploads.remove(key);
      
      _activeDownloads[key]?.cancel();
      _activeDownloads.remove(key);
      
      // Cập nhật trạng thái
      final updatedAttachment = attachment.copyWith(
        status: AttachmentQueueStatus.waitingForNetwork,
        updatedAt: DateTime.now()
      );
      
      // Đưa về danh sách chờ
      _processingAttachments.remove(key);
      _pendingAttachments.add(updatedAttachment);
      
      // Thông báo thay đổi trạng thái
      _notifyAttachmentStatusChanged(updatedAttachment);
    }
  }
  
  /// Xử lý các attachment sẵn sàng
  Future<void> _processReadyAttachments() async {
    // Thời gian hiện tại
    final now = DateTime.now();
    
    // Lấy danh sách các attachment sẵn sàng xử lý
    final readyAttachments = _pendingAttachments
        .where((a) => a.status == AttachmentQueueStatus.pending ||
            (a.status == AttachmentQueueStatus.waitingForNetwork) ||
            (a.status == AttachmentQueueStatus.failed && 
             a.nextRetryTime != null && 
             a.nextRetryTime!.isBefore(now)))
        .toList();
    
    // Sắp xếp theo ưu tiên: Retry trước, sau đó là các attachment nhỏ hơn
    readyAttachments.sort((a, b) {
      // Ưu tiên các lần thử lại
      final retryComp = b.retryCount.compareTo(a.retryCount);
      if (retryComp != 0) return retryComp;
      
      // Sau đó ưu tiên các file nhỏ hơn
      return a.fileSize.compareTo(b.fileSize);
    });
    
    // Giới hạn số lượng attachment xử lý đồng thời dựa trên kích thước
    final availableAttachments = <QueuedAttachment>[];
    int totalSize = _processingSize;
    
    for (final attachment in readyAttachments) {
      // Kiểm tra xem có đủ dung lượng xử lý không
      if (_processingAttachments.length < _maxBatchSize && 
          (totalSize + attachment.fileSize <= _maxConcurrentUploadSize || 
           attachment.fileSize <= 100 * 1024)) { // Luôn cho phép file < 100KB
        
        availableAttachments.add(attachment);
        totalSize += attachment.fileSize;
        
        // Đạt giới hạn tối đa
        if (availableAttachments.length >= _maxBatchSize) {
          break;
        }
      }
    }
    
    // Xử lý các attachment sẵn sàng
    for (final attachment in availableAttachments) {
      // Xóa khỏi danh sách chờ
      _pendingAttachments.remove(attachment);
      
      // Xử lý tập tin
      await _processAttachment(attachment);
    }
  }
  
  /// Kiểm tra các lần thử lại đã lên lịch
  void _checkScheduledRetries() {
    final now = DateTime.now();
    
    // Tìm các attachment đã lên lịch thử lại
    final retryAttachments = _pendingAttachments
        .where((a) => a.status == AttachmentQueueStatus.failed && 
                      a.nextRetryTime != null && 
                      a.nextRetryTime!.isBefore(now))
        .toList();
        
    if (retryAttachments.isNotEmpty) {
      debugPrint('Tìm thấy ${retryAttachments.length} attachments cần thử lại');
      _ensureProcessing();
    }
  }
  
  /// Xử lý một tập tin đính kèm
  Future<void> _processAttachment(QueuedAttachment attachment) async {
    // Cập nhật trạng thái thành đang tải lên
    final updatedAttachment = attachment.copyWith(
      status: AttachmentQueueStatus.uploading,
      progress: 0.0,
      updatedAt: DateTime.now(),
    );
    
    // Thêm vào danh sách đang xử lý
    _processingAttachments[updatedAttachment.localId] = updatedAttachment;
    
    // Cập nhật metrics
    _metrics.recordProcessingStarted();
    
    // Thông báo trạng thái đã thay đổi
    _notifyAttachmentStatusChanged(updatedAttachment);
    _emitEvent(MessageQueueEventType.attachmentUploading, 
      attachmentId: updatedAttachment.localId,
      messageId: updatedAttachment.messageId,
    );
    
    // Bắt đầu thời gian đo
    final startTime = DateTime.now();
    
    try {
      // Kiểm tra xem file còn tồn tại không
      if (!updatedAttachment.fileExists) {
        throw FileSystemException('File không tồn tại');
      }
      
      // Tải tập tin lên server
      final result = await _uploadAttachment(updatedAttachment);
      
      // Cập nhật thời gian hoàn thành
      final duration = DateTime.now().difference(startTime);
      _metrics.addAttachmentUploadDuration(duration);
      
      // Đánh dấu thành công
      final successAttachment = updatedAttachment.copyWith(
        status: AttachmentQueueStatus.uploaded,
        serverId: result.id,
        serverUrl: result.url,
        progress: 1.0,
        updatedAt: DateTime.now(),
      );
      
      // Xóa khỏi danh sách đang xử lý
      _processingAttachments.remove(updatedAttachment.localId);
      
      // Cập nhật metrics
      _metrics.recordSuccess(sendDuration: duration);
      _metrics.recordProcessingCompleted();
      
      // Thông báo thành công
      _notifyAttachmentStatusChanged(successAttachment);
      _emitEvent(MessageQueueEventType.attachmentUploaded,
        attachmentId: successAttachment.localId,
        messageId: successAttachment.messageId,
        serverId: successAttachment.serverId,
      );
      
      debugPrint('Tải lên attachment thành công: ${successAttachment.localId}');
      
      // Lưu vào cache để sử dụng sau này
      await _cacheAttachment(successAttachment);
      
    } catch (e, stackTrace) {
      debugPrint('Lỗi tải lên attachment: $e');
      debugPrint(stackTrace.toString());
      
      // Phân loại lỗi
      final errorType = _categorizeError(e);
      
      // Tăng số lần thử lại
      final retryCount = updatedAttachment.retryCount + 1;
      
      // Kiểm tra xem đã đạt giới hạn thử lại chưa
      if (retryCount >= _maxRetryCount) {
        // Đánh dấu lỗi vĩnh viễn
        final failedAttachment = updatedAttachment.copyWith(
          status: AttachmentQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Lỗi sau $retryCount lần thử: $e',
          errorType: errorType,
          updatedAt: DateTime.now(),
        );
        
        // Xóa khỏi danh sách đang xử lý
        _processingAttachments.remove(updatedAttachment.localId);
        
        // Cập nhật metrics
        _metrics.recordFailure(errorType);
        _metrics.recordProcessingCompleted();
        
        // Thông báo thất bại
        _notifyAttachmentStatusChanged(failedAttachment);
        _emitEvent(MessageQueueEventType.attachmentFailed,
          attachmentId: failedAttachment.localId,
          messageId: failedAttachment.messageId,
          error: failedAttachment.errorMessage,
          errorType: errorType,
        );
        
        debugPrint('Attachment lỗi vĩnh viễn: ${failedAttachment.localId}');
      } else {
        // Lên lịch thử lại với độ trễ tăng dần
        final delayMs = _calculateRetryDelay(retryCount, errorType);
        final nextRetryTime = DateTime.now().add(Duration(milliseconds: delayMs));
        
        // Cập nhật thông tin thử lại
        final retryAttachment = updatedAttachment.copyWith(
          status: AttachmentQueueStatus.failed,
          retryCount: retryCount,
          errorMessage: 'Thử lại $retryCount: $e',
          errorType: errorType,
          nextRetryTime: nextRetryTime,
          updatedAt: DateTime.now(),
        );
        
        // Xóa khỏi danh sách đang xử lý
        _processingAttachments.remove(updatedAttachment.localId);
        
        // Thêm lại vào danh sách chờ
        _pendingAttachments.add(retryAttachment);
        
        // Cập nhật metrics
        _metrics.recordRetry();
        _metrics.recordProcessingCompleted();
        
        // Thông báo thử lại
        _notifyAttachmentStatusChanged(retryAttachment);
        _emitEvent(MessageQueueEventType.messageRetryScheduled,
          attachmentId: retryAttachment.localId,
          messageId: retryAttachment.messageId,
          scheduledTime: nextRetryTime,
          errorType: errorType,
          error: retryAttachment.errorMessage,
        );
        
        debugPrint('Attachment lên lịch thử lại: ${retryAttachment.localId} lúc $nextRetryTime');
      }
    }
    
    // Lưu trạng thái hàng đợi
    await _saveQueue();
  }
  
  /// Tải tập tin lên server với cập nhật tiến độ
  Future<AttachmentUploadResult> _uploadAttachment(QueuedAttachment attachment) async {
    final completer = Completer<AttachmentUploadResult>();
    
    try {
      // Lấy file
      final file = File(attachment.filePath);
      if (!file.existsSync()) {
        throw FileSystemException('File không tồn tại: ${attachment.filePath}');
      }
      
      // Tải lên với cập nhật tiến độ
      final uploadStream = _attachmentRepository.uploadAttachment(
        messageId: attachment.messageId, 
        chatId: attachment.chatId,
        file: file,
        onProgress: (progress) {
          // Cập nhật tiến độ
          final updatedAttachment = attachment.copyWith(
            progress: progress,
            updatedAt: DateTime.now(),
          );
          
          // Cập nhật trong danh sách đang xử lý
          _processingAttachments[attachment.localId] = updatedAttachment;
          
          // Thông báo tiến độ
          _notifyAttachmentStatusChanged(updatedAttachment);
          _emitEvent(MessageQueueEventType.attachmentProgressUpdated,
            attachmentId: attachment.localId,
            messageId: attachment.messageId,
            progress: progress,
          );
        },
      );
      
      // Theo dõi tải lên
      final subscription = uploadStream.listen(
        (result) {
          if (!completer.isCompleted) {
            completer.complete(result);
          }
          
          // Xóa khỏi danh sách uploads đang hoạt động
          _activeUploads.remove(attachment.localId);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
          
          // Xóa khỏi danh sách uploads đang hoạt động
          _activeUploads.remove(attachment.localId);
        },
        cancelOnError: true,
      );
      
      // Lưu subscription để có thể hủy nếu cần
      _activeUploads[attachment.localId] = subscription;
      
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      return await completer.future;
    }
  }
  
  /// Lưu attachment vào cache
  Future<void> _cacheAttachment(QueuedAttachment attachment) async {
    try {
      if (attachment.serverUrl != null && attachment.fileExists) {
        // Tạo key cho cache
        final cacheKey = 'attachment_${attachment.serverId}';
        
        // Đọc file
        final file = File(attachment.filePath);
        
        // Lưu vào cache
        await _mediaCache.putFile(cacheKey, file);
        
        debugPrint('Đã lưu attachment vào cache: $cacheKey');
      }
    } catch (e) {
      debugPrint('Lỗi cache attachment: $e');
    }
  }
  
  /// Thử lại tải lên attachment
  Future<bool> retryAttachment(String attachmentId) async {
    // Tìm attachment
    final attachmentIndex = _pendingAttachments.indexWhere((a) => a.localId == attachmentId);
    if (attachmentIndex == -1) return false;
    
    final attachment = _pendingAttachments[attachmentIndex];
    
    // Chỉ có thể thử lại các attachment bị lỗi
    if (attachment.status != AttachmentQueueStatus.failed && 
        attachment.status != AttachmentQueueStatus.waitingForNetwork) {
      return false;
    }
    
    // Cập nhật để thử lại
    final retryAttachment = attachment.copyWith(
      status: AttachmentQueueStatus.pending,
      updatedAt: DateTime.now(),
    );
    
    // Cập nhật trong danh sách
    _pendingAttachments[attachmentIndex] = retryAttachment;
    
    // Thông báo thay đổi trạng thái
    _notifyAttachmentStatusChanged(retryAttachment);
    
    // Lưu hàng đợi
    await _saveQueue();
    
    // Đảm bảo xử lý
    _ensureProcessing();
    
    return true;
  }
  
  /// Hủy attachment
  Future<bool> cancelAttachment(String attachmentId) async {
    // Tìm trong danh sách chờ
    final pendingIndex = _pendingAttachments.indexWhere((a) => a.localId == attachmentId);
    
    // Tìm trong danh sách đang xử lý
    final isProcessing = _processingAttachments.containsKey(attachmentId);
    
    // Không tìm thấy
    if (pendingIndex == -1 && !isProcessing) return false;
    
    if (pendingIndex >= 0) {
      // Lấy từ danh sách chờ
      final attachment = _pendingAttachments[pendingIndex];
      
      // Xóa khỏi danh sách
      _pendingAttachments.removeAt(pendingIndex);
      
      // Cập nhật trạng thái
      final cancelledAttachment = attachment.copyWith(
        status: AttachmentQueueStatus.cancelled,
        errorMessage: 'Đã hủy bởi người dùng',
        updatedAt: DateTime.now(),
      );
      
      // Thông báo thay đổi trạng thái
      _notifyAttachmentStatusChanged(cancelledAttachment);
      _emitEvent(MessageQueueEventType.attachmentFailed,
        attachmentId: cancelledAttachment.localId,
        messageId: cancelledAttachment.messageId,
        error: cancelledAttachment.errorMessage,
      );
    } else if (isProcessing) {
      // Lấy từ danh sách đang xử lý
      final attachment = _processingAttachments[attachmentId]!;
      
      // Hủy upload đang chạy
      if (_activeUploads.containsKey(attachmentId)) {
        _activeUploads[attachmentId]?.cancel();
        _activeUploads.remove(attachmentId);
      }
      
      // Hủy download đang chạy
      if (_activeDownloads.containsKey(attachmentId)) {
        _activeDownloads[attachmentId]?.cancel();
        _activeDownloads.remove(attachmentId);
      }
      
      // Xóa khỏi danh sách
      _processingAttachments.remove(attachmentId);
      
      // Cập nhật trạng thái
      final cancelledAttachment = attachment.copyWith(
        status: AttachmentQueueStatus.cancelled,
        errorMessage: 'Đã hủy bởi người dùng',
        updatedAt: DateTime.now(),
      );
      
      // Thông báo thay đổi trạng thái
      _notifyAttachmentStatusChanged(cancelledAttachment);
      _emitEvent(MessageQueueEventType.attachmentFailed,
        attachmentId: cancelledAttachment.localId,
        messageId: cancelledAttachment.messageId,
        error: cancelledAttachment.errorMessage,
      );
      
      // Cập nhật metrics
      _metrics.recordProcessingCompleted();
    }
    
    // Lưu hàng đợi
    await _saveQueue();
    
    return true;
  }
  
  /// Lấy tất cả attachment trong hàng đợi
  List<QueuedAttachment> getAllAttachments() {
    return [..._pendingAttachments, ..._processingAttachments.values];
  }
  
  /// Lấy tất cả attachment cho một tin nhắn
  List<QueuedAttachment> getAttachmentsForMessage(String messageId) {
    return getAllAttachments()
        .where((a) => a.messageId == messageId)
        .toList();
  }
  
  /// Lấy trạng thái của một attachment
  QueuedAttachment? getAttachmentById(String attachmentId) {
    // Tìm trong danh sách chờ
    final pendingAttachment = _pendingAttachments
        .firstWhere((a) => a.localId == attachmentId, orElse: () => null as QueuedAttachment);
        
    if (pendingAttachment != null) return pendingAttachment;
    
    // Tìm trong danh sách đang xử lý
    return _processingAttachments[attachmentId];
  }
  
  /// Tạm dừng hàng đợi
  void pauseQueue() {
    _isPaused = true;
    
    // Thông báo sự kiện
    _emitEvent(MessageQueueEventType.queuePaused);
  }
  
  /// Tiếp tục hàng đợi
  void resumeQueue() {
    _isPaused = false;
    
    // Thông báo sự kiện
    _emitEvent(MessageQueueEventType.queueResumed);
    
    // Tiếp tục xử lý
    _ensureProcessing();
  }
  
  /// Phân loại lỗi
  MessageErrorType _categorizeError(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return MessageErrorType.networkError;
    } else if (error is FileSystemException) {
      return MessageErrorType.fileError;
    } else if (error is http.ClientException || error.toString().contains('DioError')) {
      // Nếu có status code, phân loại dựa trên code
      if (error.toString().contains('status code: 401') || 
          error.toString().contains('status code: 403')) {
        return MessageErrorType.authError;
      } else if (error.toString().contains('status code: 429')) {
        return MessageErrorType.rateLimitError;
      } else if (error.toString().contains('status code: 4')) {
        return MessageErrorType.validationError;
      } else if (error.toString().contains('status code: 5')) {
        return MessageErrorType.serverError;
      }
      
      return MessageErrorType.networkError;
    } else if (error.toString().contains('auth') || 
               error.toString().contains('unauthorized')) {
      return MessageErrorType.authError;
    }
    
    return MessageErrorType.unknown;
  }
  
  /// Tính thời gian trễ cho việc thử lại
  int _calculateRetryDelay(int retryCount, MessageErrorType errorType) {
    // Độ trễ cơ bản với backoff
    int baseDelay;
    
    switch (errorType) {
      case MessageErrorType.networkError:
        // Độ trễ ngắn hơn cho lỗi mạng
        baseDelay = _baseRetryDelayMs * pow(1.5, retryCount).toInt();
        break;
      case MessageErrorType.serverError:
        // Độ trễ dài hơn cho lỗi server
        baseDelay = _baseRetryDelayMs * pow(2.5, retryCount).toInt();
        break;
      case MessageErrorType.rateLimitError:
        // Độ trễ dài cho lỗi giới hạn tốc độ
        baseDelay = _baseRetryDelayMs * 5 + (15000 * retryCount);
        break;
      case MessageErrorType.authError:
        // Độ trễ dài cho lỗi xác thực
        baseDelay = _baseRetryDelayMs * 5;
        break;
      default:
        baseDelay = _baseRetryDelayMs * pow(2, retryCount).toInt();
        break;
    }
    
    // Giới hạn tối đa
    final maxDelay = min(baseDelay, _maxRetryDelayMs);
    
    // Thêm nhiễu để tránh thundering herd
    final jitter = Random().nextInt((maxDelay * 0.3).toInt());
    
    return maxDelay + jitter;
  }
  
  /// Thông báo thay đổi trạng thái
  void _notifyAttachmentStatusChanged(QueuedAttachment attachment) {
    if (!_attachmentStatusController.isClosed) {
      _attachmentStatusController.add(attachment);
    }
  }
  
  /// Phát sự kiện
  void _emitEvent(MessageQueueEventType type, {
    String? attachmentId,
    String? messageId,
    String? serverId,
    String? error,
    MessageErrorType? errorType,
    DateTime? scheduledTime,
    double? progress,
  }) {
    if (!_eventController.isClosed) {
      _eventController.add(MessageQueueEvent(
        type: type,
        attachmentId: attachmentId,
        messageId: messageId,
        serverId: serverId,
        error: error,
        errorType: errorType,
        scheduledTime: scheduledTime,
        progress: progress,
      ));
    }
  }
  
  /// Giải phóng tài nguyên
  void dispose() {
    _stopProcessingQueue();
    
    // Hủy tất cả uploads đang chạy
    for (final subscription in _activeUploads.values) {
      subscription.cancel();
    }
    _activeUploads.clear();
    
    // Hủy tất cả downloads đang chạy
    for (final subscription in _activeDownloads.values) {
      subscription.cancel();
    }
    _activeDownloads.clear();
    
    // Đóng stream controllers
    _attachmentStatusController.close();
    _eventController.close();
  }
}

/// Kết quả của việc tải lên tập tin đính kèm
class AttachmentUploadResult {
  /// ID trên server
  final String id;
  
  /// URL truy cập
  final String url;
  
  /// Kích thước tập tin
  final int size;
  
  /// Thời gian tạo
  final DateTime createdAt;
  
  /// Constructor
  AttachmentUploadResult({
    required this.id,
    required this.url,
    required this.size,
    required this.createdAt,
  });
} 