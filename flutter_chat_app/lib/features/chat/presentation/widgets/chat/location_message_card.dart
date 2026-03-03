import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
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

class LocationMessageCard extends StatefulWidget {
  final LocationMessageData location;
  final bool isFromCurrentUser;

  const LocationMessageCard({
    super.key,
    required this.location,
    required this.isFromCurrentUser,
  });

  @override
  State<LocationMessageCard> createState() => _LocationMessageCardState();
}

class _LocationMessageCardState extends State<LocationMessageCard> {
  static const int _mapZoom = 15;
  int _activeMapSourceIndex = 0;
  bool _isSwitchingSource = false;
  late List<Uri> _mapSources;

  @override
  void initState() {
    super.initState();
    _mapSources = _buildMapSources();
  }

  @override
  void didUpdateWidget(covariant LocationMessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.latitude != widget.location.latitude ||
        oldWidget.location.longitude != widget.location.longitude) {
      _mapSources = _buildMapSources();
      _activeMapSourceIndex = 0;
      _isSwitchingSource = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = widget.isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = widget.isFromCurrentUser
        ? Colors.white.withValues(alpha: 0.2)
        : theme.dividerColor;
    final footerColor = widget.isFromCurrentUser
        ? theme.colorScheme.primary.withValues(alpha: 0.88)
        : theme.colorScheme.primaryContainer.withValues(alpha: 0.96);
    final footerTextColor = widget.isFromCurrentUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onPrimaryContainer;
    final locationTitle = widget.location.name?.trim().isNotEmpty == true
        ? widget.location.name!.trim()
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _mapSources[_activeMapSourceIndex].toString(),
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 220),
                    memCacheHeight: 420,
                    memCacheWidth: 900,
                    placeholder: (_, __) => _buildMapLoading(theme),
                    errorWidget: (_, __, ___) {
                      _switchMapSource();
                      return _buildMapFallback(theme);
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x22000000),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.location_on,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: footerColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            locationTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: footerTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.0,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '${widget.location.latitude.toStringAsFixed(5)}, '
                            '${widget.location.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              color: footerTextColor.withValues(alpha: 0.8),
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 18.0,
                      color: footerTextColor.withValues(alpha: 0.92),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchMapSource() {
    if (_isSwitchingSource) return;
    if (_activeMapSourceIndex >= _mapSources.length - 1) return;

    _isSwitchingSource = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _activeMapSourceIndex += 1;
        _isSwitchingSource = false;
      });
    });
  }

  Widget _buildMapLoading(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: SizedBox(
        width: 22.0,
        height: 22.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildMapFallback(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(
        Icons.map_outlined,
        size: 26.0,
        color: theme.colorScheme.primary,
      ),
    );
  }

  List<Uri> _buildMapSources() {
    final latitude = widget.location.latitude;
    final longitude = widget.location.longitude;
    final tile = _latLonToTile(
      latitude: latitude,
      longitude: longitude,
      zoom: _mapZoom,
    );

    return [
      Uri.https(
        'staticmap.openstreetmap.de',
        '/staticmap.php',
        {
          'center': '$latitude,$longitude',
          'zoom': '$_mapZoom',
          'size': '900x420',
          'markers': '$latitude,$longitude,red-pushpin',
        },
      ),
      Uri.https(
        'tile.openstreetmap.org',
        '/$_mapZoom/${tile.x}/${tile.y}.png',
      ),
      Uri.https(
        'a.basemaps.cartocdn.com',
        '/light_all/$_mapZoom/${tile.x}/${tile.y}.png',
      ),
    ];
  }

  _MapTileCoordinate _latLonToTile({
    required double latitude,
    required double longitude,
    required int zoom,
  }) {
    final latRad = latitude * math.pi / 180.0;
    final n = math.pow(2.0, zoom).toDouble();

    final x = ((longitude + 180.0) / 360.0 * n).floor();
    final y =
        ((1.0 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) /
                2.0 *
                n)
            .floor();

    return _MapTileCoordinate(x: x, y: y);
  }

  Future<void> _openInMaps() async {
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${widget.location.latitude},${widget.location.longitude}',
    );
    final fallbackUri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${widget.location.latitude}'
      '&mlon=${widget.location.longitude}'
      '#map=15/${widget.location.latitude}/${widget.location.longitude}',
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      return;
    }

    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    }
  }
}

class _MapTileCoordinate {
  final int x;
  final int y;

  const _MapTileCoordinate({
    required this.x,
    required this.y,
  });
}
