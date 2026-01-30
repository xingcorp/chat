import 'package:flutter_chat_app/domain/entities/message_error_type.dart';

/// Class theo dõi metrics và hiệu suất của message queue
class MessageQueueMetrics {
  /// Tổng số tin nhắn đã thêm vào hàng đợi
  int totalEnqueued = 0;
  
  /// Tổng số tin nhắn đã gửi thành công
  int totalSent = 0;
  
  /// Tổng số tin nhắn bị lỗi
  int totalFailed = 0;
  
  /// Tổng số tin nhắn đã thử lại
  int totalRetried = 0;
  
  /// Kích thước hàng đợi hiện tại
  int currentQueueSize = 0;
  
  /// Số tin nhắn đang xử lý
  int currentProcessing = 0;
  
  /// Thông kê số lượng từng loại lỗi
  final Map<MessageErrorType, int> errorCounts = {};
  
  /// Thời gian gửi tin nhắn thành công gần nhất
  DateTime? lastSuccessSendTime;
  
  /// Danh sách thời gian gửi tin nhắn
  final List<Duration> _sendDurations = [];
  
  /// Danh sách thời gian tải tệp đính kèm
  final List<Duration> _attachmentUploadDurations = [];
  
  /// Timestamp bắt đầu theo dõi
  final DateTime startTime = DateTime.now();
  
  /// Số tin nhắn đã hoàn thành trong phiên
  int completedInSession = 0;
  
  /// Thêm mốc thời gian gửi tin nhắn mới
  void addSendDuration(Duration duration) {
    _sendDurations.add(duration);
    
    // Giữ tối đa 100 mẫu
    if (_sendDurations.length > 100) {
      _sendDurations.removeAt(0);
    }
  }
  
  /// Thêm mốc thời gian tải tệp đính kèm mới
  void addAttachmentUploadDuration(Duration duration) {
    _attachmentUploadDurations.add(duration);
    
    // Giữ tối đa 50 mẫu
    if (_attachmentUploadDurations.length > 50) {
      _attachmentUploadDurations.removeAt(0);
    }
  }
  
  /// Tính thời gian trung bình gửi tin nhắn
  Duration get averageSendDuration {
    if (_sendDurations.isEmpty) return Duration.zero;
    
    int total = 0;
    for (var duration in _sendDurations) {
      total += duration.inMilliseconds;
    }
    return Duration(milliseconds: total ~/ _sendDurations.length);
  }
  
  /// Tính thời gian trung bình tải tệp đính kèm
  Duration get averageAttachmentUploadDuration {
    if (_attachmentUploadDurations.isEmpty) return Duration.zero;
    
    int total = 0;
    for (var duration in _attachmentUploadDurations) {
      total += duration.inMilliseconds;
    }
    return Duration(milliseconds: total ~/ _attachmentUploadDurations.length);
  }
  
  /// Tính tỷ lệ thành công của việc gửi tin
  double get successRate {
    if (totalEnqueued == 0) return 0;
    return totalSent / totalEnqueued;
  }
  
  /// Tính tỷ lệ thất bại của việc gửi tin
  double get failureRate {
    if (totalEnqueued == 0) return 0;
    return totalFailed / totalEnqueued;
  }
  
  /// Tỷ lệ thử lại
  double get retryRate {
    if (totalEnqueued == 0) return 0;
    return totalRetried / totalEnqueued;
  }
  
  /// Tính thông lượng: số tin nhắn hoàn thành trên một phút
  double get throughputPerMinute {
    final elapsedMinutes = DateTime.now().difference(startTime).inMinutes;
    if (elapsedMinutes == 0) return 0;
    return completedInSession / elapsedMinutes;
  }
  
  /// Thêm một lỗi vào thống kê
  void addError(MessageErrorType errorType) {
    errorCounts[errorType] = (errorCounts[errorType] ?? 0) + 1;
    totalFailed++;
  }
  
  /// Ghi nhận một tin nhắn thành công
  void recordSuccess({Duration? sendDuration}) {
    totalSent++;
    completedInSession++;
    lastSuccessSendTime = DateTime.now();
    
    if (sendDuration != null) {
      addSendDuration(sendDuration);
    }
  }
  
  /// Ghi nhận một tin nhắn thất bại
  void recordFailure(MessageErrorType errorType) {
    addError(errorType);
    completedInSession++;
  }
  
  /// Ghi nhận một lần thử lại
  void recordRetry() {
    totalRetried++;
  }
  
  /// Ghi nhận một tin nhắn được thêm vào hàng đợi
  void recordEnqueued() {
    totalEnqueued++;
    currentQueueSize++;
  }
  
  /// Ghi nhận một tin nhắn bắt đầu xử lý
  void recordProcessingStarted() {
    currentQueueSize--;
    currentProcessing++;
  }
  
  /// Ghi nhận một tin nhắn hoàn thành xử lý
  void recordProcessingCompleted() {
    currentProcessing--;
  }
  
  /// Reset metrics
  void reset() {
    totalEnqueued = 0;
    totalSent = 0;
    totalFailed = 0;
    totalRetried = 0;
    currentQueueSize = 0;
    currentProcessing = 0;
    errorCounts.clear();
    _sendDurations.clear();
    _attachmentUploadDurations.clear();
    lastSuccessSendTime = null;
    completedInSession = 0;
  }
  
  /// Tạo báo cáo hiệu suất
  String generateReport() {
    final averageSendMs = averageSendDuration.inMilliseconds;
    final averageUploadMs = averageAttachmentUploadDuration.inMilliseconds;
    
    final errorSummary = errorCounts.entries.map((entry) =>
        '${entry.key.toString().split('.').last}: ${entry.value}').join(', ');
    
    return """
    Message Queue Performance Report:
    - Total Enqueued: $totalEnqueued
    - Total Sent: $totalSent
    - Total Failed: $totalFailed
    - Total Retried: $totalRetried
    - Current Queue Size: $currentQueueSize
    - Messages Being Processed: $currentProcessing
    - Success Rate: ${(successRate * 100).toStringAsFixed(2)}%
    - Failure Rate: ${(failureRate * 100).toStringAsFixed(2)}%
    - Retry Rate: ${(retryRate * 100).toStringAsFixed(2)}%
    - Average Send Time: ${averageSendMs}ms
    - Average Attachment Upload Time: ${averageUploadMs}ms
    - Throughput: ${throughputPerMinute.toStringAsFixed(2)} messages/minute
    - Error Distribution: $errorSummary
    - Running since: ${startTime.toString()}
    """;
  }
  
  /// Increment cancelled message count
  void incrementCancelled() {
    // Count cancelled messages separately or as failed
    totalFailed++;
    currentQueueSize = currentQueueSize > 0 ? currentQueueSize - 1 : 0;
  }
}
