# Xử lý Media trong Ứng dụng Chat

Tài liệu này mô tả các chiến lược tối ưu để xử lý hình ảnh, video, âm thanh và tệp đính kèm trong ứng dụng chat, đảm bảo tốc độ nhanh, tiết kiệm bộ nhớ, và trải nghiệm người dùng mượt mà.

## Mô hình Xử lý Media

Ứng dụng chat sử dụng kiến trúc ba lớp để xử lý media:

```
+----------------+     +---------------+     +----------------+
| Presentation   |     | Domain        |     | Data           |
| Layer          |     | Layer         |     | Layer          |
+----------------+     +---------------+     +----------------+
| - Media Viewers|     | - Media       |     | - Media Cache  |
| - Media Editors|     |   Entities    |     | - Upload Queue |
| - Upload UI    |     | - Usecases    |     | - API Client   |
+----------------+     +---------------+     +----------------+
```

## Xử lý Hình Ảnh

### Compression và Resizing

Hình ảnh được tối ưu trước khi upload để tiết kiệm băng thông và không gian lưu trữ:

```dart
Future<File> compressImage(File imageFile) async {
  final deviceInfo = GetIt.instance<DeviceCapabilityService>();
  final quality = deviceInfo.isLowEndDevice ? 70 : 85;
  
  // Lấy thông tin ảnh ban đầu
  final originalImage = await decodeImageFromList(await imageFile.readAsBytes());
  final width = originalImage.width;
  final height = originalImage.height;
  
  // Tính toán kích thước mới, giới hạn chiều lớn nhất là 1920px
  final maxDimension = 1920;
  final resizeFactor = math.min(1.0, maxDimension / math.max(width, height));
  final newWidth = (width * resizeFactor).round();
  final newHeight = (height * resizeFactor).round();
  
  // Nén với flutter_image_compress
  final compressedFile = await FlutterImageCompress.compressAndGetFile(
    imageFile.path,
    '${imageFile.path}_compressed.jpg',
    quality: quality,
    minWidth: newWidth,
    minHeight: newHeight,
    format: CompressFormat.jpeg,
  );
  
  final stats = await _logCompressionStats(imageFile, compressedFile!);
  log('Image compressed: ${stats.compressionRatio}% reduction');
  
  return compressedFile;
}
```

### Adaptive Loading

Tải hình ảnh với chất lượng dựa trên kết nối mạng:

```dart
Widget buildAdaptiveImage(String url, {double? width, double? height}) {
  final connectivityService = GetIt.instance<ConnectivityService>();
  
  return StreamBuilder<ConnectionType>(
    stream: connectivityService.connectionType,
    builder: (context, snapshot) {
      final connectionType = snapshot.data ?? ConnectionType.unknown;
      
      // Xác định chất lượng dựa trên loại kết nối
      final imageQuality = _getImageQualityForConnection(connectionType);
      final imageUrl = _getUrlWithQuality(url, imageQuality);
      
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        placeholder: (context, url) => ShimmerPlaceholder(width: width, height: height),
        errorWidget: (context, url, error) => ImageErrorWidget(),
        fadeInDuration: const Duration(milliseconds: 300),
        memCacheWidth: width != null ? (width * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      );
    },
  );
}

String _getUrlWithQuality(String originalUrl, ImageQuality quality) {
  // Giả sử API hỗ trợ tham số quality
  final uri = Uri.parse(originalUrl);
  return uri.replace(queryParameters: {
    ...uri.queryParameters,
    'quality': quality.value.toString(),
  }).toString();
}

ImageQuality _getImageQualityForConnection(ConnectionType connectionType) {
  switch (connectionType) {
    case ConnectionType.wifi:
      return ImageQuality.high;
    case ConnectionType.mobile:
      return ImageQuality.medium;
    case ConnectionType.slow:
      return ImageQuality.low;
    default:
      return ImageQuality.medium;
  }
}

enum ImageQuality {
  low(60),
  medium(80),
  high(100);
  
  final int value;
  const ImageQuality(this.value);
}
```

## Upload và Download Strategy

### Queue Management

Hệ thống quản lý hàng đợi đảm bảo tất cả hoạt động upload/download vẫn hoạt động hiệu quả khi mất kết nối:

```dart
class MediaUploadQueue {
  final Queue<MediaUploadTask> _queue = Queue();
  final _uploadController = StreamController<MediaUploadStatus>.broadcast();
  Stream<MediaUploadStatus> get uploadStatus => _uploadController.stream;
  
  bool _isProcessing = false;
  final ConnectivityService _connectivityService;
  
  MediaUploadQueue(this._connectivityService) {
    // Lắng nghe thay đổi kết nối để tự động xử lý queue
    _connectivityService.connectionStatus.listen(_onConnectionChange);
  }
  
  void _onConnectionChange(bool isConnected) {
    if (isConnected && !_isProcessing && _queue.isNotEmpty) {
      _processQueue();
    }
  }
  
  // Thêm media vào hàng đợi
  Future<void> addToQueue(MediaUploadTask task) async {
    // Lưu thông tin task vào local storage để phục hồi sau restart
    await _persistTask(task);
    
    _queue.add(task);
    _uploadController.add(MediaUploadStatus(
      taskId: task.id,
      status: UploadStatus.queued,
      progress: 0.0,
    ));
    
    if (!_isProcessing && await _connectivityService.isConnected()) {
      _processQueue();
    }
  }
  
  // Xử lý hàng đợi
  Future<void> _processQueue() async {
    if (_queue.isEmpty || _isProcessing) return;
    
    _isProcessing = true;
    
    while (_queue.isNotEmpty) {
      final task = _queue.first;
      
      try {
        await _processTask(task);
        _queue.removeFirst();
        await _removePersistedTask(task.id);
      } catch (e) {
        // Xử lý lỗi và quyết định có retry không
        if (task.retryCount < 3) {
          final updatedTask = task.copyWith(retryCount: task.retryCount + 1);
          _queue.removeFirst();
          _queue.add(updatedTask);
          await _updatePersistedTask(updatedTask);
        } else {
          // Đánh dấu failed sau 3 lần retry
          _uploadController.add(MediaUploadStatus(
            taskId: task.id,
            status: UploadStatus.failed,
            error: e.toString(),
          ));
          _queue.removeFirst();
          await _removePersistedTask(task.id);
        }
        
        if (!await _connectivityService.isConnected()) {
          break; // Dừng xử lý nếu mất kết nối
        }
      }
    }
    
    _isProcessing = false;
  }
  
  // Xử lý từng task với progress update
  Future<void> _processTask(MediaUploadTask task) async {
    final uploader = _createUploader(task);
    
    uploader.progress.listen((progress) {
      _uploadController.add(MediaUploadStatus(
        taskId: task.id,
        status: UploadStatus.uploading,
        progress: progress,
      ));
    });
    
    final result = await uploader.upload();
    
    _uploadController.add(MediaUploadStatus(
      taskId: task.id,
      status: UploadStatus.completed,
      progress: 1.0,
      result: result,
    ));
  }
  
  // Tạo uploader dựa trên loại media
  MediaUploader _createUploader(MediaUploadTask task) {
    switch (task.mediaType) {
      case MediaType.image:
        return ImageUploader(task);
      case MediaType.video:
        return VideoUploader(task);
      case MediaType.audio:
        return AudioUploader(task);
      case MediaType.file:
        return FileUploader(task);
    }
  }
  
  // Các phương thức persistence
  Future<void> _persistTask(MediaUploadTask task) async {
    // Lưu task vào SharedPreferences hoặc local DB
  }
  
  Future<void> _updatePersistedTask(MediaUploadTask task) async {
    // Cập nhật task trong storage
  }
  
  Future<void> _removePersistedTask(String taskId) async {
    // Xóa task từ storage
  }
}
```

### Background Upload

Xử lý upload ngay cả khi ứng dụng ở nền:

```dart
class BackgroundUploadService {
  static Future<void> initialize() async {
    // Register for background fetch events
    final fetchStatus = await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );
    
    log('Background fetch status: $fetchStatus');
  }
  
  static Future<void> _onBackgroundFetch(String taskId) async {
    log('Background fetch task: $taskId');
    
    // Khởi tạo dependency injection
    await setupLocator();
    
    // Xử lý upload queue
    final uploadQueue = GetIt.instance<MediaUploadQueue>();
    await uploadQueue.resumeAllPendingUploads();
    
    // Thông báo task hoàn thành
    BackgroundFetch.finish(taskId);
  }
  
  static void _onBackgroundFetchTimeout(String taskId) {
    log('Background fetch timeout: $taskId');
    BackgroundFetch.finish(taskId);
  }
}
```

## Xử lý Video

### Transcoding và Thumbnail

```dart
class VideoProcessor {
  final deviceCapability = GetIt.instance<DeviceCapabilityService>();
  
  Future<VideoProcessResult> processVideoForUpload(File videoFile) async {
    final videoInfo = await VideoCompress.getMediaInfo(videoFile.path);
    final duration = videoInfo.duration ?? 0;
    
    // Bỏ qua transcoding cho video ngắn trên thiết bị cấu hình cao
    if (duration < 30 && deviceCapability.isHighEndDevice) {
      return VideoProcessResult(
        video: videoFile,
        thumbnail: await _generateThumbnail(videoFile.path),
        metadata: VideoMetadata(
          duration: duration,
          width: videoInfo.width,
          height: videoInfo.height,
          size: await videoFile.length(),
        ),
      );
    }
    
    // Nén video cho các trường hợp khác
    final compressedVideo = await _compressVideo(videoFile);
    
    return VideoProcessResult(
      video: compressedVideo,
      thumbnail: await _generateThumbnail(compressedVideo.path),
      metadata: VideoMetadata(
        duration: duration,
        width: videoInfo.width,
        height: videoInfo.height,
        size: await compressedVideo.length(),
      ),
    );
  }
  
  Future<File> _compressVideo(File videoFile) async {
    final quality = deviceCapability.isLowEndDevice 
        ? VideoQuality.LowQuality 
        : VideoQuality.MediumQuality;
    
    final compressedVideo = await VideoCompress.compressVideo(
      videoFile.path,
      quality: quality,
      deleteOrigin: false,
      includeAudio: true,
    );
    
    return File(compressedVideo!.path!);
  }
  
  Future<File> _generateThumbnail(String videoPath) async {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
    
    return File(thumbnailPath!);
  }
}
```

### Video Streaming Adaptation

```dart
class AdaptiveVideoPlayer extends StatefulWidget {
  final String videoUrl;
  
  @override
  _AdaptiveVideoPlayerState createState() => _AdaptiveVideoPlayerState();
}

class _AdaptiveVideoPlayerState extends State<AdaptiveVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late ConnectivityService _connectivityService;
  late StreamSubscription _connectivitySubscription;
  VideoQuality _currentQuality = VideoQuality.auto;
  
  @override
  void initState() {
    super.initState();
    _connectivityService = GetIt.instance<ConnectivityService>();
    _initializePlayer();
    
    // Theo dõi thay đổi kết nối và điều chỉnh chất lượng nếu cần
    _connectivitySubscription = _connectivityService.connectionType.listen(_onConnectionChanged);
  }
  
  void _initializePlayer() {
    final videoUrl = _getVideoUrlForQuality(_currentQuality);
    _controller = VideoPlayerController.network(videoUrl);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Đảm bảo widget được rebuild sau khi video được khởi tạo
      if (mounted) setState(() {});
    });
  }
  
  void _onConnectionChanged(ConnectionType connectionType) {
    // Chỉ thay đổi chất lượng khi video đang phát
    if (_controller.value.isPlaying) {
      final newQuality = _getQualityForConnection(connectionType);
      if (newQuality != _currentQuality) {
        _changeVideoQuality(newQuality);
      }
    }
  }
  
  void _changeVideoQuality(VideoQuality quality) {
    // Lưu vị trí hiện tại
    final currentPosition = _controller.value.position;
    final wasPlaying = _controller.value.isPlaying;
    
    // Dừng và giải phóng controller hiện tại
    _controller.pause();
    _controller.dispose();
    
    // Tạo controller mới với URL chất lượng mới
    _currentQuality = quality;
    final newUrl = _getVideoUrlForQuality(quality);
    _controller = VideoPlayerController.network(newUrl);
    
    // Khởi tạo lại và khôi phục vị trí
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      _controller.seekTo(currentPosition);
      if (wasPlaying) _controller.play();
      if (mounted) setState(() {});
    });
  }
  
  String _getVideoUrlForQuality(VideoQuality quality) {
    // Giả sử API hỗ trợ stream ở nhiều chất lượng khác nhau
    final uri = Uri.parse(widget.videoUrl);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'quality': quality.value,
    }).toString();
  }
  
  VideoQuality _getQualityForConnection(ConnectionType connectionType) {
    switch (connectionType) {
      case ConnectionType.wifi:
        return VideoQuality.high;
      case ConnectionType.mobile:
        return VideoQuality.medium;
      case ConnectionType.slow:
        return VideoQuality.low;
      default:
        return VideoQuality.auto;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                VideoPlayer(_controller),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                _buildControls(),
              ],
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
  
  Widget _buildControls() {
    // Video controls UI
    return VideoControls(
      controller: _controller,
      onQualityChanged: _changeVideoQuality,
    );
  }
  
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _controller.dispose();
    super.dispose();
  }
}

enum VideoQuality {
  auto('auto'),
  low('240p'),
  medium('480p'),
  high('720p'),
  hd('1080p');
  
  final String value;
  const VideoQuality(this.value);
}
```

## Âm thanh và Voice Messages

### Stream & Compression

```dart
class VoiceMessageRecorder {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final String _filePath;
  final _recordingTimer = Stopwatch();
  final _levelUpdates = StreamController<RecordingLevel>.broadcast();
  Stream<RecordingLevel> get levelUpdates => _levelUpdates.stream;
  StreamSubscription? _levelSubscription;
  
  VoiceMessageRecorder({String? customPath}) 
      : _filePath = customPath ?? '${getTemporaryDirectory().path}/voice_message.aac';
  
  Future<void> initialize() async {
    await _recorder.openRecorder();
    await _recorder.setSubscriptionDuration(const Duration(milliseconds: 100));
  }
  
  Future<void> startRecording() async {
    if (await _checkPermission()) {
      _recordingTimer.start();
      
      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.aacADTS,
        audioSource: AudioSource.microphone,
      );
      
      // Lắng nghe dB level để hiển thị waveform
      _levelSubscription = _recorder.onProgress!.listen((event) {
        if (event.decibels != null) {
          _levelUpdates.add(RecordingLevel(
            level: event.decibels!,
            duration: _recordingTimer.elapsed,
          ));
        }
      });
    }
  }
  
  Future<VoiceMessageResult> stopRecording() async {
    _recordingTimer.stop();
    final duration = _recordingTimer.elapsed;
    _recordingTimer.reset();
    
    final recordingPath = await _recorder.stopRecorder();
    _levelSubscription?.cancel();
    
    // Nén audio nếu cần (trên 2 phút)
    final File audioFile = File(recordingPath!);
    final File processedFile = duration.inMinutes >= 2 
        ? await _compressAudio(audioFile)
        : audioFile;
    
    return VoiceMessageResult(
      file: processedFile,
      duration: duration,
      waveform: await _generateWaveform(processedFile),
    );
  }
  
  Future<File> _compressAudio(File audioFile) async {
    // Nén audio với ffmpeg
    final outputPath = '${audioFile.path}_compressed.aac';
    await FFmpegKit.execute('-i ${audioFile.path} -c:a aac -b:a 64k $outputPath');
    return File(outputPath);
  }
  
  Future<List<int>> _generateWaveform(File audioFile) async {
    // Tạo waveform data để hiển thị
    final waveform = <int>[];
    
    // Phân tích audio để lấy biên độ
    await FFmpegKit.execute(
      '-i ${audioFile.path} -f wav -',
      (session) async {
        final output = await session.getOutput();
        // Parse output để lấy amplitude data và tạo waveform
        // (Giả lập ở đây)
        for (int i = 0; i < 50; i++) {
          waveform.add(Random().nextInt(100));
        }
      },
    );
    
    return waveform;
  }
  
  Future<bool> _checkPermission() async {
    // Kiểm tra và yêu cầu quyền ghi âm
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    final result = await Permission.microphone.request();
    return result.isGranted;
  }
  
  Future<void> dispose() async {
    _levelSubscription?.cancel();
    _levelUpdates.close();
    await _recorder.closeRecorder();
  }
}
```

## File Handling

### Tối ưu download và preview

```dart
class FileHandler {
  final _downloadQueue = <String, Completer<File>>{};
  final _fileRepository = GetIt.instance<FileRepository>();
  
  // Download và cache một file
  Future<File> downloadFile(FileMessage fileMessage) async {
    // Kiểm tra nếu file đã có trong cache
    final cachedFile = await _fileRepository.getCachedFile(fileMessage.id);
    if (cachedFile != null) {
      return cachedFile;
    }
    
    // Kiểm tra nếu file đang được download
    if (_downloadQueue.containsKey(fileMessage.id)) {
      return _downloadQueue[fileMessage.id]!.future;
    }
    
    // Tạo một completer mới để theo dõi download
    final completer = Completer<File>();
    _downloadQueue[fileMessage.id] = completer;
    
    try {
      // Download file và lưu vào cache
      final file = await _fileRepository.downloadFile(
        fileMessage.url,
        fileMessage.id,
        fileMessage.name,
        onProgress: (progress) {
          // Update UI với tiến trình download
          GetIt.instance<FileDownloadBloc>().add(
            FileDownloadProgressUpdated(fileMessage.id, progress),
          );
        },
      );
      
      completer.complete(file);
      _downloadQueue.remove(fileMessage.id);
      return file;
    } catch (e) {
      completer.completeError(e);
      _downloadQueue.remove(fileMessage.id);
      rethrow;
    }
  }
  
  // Preview file phù hợp với loại
  Future<void> previewFile(BuildContext context, FileMessage fileMessage) async {
    try {
      final file = await downloadFile(fileMessage);
      
      if (!context.mounted) return;
      
      // Xác định loại file và mở preview phù hợp
      switch (_getFileType(fileMessage.name)) {
        case FileType.image:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(file: file),
            ),
          );
          break;
          
        case FileType.pdf:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(file: file),
            ),
          );
          break;
          
        case FileType.video:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreen(file: file),
            ),
          );
          break;
          
        case FileType.audio:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AudioPreviewScreen(file: file),
            ),
          );
          break;
          
        default:
          // Mở file bằng ứng dụng mặc định
          await OpenFile.open(file.path);
      }
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể mở file: ${e.toString()}')),
      );
    }
  }
  
  FileType _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return FileType.image;
    } else if (extension == 'pdf') {
      return FileType.pdf;
    } else if (['mp4', 'mov', '3gp', 'avi', 'mkv'].contains(extension)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
      return FileType.audio;
    } else {
      return FileType.other;
    }
  }
}
```

## Cache và Storage Management

### Cleanup Strategy

```dart
class MediaCacheManager {
  final FileRepository _fileRepository;
  final PreferenceService _preferenceService;
  final long MAX_CACHE_SIZE_BYTES = 200 * 1024 * 1024; // 200MB
  
  MediaCacheManager(this._fileRepository, this._preferenceService);
  
  Future<void> initializeCache() async {
    // Lên lịch cleanup cache định kỳ
    Timer.periodic(const Duration(days: 1), (_) => cleanupCache());
    
    // Và check ngay lập tức sau khi khởi động
    cleanupCache();
  }
  
  Future<void> cleanupCache() async {
    final cacheSize = await _fileRepository.getCacheSize();
    
    // Nếu cache < 80% giới hạn thì không cần cleanup
    if (cacheSize < MAX_CACHE_SIZE_BYTES * 0.8) {
      return;
    }
    
    log('Cache size: ${cacheSize / (1024 * 1024)}MB, cleaning up...');
    
    // Lấy danh sách file trong cache, sắp xếp theo thời gian truy cập
    final cachedFiles = await _fileRepository.getCachedFiles();
    cachedFiles.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
    
    // Xóa file cũ nhất cho đến khi còn 50% không gian
    long targetSize = MAX_CACHE_SIZE_BYTES * 0.5;
    long currentSize = cacheSize;
    
    for (final file in cachedFiles) {
      // Không xóa file được đánh dấu "keep"
      if (file.keepInCache) continue;
      
      try {
        await _fileRepository.removeFromCache(file.id);
        currentSize -= file.size;
        
        if (currentSize <= targetSize) {
          break;
        }
      } catch (e) {
        log('Error removing file from cache: ${e.toString()}');
      }
    }
    
    log('Cache cleaned up, new size: ${currentSize / (1024 * 1024)}MB');
  }
  
  Future<void> keepFilesForChat(String chatId, {Duration duration = const Duration(days: 7)}) async {
    // Đánh dấu các file từ một chat là "keep" trong khoảng thời gian
    final expiryDate = DateTime.now().add(duration);
    await _preferenceService.setChatFilesExpiry(chatId, expiryDate);
    
    // Cập nhật trạng thái cho các file
    final chatFiles = await _fileRepository.getFilesForChat(chatId);
    for (final file in chatFiles) {
      await _fileRepository.markFileKeep(file.id, true);
    }
  }
  
  Future<void> clearChatCache(String chatId) async {
    final chatFiles = await _fileRepository.getFilesForChat(chatId);
    for (final file in chatFiles) {
      await _fileRepository.removeFromCache(file.id);
    }
  }
}
```

### Memory Usage Optimization

```dart
class MediaMemoryOptimizer {
  final DeviceCapabilityService _deviceCapabilityService;
  
  MediaMemoryOptimizer(this._deviceCapabilityService);
  
  // Cấu hình cache size dựa trên thiết bị
  void configureImageCache() {
    final maxMemory = _deviceCapabilityService.availableMemoryMB;
    
    // Điều chỉnh image cache dựa trên RAM có sẵn
    if (maxMemory < 1024) {
      // Thiết bị RAM thấp (<1GB free)
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
    } else if (maxMemory < 2048) {
      // Thiết bị RAM trung bình
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024; // 100MB
    } else {
      // Thiết bị RAM cao
      PaintingBinding.instance.imageCache.maximumSizeBytes = 150 * 1024 * 1024; // 150MB
    }
  }
  
  // Giải phóng bộ nhớ khi ứng dụng chuyển sang background
  void handleAppBackground() {
    // Xóa image cache trừ khi có đánh dấu pinning
    PaintingBinding.instance.imageCache.clear();
    
    // Giảm memory footprint
    ImageCache().clearLiveImages();
  }
  
  // Giải phóng bộ nhớ khi cần
  void reducePressure() {
    // Xóa cache vì lý do bộ nhớ thấp
    PaintingBinding.instance.imageCache.clear();
    
    // Gợi ý GC chạy
    SystemChannels.memory.invokeMethod('gc');
  }
}
```

## Best Practices

### Quy tắc xử lý Media

1. **Luôn đo lường trước khi tối ưu**
   - Sử dụng Firebase Performance để theo dõi thời gian tải media
   - Đặt benchmark cho từng loại media (ví dụ: hình ảnh < 500ms)

2. **Progressive Loading**
   - Hiển thị thumbnail trước, sau đó là bản đầy đủ
   - Phương pháp "blur hash" cho hình ảnh

3. **Prefetching thông minh**
   - Tải trước media có khả năng được xem
   - Chỉ prefetch khi kết nối WiFi và thiết bị có đủ bộ nhớ

4. **Giảm kích thước payload**
   - Upload với kích thước phù hợp cho thiết bị di động
   - Sử dụng định dạng hiện đại (WebP thay vì JPEG)

5. **Error handling có hệ thống**
   - Tải lại tự động trong trường hợp lỗi
   - Fallback strategy cho mỗi loại media

### Performance Checklist

Sử dụng checklist sau để đảm bảo hiệu suất media tối ưu:

- [ ] Tất cả hình ảnh đều được nén với chất lượng phù hợp (lossy + lossless)
- [ ] Video được transcode để phát trực tuyến adaptive
- [ ] Memory footprint được kiểm soát qua caching và cleanup
- [ ] Có chiến lược dọn dẹp cache tự động
- [ ] UI không bị block khi tải media
- [ ] Kiểm thử trên thiết bị cấu hình thấp

## Dependency Injection

```dart
// Thiết lập các service và repository
void setupMediaDependencies() {
  GetIt.instance.registerLazySingleton<MediaUploadQueue>(() => 
    MediaUploadQueue(GetIt.instance<ConnectivityService>())
  );
  
  GetIt.instance.registerLazySingleton<FileRepository>(() => 
    FileRepositoryImpl(GetIt.instance<DatabaseService>())
  );
  
  GetIt.instance.registerLazySingleton<MediaCacheManager>(() => 
    MediaCacheManager(
      GetIt.instance<FileRepository>(),
      GetIt.instance<PreferenceService>(),
    )
  );
  
  GetIt.instance.registerFactory<VideoProcessor>(() => VideoProcessor());
  
  GetIt.instance.registerFactory<FileHandler>(() => FileHandler());
}
```

## Tham khảo

- [Flutter Image Caching & Optimization](https://flutter.dev/docs/cookbook/images/cached-images)
- [Media Optimization Techniques](https://flutter.dev/docs/perf/rendering/images)
- [Video Streaming Optimization](https://github.com/flutter/flutter/issues)
- [Media Handling on Low-end Devices](https://medium.com/flutter-community/) 