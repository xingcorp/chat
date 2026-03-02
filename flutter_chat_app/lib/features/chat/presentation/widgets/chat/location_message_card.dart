import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMessageData {
  final double latitude;
  final double longitude;
  final String? name;

  const LocationMessageData({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  static LocationMessageData? tryParse(String rawContent) {
    try {
      final decoded = jsonDecode(rawContent);
      if (decoded is! Map<String, dynamic>) return null;

      final latitude = (decoded['latitude'] as num?)?.toDouble();
      final longitude = (decoded['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return null;

      final rawName = decoded['name'];
      final name = rawName is String && rawName.trim().isNotEmpty
          ? rawName.trim()
          : null;

      return LocationMessageData(
        latitude: latitude,
        longitude: longitude,
        name: name,
      );
    } catch (_) {
      return null;
    }
  }
}

class LocationMessageCard extends StatelessWidget {
  final LocationMessageData location;
  final bool isFromCurrentUser;

  const LocationMessageCard({
    super.key,
    required this.location,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isFromCurrentUser
        ? theme.colorScheme.onPrimary
        : theme.textTheme.bodyMedium?.color ?? Colors.black;
    final borderColor = isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.2)
        : theme.dividerColor;
    final locationTitle = location.name?.trim().isNotEmpty == true
        ? location.name!.trim()
        : context.l10n.shareLocation;

    return GestureDetector(
      onTap: _openInMaps,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 140.0,
              child: Image.network(
                _buildStaticMapUri().toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locationTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.0,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${location.latitude.toStringAsFixed(5)}, '
                    '${location.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12.0,
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

  Uri _buildStaticMapUri() {
    return Uri.https(
      'staticmap.openstreetmap.de',
      '/staticmap.php',
      {
        'center': '${location.latitude},${location.longitude}',
        'zoom': '15',
        'size': '800x400',
        'markers': '${location.latitude},${location.longitude},red-pushpin',
      },
    );
  }

  Future<void> _openInMaps() async {
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${location.latitude},${location.longitude}',
    );
    if (!await canLaunchUrl(mapsUri)) return;

    await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }
}
