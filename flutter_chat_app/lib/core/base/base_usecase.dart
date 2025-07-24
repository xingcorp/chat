import 'dart:async';

import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/either.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';

/// Base class cho các use case không có tham số đầu vào
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Base class cho các use case có tham số đầu vào
abstract class UseCase<Type, Params> {
  /// Phương thức thực thi usecase
  /// Tham số đầu vào [params]
  /// Trả về [Either] với [Failure] bên trái và [Type] bên phải
  Future<Either<Failure, Type>> call(Params params);
  
  /// Phương thức gọi usecase với xử lý lỗi tự động
  /// Tham số đầu vào [params]
  /// Callback khi thành công [onSuccess]
  /// Callback khi thất bại [onFailure]
  Future<void> execute({
    required Params params,
    required Function(Type) onSuccess,
    required Function(Failure) onFailure,
  }) async {
    try {
      final result = await call(params);
      result.fold(
        (failure) => onFailure(failure),
        (data) => onSuccess(data),
      );
    } catch (e, stacktrace) {
      LogUtils.e('UseCase', 'Execute error: $e\n$stacktrace');
      onFailure(UnexpectedFailure(message: e.toString()));
    }
  }
}

/// Base class cho các use case stream
abstract class StreamUseCase<Type, Params> {
  /// Phương thức thực thi usecase stream
  /// Tham số đầu vào [params]
  /// Trả về Stream của [Either] với [Failure] bên trái và [Type] bên phải
  Stream<Either<Failure, Type>> call(Params params);
}

/// Base class cho các use case không có tham số đầu vào và trả về Stream
abstract class NoParamsStreamUseCase<Type> {
  /// Phương thức thực thi usecase stream không có tham số
  /// Trả về Stream của [Either] với [Failure] bên trái và [Type] bên phải
  Stream<Either<Failure, Type>> call();
} 