import 'package:mime/mime.dart';


/// Lớp MediaType đại diện cho một MIME type, được sử dụng
/// cho các header `Content-Type` và `Accept` trong HTTP requests.
class MediaType {
  /// Phần type chính (ví dụ: "application", "image", "text")
  final String type;
  
  /// Phần subtype (ví dụ: "json", "png", "html")
  final String subtype;
  
  /// Các tham số bổ sung (ví dụ: "charset=utf-8")
  final Map<String, String> parameters;
  
  /// Cache cho các MediaType đã parse
  static final Map<String, MediaType> _parseCache = {};
  
  /// Cache cho các MediaType từ file extension
  static final Map<String, MediaType?> _extensionCache = {};
  
  /// Constructor mặc định
  const MediaType(this.type, this.subtype, [this.parameters = const {}]);
  
  /// Tạo MediaType từ một chuỗi MIME type (ví dụ: "application/json; charset=utf-8")
  factory MediaType.parse(String mimeTypeString) {
    // Kiểm tra cache trước
    if (_parseCache.containsKey(mimeTypeString)) {
      return _parseCache[mimeTypeString]!;
    }
    
    final parts = mimeTypeString.split(';');
    final mainType = parts.first.trim().toLowerCase();
    
    final parameters = <String, String>{};
    for (var i = 1; i < parts.length; i++) {
      final param = parts[i].trim();
      if (param.contains('=')) {
        final paramParts = param.split('=');
        final key = paramParts[0].trim().toLowerCase();
        final value = paramParts[1].trim();
        parameters[key] = value.startsWith('"') && value.endsWith('"')
            ? value.substring(1, value.length - 1)
            : value;
      }
    }
    
    final typeSubtypeParts = mainType.split('/');
    if (typeSubtypeParts.length != 2) {
      throw FormatException('Invalid media type format: $mimeTypeString');
    }
    
    // Tạo và cache instance
    final mediaType = MediaType(
      typeSubtypeParts[0],
      typeSubtypeParts[1],
      parameters,
    );
    
    // Giới hạn kích thước cache
    if (_parseCache.length > 100) {
      _parseCache.remove(_parseCache.keys.first);
    }
    
    _parseCache[mimeTypeString] = mediaType;
    return mediaType;
  }
  
  /// Tạo MediaType từ file extension
  static MediaType? fromFileExtension(String extension) {
    // Kiểm tra cache trước
    if (_extensionCache.containsKey(extension)) {
      return _extensionCache[extension];
    }
    
    final mimeType = lookupMimeType('file.$extension');
    MediaType? result;
    
    if (mimeType != null) {
      result = MediaType.parse(mimeType);
    }
    
    // Giới hạn kích thước cache
    if (_extensionCache.length > 100) {
      _extensionCache.remove(_extensionCache.keys.first);
    }
    
    _extensionCache[extension] = result;
    return result;
  }
  
  /// Kiểm tra xem MediaType này có khớp với loại được chỉ định hay không
  /// (ví dụ: image/* sẽ khớp với image/png)
  bool matchesType(String typePattern) {
    if (typePattern == '*/*') {
      return true;
    }
    
    final parts = typePattern.split('/');
    if (parts.length != 2) {
      return false;
    }
    
    final typeMatch = parts[0] == '*' || parts[0].toLowerCase() == type;
    final subtypeMatch = parts[1] == '*' || parts[1].toLowerCase() == subtype;
    
    return typeMatch && subtypeMatch;
  }
  
  /// Các MediaType phổ biến
  
  /// application/json
  static const json = MediaType('application', 'json');
  
  /// application/octet-stream
  static const binary = MediaType('application', 'octet-stream');
  
  /// application/x-www-form-urlencoded
  static const formUrlEncoded = MediaType('application', 'x-www-form-urlencoded');
  
  /// multipart/form-data
  static const multipartFormData = MediaType('multipart', 'form-data');
  
  /// text/plain
  static const text = MediaType('text', 'plain', {'charset': 'utf-8'});
  
  /// text/html
  static const html = MediaType('text', 'html', {'charset': 'utf-8'});
  
  /// image/jpeg
  static const jpeg = MediaType('image', 'jpeg');
  
  /// image/png
  static const png = MediaType('image', 'png');
  
  /// image/gif
  static const gif = MediaType('image', 'gif');
  
  /// image/webp
  static const webp = MediaType('image', 'webp');
  
  /// audio/mpeg
  static const mp3 = MediaType('audio', 'mpeg');
  
  /// video/mp4
  static const mp4 = MediaType('video', 'mp4');
  
  /// Tối ưu bộ nhớ cache
  static void clearCache() {
    _parseCache.clear();
    _extensionCache.clear();
  }
  
  /// Chuyển đổi thành string header Content-Type cho Dio
  String toHeaderValue() {
    return toString();
  }
  
  @override
  String toString() {
    final buffer = StringBuffer('$type/$subtype');
    
    parameters.forEach((key, value) {
      buffer.write('; $key=$value');
    });
    
    return buffer.toString();
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MediaType) return false;
    
    return type == other.type && 
           subtype == other.subtype &&
           _mapsEqual(parameters, other.parameters);
  }
  
  @override
  int get hashCode => Object.hash(type, subtype, parameters.toString());
  
  /// So sánh bằng cho maps
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key) || b[key] != a[key]) {
        return false;
      }
    }
    
    return true;
  }
} 