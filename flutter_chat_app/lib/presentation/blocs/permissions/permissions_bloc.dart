// Presentation BLoC: Permissions
// State management cho permissions UI với enterprise-grade error handling
// Tuân thủ BLoC pattern và Clean Architecture

// Dart imports
import 'dart:async';

// Third-party package imports
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

// App imports
import 'package:flutter_chat_app/core/services/permissions_service.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/shared/domain/entities/permission_entity.dart';

// Events
abstract class PermissionsEvent extends Equatable {
  const PermissionsEvent();

  @override
  List<Object?> get props => [];
}

class PermissionsInitializeEvent extends PermissionsEvent {
  const PermissionsInitializeEvent();
}

class PermissionsCheckEvent extends PermissionsEvent {
  const PermissionsCheckEvent(this.type);
  
  final PermissionType type;

  @override
  List<Object?> get props => [type];
}

class PermissionsCheckAllEvent extends PermissionsEvent {
  const PermissionsCheckAllEvent();
}

class PermissionsRequestEvent extends PermissionsEvent {
  const PermissionsRequestEvent({
    required this.type,
    this.showRationale = true,
    this.forceRequest = false,
    this.context,
  });
  
  final PermissionType type;
  final bool showRationale;
  final bool forceRequest;
  final dynamic context;

  @override
  List<Object?> get props => [type, showRationale, forceRequest, context];
}

class PermissionsRequestBatchEvent extends PermissionsEvent {
  const PermissionsRequestBatchEvent({
    required this.types,
    this.showRationale = true,
    this.stopOnFirstFailure = false,
  });
  
  final List<PermissionType> types;
  final bool showRationale;
  final bool stopOnFirstFailure;

  @override
  List<Object?> get props => [types, showRationale, stopOnFirstFailure];
}

class PermissionsOpenSettingsEvent extends PermissionsEvent {
  const PermissionsOpenSettingsEvent({this.type});
  
  final PermissionType? type;

  @override
  List<Object?> get props => [type];
}

class PermissionsResetEvent extends PermissionsEvent {
  const PermissionsResetEvent();
}

// States
abstract class PermissionsState extends Equatable {
  const PermissionsState();

  @override
  List<Object?> get props => [];
}

class PermissionsInitialState extends PermissionsState {
  const PermissionsInitialState();
}

class PermissionsLoadingState extends PermissionsState {
  const PermissionsLoadingState();
}

class PermissionsLoadedState extends PermissionsState {
  const PermissionsLoadedState({
    required this.permissions,
    required this.summary,
  });
  
  final Map<PermissionType, PermissionEntity> permissions;
  final PermissionStatusSummary summary;

  @override
  List<Object?> get props => [permissions, summary];
}

class PermissionsRequestingState extends PermissionsState {
  const PermissionsRequestingState({
    required this.type,
    required this.currentPermissions,
  });
  
  final PermissionType type;
  final Map<PermissionType, PermissionEntity> currentPermissions;

  @override
  List<Object?> get props => [type, currentPermissions];
}

class PermissionsRequestBatchingState extends PermissionsState {
  const PermissionsRequestBatchingState({
    required this.types,
    required this.currentPermissions,
    this.currentIndex = 0,
  });
  
  final List<PermissionType> types;
  final Map<PermissionType, PermissionEntity> currentPermissions;
  final int currentIndex;

  @override
  List<Object?> get props => [types, currentPermissions, currentIndex];
}

class PermissionsSuccessState extends PermissionsState {
  const PermissionsSuccessState({
    required this.permissions,
    required this.summary,
    this.message,
  });
  
  final Map<PermissionType, PermissionEntity> permissions;
  final PermissionStatusSummary summary;
  final String? message;

  @override
  List<Object?> get props => [permissions, summary, message];
}

class PermissionsErrorState extends PermissionsState {
  const PermissionsErrorState({
    required this.message,
    required this.currentPermissions,
    this.type,
  });
  
  final String message;
  final Map<PermissionType, PermissionEntity> currentPermissions;
  final PermissionType? type;

  @override
  List<Object?> get props => [message, currentPermissions, type];
}

// BLoC
@injectable
class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  
  PermissionsBloc(
    this._permissionsService,
    this._logger,
  ) : super(const PermissionsInitialState()) {
    
    on<PermissionsInitializeEvent>(_onInitialize);
    on<PermissionsCheckEvent>(_onCheck);
    on<PermissionsCheckAllEvent>(_onCheckAll);
    on<PermissionsRequestEvent>(_onRequest);
    on<PermissionsRequestBatchEvent>(_onRequestBatch);
    on<PermissionsOpenSettingsEvent>(_onOpenSettings);
    on<PermissionsResetEvent>(_onReset);
    
    // Listen to permissions service stream
    _permissionsSubscription = _permissionsService.permissionsStream.listen(
      (permissions) {
        if (state is! PermissionsRequestingState && 
            state is! PermissionsRequestBatchingState) {
          add(const PermissionsCheckAllEvent());
        }
      },
    );
  }

  final PermissionsService _permissionsService;
  final AppLogger _logger;
  
  StreamSubscription<Map<PermissionType, PermissionEntity>>? _permissionsSubscription;

  Future<void> _onInitialize(
    PermissionsInitializeEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      emit(const PermissionsLoadingState());
      
      await _permissionsService.initialize();
      
      // Load current permissions
      add(const PermissionsCheckAllEvent());
      
    } catch (e) {
      _logger.error('Error initializing permissions: $e');
      emit(PermissionsErrorState(
        message: 'Không thể khởi tạo permissions: $e',
        currentPermissions: const {},
      ));
    }
  }

  Future<void> _onCheck(
    PermissionsCheckEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      final currentPermissions = _getCurrentPermissions();
      
      final permission = await _permissionsService.checkPermission(event.type);
      final updatedPermissions = Map<PermissionType, PermissionEntity>.from(currentPermissions);
      updatedPermissions[event.type] = permission;
      
      final summary = await _permissionsService.getPermissionSummary();
      
      emit(PermissionsLoadedState(
        permissions: updatedPermissions,
        summary: summary,
      ));
      
    } catch (e) {
      _logger.error('Error checking permission ${event.type.name}: $e');
      emit(PermissionsErrorState(
        message: 'Không thể kiểm tra quyền ${event.type.name}: $e',
        currentPermissions: _getCurrentPermissions(),
        type: event.type,
      ));
    }
  }

  Future<void> _onCheckAll(
    PermissionsCheckAllEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      final summary = await _permissionsService.getPermissionSummary();
      
      // Get all permissions
      const allTypes = PermissionType.values;
      final permissions = <PermissionType, PermissionEntity>{};
      
      for (final type in allTypes) {
        permissions[type] = await _permissionsService.checkPermission(type);
      }
      
      emit(PermissionsLoadedState(
        permissions: permissions,
        summary: summary,
      ));
      
    } catch (e) {
      _logger.error('Error checking all permissions: $e');
      emit(PermissionsErrorState(
        message: 'Không thể kiểm tra permissions: $e',
        currentPermissions: _getCurrentPermissions(),
      ));
    }
  }

  Future<void> _onRequest(
    PermissionsRequestEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      final currentPermissions = _getCurrentPermissions();
      
      emit(PermissionsRequestingState(
        type: event.type,
        currentPermissions: currentPermissions,
      ));
      
      final result = await _permissionsService.requestPermission(
        event.type,
        showRationale: event.showRationale,
        forceRequest: event.forceRequest,
        context: event.context,
      );
      
      if (result.isSuccess) {
        final updatedPermissions = Map<PermissionType, PermissionEntity>.from(currentPermissions);
        updatedPermissions[event.type] = result.permission!;
        
        final summary = await _permissionsService.getPermissionSummary();
        
        emit(PermissionsSuccessState(
          permissions: updatedPermissions,
          summary: summary,
          message: 'Đã cấp quyền ${event.type.name} thành công',
        ));
      } else {
        emit(PermissionsErrorState(
          message: result.failure?.message ?? 'Không thể cấp quyền ${event.type.name}',
          currentPermissions: currentPermissions,
          type: event.type,
        ));
      }
      
    } catch (e) {
      _logger.error('Error requesting permission ${event.type.name}: $e');
      emit(PermissionsErrorState(
        message: 'Lỗi khi yêu cầu quyền ${event.type.name}: $e',
        currentPermissions: _getCurrentPermissions(),
        type: event.type,
      ));
    }
  }

  Future<void> _onRequestBatch(
    PermissionsRequestBatchEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      final currentPermissions = _getCurrentPermissions();
      
      emit(PermissionsRequestBatchingState(
        types: event.types,
        currentPermissions: currentPermissions,
      ));
      
      final result = await _permissionsService.requestPermissions(
        event.types,
        showRationale: event.showRationale,
        stopOnFirstFailure: event.stopOnFirstFailure,
      );
      
      final updatedPermissions = Map<PermissionType, PermissionEntity>.from(currentPermissions);
      updatedPermissions.addAll(result.successful);
      
      final summary = await _permissionsService.getPermissionSummary();
      
      if (result.allSuccessful) {
        emit(PermissionsSuccessState(
          permissions: updatedPermissions,
          summary: summary,
          message: 'Đã cấp tất cả quyền thành công',
        ));
      } else if (result.criticalSuccessful) {
        emit(PermissionsSuccessState(
          permissions: updatedPermissions,
          summary: summary,
          message: 'Đã cấp các quyền quan trọng thành công',
        ));
      } else {
        final failedTypes = result.failed.keys.map((t) => t.name).join(', ');
        emit(PermissionsErrorState(
          message: 'Không thể cấp một số quyền: $failedTypes',
          currentPermissions: updatedPermissions,
        ));
      }
      
    } catch (e) {
      _logger.error('Error requesting permissions batch: $e');
      emit(PermissionsErrorState(
        message: 'Lỗi khi yêu cầu nhiều quyền: $e',
        currentPermissions: _getCurrentPermissions(),
      ));
    }
  }

  Future<void> _onOpenSettings(
    PermissionsOpenSettingsEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      final success = await _permissionsService.openAppSettings(type: event.type);
      
      if (!success) {
        emit(PermissionsErrorState(
          message: 'Không thể mở cài đặt ứng dụng',
          currentPermissions: _getCurrentPermissions(),
          type: event.type,
        ));
      }
      
    } catch (e) {
      _logger.error('Error opening app settings: $e');
      emit(PermissionsErrorState(
        message: 'Lỗi khi mở cài đặt: $e',
        currentPermissions: _getCurrentPermissions(),
        type: event.type,
      ));
    }
  }

  Future<void> _onReset(
    PermissionsResetEvent event,
    Emitter<PermissionsState> emit,
  ) async {
    try {
      await _permissionsService.resetPermissionHistory();
      _permissionsService.clearCache();
      
      emit(const PermissionsInitialState());
      add(const PermissionsInitializeEvent());
      
    } catch (e) {
      _logger.error('Error resetting permissions: $e');
      emit(PermissionsErrorState(
        message: 'Không thể reset permissions: $e',
        currentPermissions: _getCurrentPermissions(),
      ));
    }
  }

  Map<PermissionType, PermissionEntity> _getCurrentPermissions() {
    final currentState = state;
    if (currentState is PermissionsLoadedState) {
      return currentState.permissions;
    } else if (currentState is PermissionsSuccessState) {
      return currentState.permissions;
    } else if (currentState is PermissionsErrorState) {
      return currentState.currentPermissions;
    } else if (currentState is PermissionsRequestingState) {
      return currentState.currentPermissions;
    } else if (currentState is PermissionsRequestBatchingState) {
      return currentState.currentPermissions;
    }
    return {};
  }

  @override
  Future<void> close() {
    _permissionsSubscription?.cancel();
    return super.close();
  }
}
