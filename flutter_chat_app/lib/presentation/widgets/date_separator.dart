import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/core/services/date_formatter_service.dart';

/// Widget hiển thị ngày phân cách giữa các nhóm tin nhắn
class DateSeparator extends StatelessWidget {
  /// Ngày cần hiển thị
  final DateTime date;
  
  /// Chiều rộng tối đa của widget
  final double? maxWidth;

  const DateSeparator({
    Key? key,
    required this.date,
    this.maxWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormatterService.formatDateForGrouping(date);
    
    return Container(
      constraints: maxWidth != null 
          ? BoxConstraints(maxWidth: maxWidth!) 
          : null,
      margin: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            formattedDate,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
} 