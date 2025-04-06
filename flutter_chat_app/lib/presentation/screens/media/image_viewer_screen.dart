import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';
import 'package:photo_view/photo_view.dart';

/// Màn hình xem hình ảnh với khả năng zoom và phóng to
class ImageViewerScreen extends StatefulWidget {
  /// URL hình ảnh
  final String imageUrl;
  
  /// Tag cho Hero animation
  final String heroTag;
  
  /// Tiêu đề
  final String? title;
  
  /// Constructor
  const ImageViewerScreen({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
    this.title,
  }) : super(key: key);
  
  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> with SingleTickerProviderStateMixin {
  /// Lấy cấu hình animation
  final animationService = GetIt.I<AnimationService>();
  
  /// Controller cho animation
  late AnimationController _animationController;
  
  /// Animation cho background
  late Animation<Color?> _colorAnimation;
  
  /// Animation cho AppBar
  late Animation<double> _appBarOpacityAnimation;
  
  /// Có hiện UI không
  bool _showUI = true;
  
  /// Đang thực hiện gesture không
  bool _isGestureActive = false;
  
  @override
  void initState() {
    super.initState();
    
    // Cài đặt SystemUI cho trải nghiệm đắm chìm
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
      ),
    );
    
    // Thiết lập animation
    _animationController = AnimationController(
      vsync: this,
      duration: animationService.config.defaultDuration,
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.black.withOpacity(0.5),
    ).animate(_animationController);
    
    _appBarOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);
    
    // Khởi tạo hiển thị UI
    _animationController.value = 0.0;
  }
  
  @override
  void dispose() {
    // Reset SystemUI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: _toggleUI,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              color: _colorAnimation.value,
              child: child,
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero animation giúp transition mượt mà từ danh sách hình ảnh
              Hero(
                tag: widget.heroTag,
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2.0,
                  filterQuality: animationService.config.imageFilterQuality,
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  loadingBuilder: (context, event) {
                    // Hiển thị tiến trình tải hình
                    if (event == null) {
                      return const SizedBox.shrink();
                    }
                    
                    return Center(
                      child: CircularProgressIndicator(
                        value: event.expectedTotalBytes != null
                            ? event.cumulativeBytesLoaded / event.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                  onScaleEnd: (_, __, ___) {
                    setState(() {
                      _isGestureActive = false;
                    });
                  },
                  scaleStateCycle: (currentState) {
                    // Chu kỳ trạng thái khi double tap
                    if (currentState == PhotoViewScaleState.initial) {
                      return PhotoViewScaleState.covering;
                    } else {
                      return PhotoViewScaleState.initial;
                    }
                  },
                  scaleStateChangedCallback: (state) {
                    // Ẩn UI khi zoom
                    if (state != PhotoViewScaleState.initial && _showUI) {
                      setState(() {
                        _showUI = false;
                        _animationController.forward();
                      });
                    }
                    
                    setState(() {
                      _isGestureActive = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Tạo AppBar với animation
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedBuilder(
        animation: _appBarOpacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _appBarOpacityAnimation.value,
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.4),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.title ?? 'Hình ảnh',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // Implement share functionality
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white),
                  onPressed: () {
                    // Implement download functionality
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 