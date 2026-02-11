import 'package:flutter/material.dart';

/// Data class for a reader's info
class ReaderInfo {
  final String userId;
  final String name;
  final String? avatarUrl;

  const ReaderInfo({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });
}

/// Stacked circular avatars showing who has read a message.
///
/// Shows max 3 avatars with initials, overlapping style.
/// Tap shows tooltip/snackbar with all reader names.
class ReadReceiptAvatars extends StatelessWidget {
  final List<ReaderInfo> readers;
  final int maxVisible;

  const ReadReceiptAvatars({
    Key? key,
    required this.readers,
    this.maxVisible = 3,
  }) : super(key: key);

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (readers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final visibleReaders = readers.take(maxVisible).toList();
    final remaining = readers.length - maxVisible;
    const radius = 8.0;
    const overlap = 12.0;

    return GestureDetector(
      onTap: () {
        final names = readers.map((r) => r.name).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(names),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: SizedBox(
        height: radius * 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: overlap * (visibleReaders.length - 1) + radius * 2 + (remaining > 0 ? 16 : 0),
              child: Stack(
                children: [
                  for (int i = 0; i < visibleReaders.length; i++)
                    Positioned(
                      left: i * overlap,
                      child: Container(
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7 + i * 0.1),
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(visibleReaders[i].name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (remaining > 0)
                    Positioned(
                      left: visibleReaders.length * overlap,
                      child: Text(
                        '+$remaining',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
