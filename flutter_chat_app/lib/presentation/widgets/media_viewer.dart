import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/core/services/connectivity_analyzer_service.dart';
import 'package:flutter_chat_app/core/services/resource_manager_service.dart';
import 'package:get_it/get_it.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Widget để hiển thị media (ảnh, video) với các tối ưu cho hiệu suất
class MediaViewer extends StatefulWidget {
  /// URL hoặc đường dẫn của tệp media
  final String mediaUrl;
  
  /// Loại media (auto, image, video)
  final MediaType mediaType;
  
  /// Chất lượng khi load video
  final VideoQuality videoQuality;
  
  /// Có sử dụng caching không
  final bool enableCaching;
  
  /// Callback khi load tiến trình
  final Function(double)? onProgressChanged;
  
  /// Callback khi gặp lỗi
  final Function(String)? onError;
  
  /// Constructor
  const MediaViewer({
    Key? key,
    required this.mediaUrl,
    this.mediaType = MediaType.auto,
    this.videoQuality = VideoQuality.auto,
    this.enableCaching = true,
    this.onProgressChanged,
    this.onError,
  }) : super(key: key);

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

/// Loại media
enum MediaType {
  /// Tự động phát hiện
  auto,
  
  /// Ảnh
  image,
  
  /// Video
  video,
}

/// Chất lượng video
enum VideoQuality {
  /// Tự động dựa trên kết nối
  auto,
  
  /// Chất lượng thấp (360p)
  low,
  
  /// Chất lượng trung bình (480p)
  medium,
  
  /// Chất lượng cao (720p)
  high,
  
  /// Chất lượng rất cao (1080p)
  veryHigh,
}

class _MediaViewerState extends State<MediaViewer> {
  /// Resource manager service
  final ResourceManagerService _resourceManager = GetIt.instance<ResourceManagerService>();
  
  /// Connectivity analyzer service
  final ConnectivityAnalyzerService _connectivityAnalyzer = GetIt.instance<ConnectivityAnalyzerService>();
  
  /// File đã tải
  File? _loadedFile;
  
  /// Controller cho video
  VideoPlayerController? _videoController;
  
  /// Controller cho chewie
  ChewieController? _chewieController;
  
  /// Trạng thái đang tải
  bool _isLoading = true;
  
  /// Tiến trình tải (0.0 - 1.0)
  double _loadingProgress = 0.0;
  
  /// Thông báo lỗi
  String? _errorMessage;
  
  /// Loại media được phát hiện
  MediaType _detectedMediaType = MediaType.image;
  
  @override
  void initState() {
    super.initState();
    _loadMedia();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
  
  /// Xác định loại media từ URL
  MediaType _detectMediaType(String url) {
    if (widget.mediaType != MediaType.auto) {
      return widget.mediaType;
    }
    
    final lowercaseUrl = url.toLowerCase();
    if (lowercaseUrl.endsWith('.mp4') || 
        lowercaseUrl.endsWith('.mov') || 
        lowercaseUrl.endsWith('.webm') ||
        lowercaseUrl.endsWith('.avi')) {
      return MediaType.video;
    } else {
      return MediaType.image;
    }
  }
  
  /// Xác định chất lượng video dựa trên kết nối mạng
  Map<String, dynamic> _getVideoOptions() {
    if (widget.videoQuality != VideoQuality.auto) {
      // Sử dụng chất lượng được chỉ định
      switch (widget.videoQuality) {
        case VideoQuality.low:
          return {'preferredResolution': 360};
        case VideoQuality.medium:
          return {'preferredResolution': 480};
        case VideoQuality.high:
          return {'preferredResolution': 720};
        case VideoQuality.veryHigh:
          return {'preferredResolution': 1080};
        default:
          return {};
      }
    }
    
    // Tự động điều chỉnh chất lượng dựa trên kết nối
    final resolution = _connectivityAnalyzer.getOptimalVideoQuality();
    return {'preferredResolution': resolution};
  }
  
  /// Tải media
  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
      _errorMessage = null;
    });
    
    try {
      // Xác định loại media
      _detectedMediaType = _detectMediaType(widget.mediaUrl);
      
      // Chế độ streaming cho video trên mạng yếu
      final shouldUseStreaming = _detectedMediaType == MediaType.video && 
                               !widget.mediaUrl.startsWith('file://') &&
                               _connectivityAnalyzer.currentQuality == NetworkQuality.poor;
      
      // Tải file
      final file = await _resourceManager.downloadFile(
        url: widget.mediaUrl,
        fileName: widget.mediaUrl.split('/').last,
        cache: widget.enableCaching,
        // TODO: Implement progress tracking with progressStream
      );
      
      if (file != null) {
        setState(() {
          _loadedFile = file;
          _isLoading = false;
        });
        
        // Khởi tạo player nếu là video
        if (_detectedMediaType == MediaType.video) {
          await _initializeVideoPlayer(file.path);
        }
      } else if (shouldUseStreaming) {
        // Nếu dùng streaming, khởi tạo player với URL trực tiếp
        if (_detectedMediaType == MediaType.video) {
          await _initializeVideoPlayer(widget.mediaUrl);
        }
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Không thể tải media');
      }
    } catch (e) {
      debugPrint('Lỗi tải media: $e');
      final errorMsg = 'Không thể tải media: $e';
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      
      if (widget.onError != null) {
        widget.onError!(errorMsg);
      }
    }
  }
  
  /// Xử lý cập nhật tiến trình tải
  void _handleLoadingProgress(double progress) {
    setState(() {
      _loadingProgress = progress;
    });
    
    if (widget.onProgressChanged != null) {
      widget.onProgressChanged!(progress);
    }
  }
  
  /// Khởi tạo video player
  Future<void> _initializeVideoPlayer(String videoPath) async {
    try {
      final controller = videoPath.startsWith('http')
          ? VideoPlayerController.networkUrl(Uri.parse(videoPath))
          : VideoPlayerController.file(File(videoPath));
      
      await controller.initialize();
      
      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        aspectRatio: controller.value.aspectRatio,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Lỗi phát video: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
      
      setState(() {
        _videoController = controller;
        _chewieController = chewieController;
      });
    } catch (e) {
      debugPrint('Lỗi khởi tạo video player: $e');
      setState(() {
        _errorMessage = 'Không thể phát video: $e';
      });
      
      if (widget.onError != null) {
        widget.onError!('Không thể phát video: $e');
      }
    }
  }
  
  /// Builder cho nội dung loading
  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            value: _loadingProgress > 0 ? _loadingProgress : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải... ${(_loadingProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
  
  /// Builder cho nội dung lỗi
  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Đã xảy ra lỗi không xác định',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMedia,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
  
  /// Builder cho nội dung hình ảnh
  Widget _buildImageContent() {
    final imageProvider = _loadedFile != null
        ? FileImage(_loadedFile!) as ImageProvider
        : NetworkImage(widget.mediaUrl);
        
    return PhotoView(
      imageProvider: imageProvider,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      loadingBuilder: (context, event) {
        return Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorContent();
      },
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
  
  /// Builder cho nội dung video
  Widget _buildVideoContent() {
    if (_chewieController != null) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingContent();
    }
    
    if (_errorMessage != null) {
      return _buildErrorContent();
    }
    
    if (_detectedMediaType == MediaType.video) {
      return _buildVideoContent();
    } else {
      return _buildImageContent();
    }
  }
} 