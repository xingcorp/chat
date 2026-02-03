/// Login Use Case
/// 
/// Handles user authentication business logic following Clean Architecture.
/// Encapsulates login flow with proper error handling and validation.
/// 
/// Author: Senior Flutter/Mobile Architect
library login_usecase;

import 'package:equatable/equatable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/utils/result.dart';
import 'package:flutter_chat_app/core/usecases/usecase.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:flutter_chat_app/features/auth/domain/repositories/auth_repository.dart';

/// Login use case parameters
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// Login use case implementation
/// 
/// Handles user authentication with proper validation and error handling.
/// Follows Clean Architecture principles by encapsulating business logic.
class LoginUseCase implements UseCase<User, LoginParams> {
  final IAuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Result<User>> call(LoginParams params) async {
    // Validate input parameters
    final validationResult = _validateParams(params);
    if (validationResult != null) {
      return Result.failure(validationResult);
    }

    // Attempt login through repository using Either pattern
    final result = await repository.login(params.email, params.password);

    return result.fold(
      (failure) => Result.failure(failure),
      (user) {
        // Additional business logic can be added here
        // For example: logging, analytics, user preferences setup
        return Result.success(user);
      },
    );
  }

  /// Validate login parameters
  ValidationFailure? _validateParams(LoginParams params) {
    final errors = <String>[];

    // Email validation
    if (params.email.isEmpty) {
      errors.add('Email không được để trống');
    } else if (!_isValidEmail(params.email)) {
      errors.add('Email không hợp lệ');
    }

    // Password validation
    if (params.password.isEmpty) {
      errors.add('Mật khẩu không được để trống');
    } else if (params.password.length < 6) {
      errors.add('Mật khẩu phải có ít nhất 6 ký tự');
    }

    if (errors.isNotEmpty) {
      return ValidationFailure(message: errors.join(', '));
    }

    return null;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Map exceptions to appropriate failures
  Failure _mapExceptionToFailure(dynamic exception) {
    if (exception is AuthenticationException) {
      return AuthenticationFailure(message: exception.message);
    } else if (exception is NetworkException) {
      return ConnectionFailure(message: exception.message);
    } else if (exception is ServerException) {
      return ServerFailure(message: exception.message);
    } else {
      return UnexpectedFailure(message: 'Đã xảy ra lỗi không xác định: ${exception.toString()}');
    }
  }
}

/// Authentication exception types
class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException(this.message);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}
