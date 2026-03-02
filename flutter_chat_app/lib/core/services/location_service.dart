import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/permissions_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/permission_entity.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';

/// **Location Data**
///
/// Represents geographical coordinates and location information.
class LocationData {
  /// Latitude coordinate
  final double latitude;

  /// Longitude coordinate
  final double longitude;

  /// Location name/address (optional)
  final String? name;

  /// Accuracy in meters (optional)
  final double? accuracy;

  /// Timestamp when location was captured
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.name,
    this.accuracy,
    required this.timestamp,
  });

  /// Convert to JSON for sending in message
  String toJson() {
    return jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      if (name != null) 'name': name,
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  /// Create from JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      name: json['name'] as String?,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Create from string (parse JSON)
  factory LocationData.fromJsonString(String jsonString) {
    return LocationData.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }
}

/// **Location Service Interface**
///
/// Handles location-related operations including:
/// - Getting current location
/// - Requesting location permissions
/// - Reverse geocoding (coordinates to address)
abstract class ILocationService {
  /// Get current device location
  Future<Either<Failure, LocationData>> getCurrentLocation();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Request location permissions
  Future<bool> requestLocationPermission();

  /// Get location permission status
  Future<bool> hasLocationPermission();

  /// Reverse geocode: convert coordinates to address
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  });
}

/// **Location Service Implementation**
///
/// Production implementation using geolocator package.
@LazySingleton(as: ILocationService)
class LocationService implements ILocationService {
  // Kept for backward compatibility with DI constructor signature.
  // ignore: unused_field
  final PermissionsService _permissionsService;
  final AppLogger _logger;

  LocationService(
    this._permissionsService,
    this._logger,
  );

  @override
  Future<Either<Failure, LocationData>> getCurrentLocation() async {
    try {
      _logger.info('LocationService: Getting current location');

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warn('Location services are disabled');
        return const Left(
          PermissionFailure(message: 'Location services are disabled'),
        );
      }

      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) {
          _logger.warn('Location permission denied');
          return const Left(
            PermissionFailure(message: 'Location permission denied'),
          );
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return Right(
        LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get current location', e, stackTrace);
      return Left(
        UnexpectedFailure(message: 'Failed to get location: $e'),
      );
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _logger.error('Failed to check location service status', e);
      return false;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      _logger.info('LocationService: Requesting location permission');

      if (!kIsWeb) {
        await _permissionsService.initialize();
        final result = await _permissionsService.requestPermission(
          PermissionType.location,
          showRationale: true,
        );
        return result.isSuccess && (result.permission?.isGranted ?? false);
      }

      final permission = await Geolocator.requestPermission();
      return _hasGrantedPermission(permission);
    } catch (e) {
      _logger.error('Failed to request location permission', e);
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      if (!kIsWeb) {
        await _permissionsService.initialize();
        final permission =
            await _permissionsService.checkPermission(PermissionType.location);
        return permission.isGranted;
      }

      final permission = await Geolocator.checkPermission();
      return _hasGrantedPermission(permission);
    } catch (e) {
      _logger.error('Failed to check location permission', e);
      return false;
    }
  }

  @override
  Future<Either<Failure, String>> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      _logger.info('LocationService: Reverse geocoding', {
        'latitude': latitude,
        'longitude': longitude,
      });

      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return const Left(
          NetworkFailure(message: 'No address found for this location'),
        );
      }

      final place = placemarks.first;
      final parts = <String?>[
        _normalizeAddressPart(place.street),
        _normalizeAddressPart(place.subLocality),
        _normalizeAddressPart(place.locality),
        _normalizeAddressPart(place.country),
      ].whereType<String>().toList();

      if (parts.isEmpty) {
        return const Right('Unknown location');
      }

      return Right(parts.join(', '));
    } catch (e, stackTrace) {
      _logger.error('Failed to reverse geocode', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to get address: $e'),
      );
    }
  }

  bool _hasGrantedPermission(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  String? _normalizeAddressPart(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
