import 'package:equatable/equatable.dart';

/// Base class cho tất cả các model trong ứng dụng
/// Mô hình hóa dữ liệu trong tầng presentation
abstract class BaseModel extends Equatable {
  /// Phương thức chuyển đổi từ Model sang Entity
  dynamic toEntity();
  
  /// Phương thức tạo bản sao với một số giá trị được thay đổi
  BaseModel copyWith();
  
  /// Phương thức chuyển đổi model thành JSON
  Map<String, dynamic> toJson();
  
  @override
  List<Object?> get props;
  
  @override
  bool get stringify => true;
}

/// Base class cho tất cả các entity trong ứng dụng
/// Mô hình hóa dữ liệu trong tầng domain
abstract class BaseEntity extends Equatable {
  /// Phương thức chuyển đổi từ Entity sang Model
  dynamic toModel();
  
  /// Phương thức tạo bản sao với một số giá trị được thay đổi
  BaseEntity copyWith();
  
  @override
  List<Object?> get props;
  
  @override
  bool get stringify => true;
}

/// Base class cho tất cả các data transfer object (DTO) trong ứng dụng
/// Mô hình hóa dữ liệu trong tầng data
abstract class BaseDto {
  /// Phương thức chuyển đổi từ DTO sang Entity
  dynamic toEntity();
  
  /// Phương thức chuyển đổi DTO thành JSON
  Map<String, dynamic> toJson();
  
  /// Phương thức tạo DTO từ JSON
  static BaseDto fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson() must be implemented in the subclass');
  }
} 