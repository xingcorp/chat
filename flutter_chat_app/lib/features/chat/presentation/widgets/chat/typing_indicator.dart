import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/services/animation_service.dart';

/// Widget hiển thị chỉ báo đang nhập tin nhắn
class TypingIndicator extends StatefulWidget {
  /// Tên hiển thị của người đang nhập
  final String? displayName;
  
  /// Có hiển thị tên không
  final bool showName;
  
  /// Constructor
  const TypingIndicator({
    Key? key,
    this.displayName,
    this.showName = true,
  }) : super(key: key);
  
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  /// Danh sách các controller animation
  late List<AnimationController> _controllers;
  
  /// Thời lượng animation
  late Duration _duration;
  
  @override
  void initState() {
    super.initState();
    
    // Lấy cấu hình animation từ service
    final animationService = GetIt.I<AnimationService>();
    _duration = animationService.config.defaultDuration;
    
    // Tạo controllers animation
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: _duration,
      )..repeat(reverse: true, period: Duration(
        milliseconds: (_duration.inMilliseconds * 0.8).round() + (index * 200),
      ));
    });
  }
  
  @override
  void dispose() {
    // Giải phóng controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showName && widget.displayName != null) ...[
            Text(
              context.l10n.isTyping(widget.displayName!),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.showName) ...[
            Text(
              context.l10n.someoneIsTyping,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Dots
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6 + (_controllers[index].value * 3),
                  width: 6 + (_controllers[index].value * 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Extension để thêm hiệu ứng fade in/out cho TypingIndicator
class TypingIndicatorWithFade extends StatelessWidget {
  /// Có ai đang gõ không
  final bool isTyping;
  
  /// Tên người đang gõ
  final String? displayName;
  
  /// Có hiển thị tên không
  final bool showName;
  
  /// Constructor
  const TypingIndicatorWithFade({
    Key? key,
    required this.isTyping,
    this.displayName,
    this.showName = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final animationService = GetIt.I<AnimationService>();
    
    // Nếu không dùng micro-animations hoặc thiết bị yếu
    if (!animationService.config.useMicroAnimations) {
      return isTyping
          ? TypingIndicator(displayName: displayName, showName: showName)
          : const SizedBox.shrink();
    }
    
    // Sử dụng AnimatedSwitcher để có hiệu ứng fade in/out
    return AnimatedSwitcher(
      duration: animationService.config.fastDuration,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: isTyping
          ? TypingIndicator(
              key: const ValueKey('typing'),
              displayName: displayName,
              showName: showName,
            )
          : const SizedBox.shrink(key: ValueKey('not_typing')),
    );
  }
} 