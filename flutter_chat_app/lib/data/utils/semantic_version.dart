import 'package:equatable/equatable.dart';

/// Parses and compares semantic versions (major.minor.patch[-prerelease][+build]).
class SemanticVersion extends Equatable implements Comparable<SemanticVersion> {
  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.preRelease,
    this.buildMetadata,
  });

  final int major;
  final int minor;
  final int patch;
  final String? preRelease;
  final String? buildMetadata;

  /// Parse a version string like '2.1.0', 'v2.1.0-beta.1', '2.1.0+42'
  /// Throws [FormatException] if the string is not a valid semver.
  factory SemanticVersion.parse(String versionString) {
    final cleaned = versionString.startsWith('v')
        ? versionString.substring(1)
        : versionString;

    final regex = RegExp(
      r'^(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.]+))?(?:\+([a-zA-Z0-9.]+))?$',
    );

    final match = regex.firstMatch(cleaned);
    if (match == null) {
      throw FormatException('Invalid semantic version: $versionString');
    }

    return SemanticVersion(
      major: int.parse(match.group(1) ?? '0'),
      minor: int.parse(match.group(2) ?? '0'),
      patch: int.parse(match.group(3) ?? '0'),
      preRelease: match.group(4),
      buildMetadata: match.group(5),
    );
  }

  /// Try to parse, returns null on failure instead of throwing.
  static SemanticVersion? tryParse(String versionString) {
    try {
      return SemanticVersion.parse(versionString);
    } on FormatException {
      return null;
    }
  }

  /// Returns true if [this] is newer than [other].
  bool isNewerThan(SemanticVersion other) => compareTo(other) > 0;

  /// Returns true if [this] is older than [other].
  bool isOlderThan(SemanticVersion other) => compareTo(other) < 0;

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // Pre-release versions have lower precedence than release
    if (preRelease != null && other.preRelease == null) return -1;
    if (preRelease == null && other.preRelease != null) return 1;
    if (preRelease != null && other.preRelease != null) {
      return preRelease!.compareTo(other.preRelease!);
    }

    return 0; // Equal
  }

  @override
  String toString() {
    final buffer = StringBuffer('$major.$minor.$patch');
    if (preRelease != null) buffer.write('-$preRelease');
    if (buildMetadata != null) buffer.write('+$buildMetadata');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [major, minor, patch, preRelease];
}
