import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/app_image.dart';

/// In-memory cache for link metadata to avoid refetching on rebuild.
final Map<String, Metadata?> _linkMetadataCache = {};

/// Widget that fetches and displays a link preview card.
///
/// Uses `any_link_preview` for metadata extraction.
/// Shows image, title, description, and domain.
/// Tap opens the link via `url_launcher`.
class LinkPreviewCard extends StatefulWidget {
  final String url;
  final bool isFromCurrentUser;

  const LinkPreviewCard({
    Key? key,
    required this.url,
    this.isFromCurrentUser = false,
  }) : super(key: key);

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  Metadata? _metadata;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    // Check cache first
    if (_linkMetadataCache.containsKey(widget.url)) {
      final cached = _linkMetadataCache[widget.url];
      if (mounted) {
        setState(() {
          _metadata = cached;
          _isLoading = false;
          _hasError = cached == null;
        });
      }
      return;
    }

    try {
      final metadata = await AnyLinkPreview.getMetadata(link: widget.url);
      _linkMetadataCache[widget.url] = metadata;
      if (mounted) {
        setState(() {
          _metadata = metadata;
          _isLoading = false;
          _hasError = metadata == null;
        });
      }
    } catch (e) {
      _linkMetadataCache[widget.url] = null;
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  String _extractDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      );
    }

    if (_hasError || _metadata == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final meta = _metadata!;
    final hasImage = meta.image != null && meta.image!.isNotEmpty;
    final hasTitle = meta.title != null && meta.title!.isNotEmpty;
    final hasDescription = meta.desc != null && meta.desc!.isNotEmpty;

    if (!hasTitle && !hasDescription) return const SizedBox.shrink();

    final bgColor = widget.isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = widget.isFromCurrentUser
        ? Colors.white
        : theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isFromCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : theme.dividerColor,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              AppImage.network(
                imageUrl: meta.image!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasTitle)
                    Text(
                      meta.title!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hasDescription) ...[
                    const SizedBox(height: 4),
                    Text(
                      meta.desc!,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _extractDomain(widget.url),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.5),
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
