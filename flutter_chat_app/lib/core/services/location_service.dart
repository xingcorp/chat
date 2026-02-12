import 'dart:async';
import 'dart:convert';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/services/permissions_service.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:injectable/injectable.dart';
// Note: geolocator package needs to be added to pubspec.yaml
// For now, using placeholder implementation

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
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Create from string (parse JSON)
  factory LocationData.fromJsonString(String jsonString) {
    return LocationData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
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
///
/// **TODO**: Add geolocator package to pubspec.yaml:
/// ```yaml
/// dependencies:
///   geolocator: ^11.0.0
///   geocoding: ^3.0.0
/// ```
@LazySingleton(as: ILocationService)
class LocationService implements ILocationService {
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

      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.warn('Location services are disabled');
        return const Left(
          PermissionFailure(message: 'Location services are disabled'),
        );
      }

      // Check/request permissions
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

      // TODO: Implement actual geolocator integration
      // For now, return mock data
      //
      // Real implementation:
      // import 'package:geolocator/geolocator.dart';
      // final position = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );
      //
      // return Right(
      //   LocationData(
      //     latitude: position.latitude,
      //     longitude: position.longitude,
      //     accuracy: position.accuracy,
      //     timestamp: position.timestamp ?? DateTime.now(),
      //   ),
      // );

      _logger.warn('Using mock location data - geolocator not implemented yet');
      return Right(
        LocationData(
          latitude: 10.7769, // Saigon
          longitude: 106.7009,
          name: 'Mock Location',
          accuracy: 10.0,
          timestamp: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get current location', e, stackTrace);
      return Left(
        UnexpectedFailure(message: 'Failed to get location: ${e.toString()}'),
      );
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      // TODO: Implement actual check
      // Real implementation:
      // import 'package:geolocator/geolocator.dart';
      // return await Geolocator.isLocationServiceEnabled();

      _logger.debug('Checking location service status (mock)');
      return true; // Mock implementation
    } catch (e) {
      _logger.error('Failed to check location service status', e);
      return false;
    }
  }

  @override
  Future<bool> requestLocationPermission() async {
    try {
      _logger.info('LocationService: Requesting location permission');

      // TODO: Implement actual permission request
      // Real implementation:
      // import 'package:geolocator/geolocator.dart';
      // final permission = await Geolocator.requestPermission();
      // return permission == LocationPermission.always ||
      //        permission == LocationPermission.whileInUse;

      // For now, use PermissionsService if available
      // This is a placeholder
      return true;
    } catch (e) {
      _logger.error('Failed to request location permission', e);
      return false;
    }
  }

  @override
  Future<bool> hasLocationPermission() async {
    try {
      // TODO: Implement actual permission check
      // Real implementation:
      // import 'package:geolocator/geolocator.dart';
      // final permission = await Geolocator.checkPermission();
      // return permission == LocationPermission.always ||
      //        permission == LocationPermission.whileInUse;

      return true; // Mock implementation
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

      // TODO: Implement actual reverse geocoding
      // Real implementation:
      // import 'package:geocoding/geocoding.dart';
      // final placemarks = await placemarkFromCoordinates(latitude, longitude);
      // if (placemarks.isNotEmpty) {
      //   final place = placemarks.first;
      //   return Right(
      //     '${place.street}, ${place.locality}, ${place.country}',
      //   );
      // }

      // Mock address
      return const Right('Mock Address, Ho Chi Minh City, Vietnam');
    } catch (e, stackTrace) {
      _logger.error('Failed to reverse geocode', e, stackTrace);
      return Left(
        NetworkFailure(message: 'Failed to get address: ${e.toString()}'),
      );
    }
  }
}
