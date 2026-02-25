# Chat Info Panel - Kế Hoạch Triển Khai Chi Tiết

> **Model**: Claude Opus 4.5
> **Date**: 2026-02-25
> **Tuân thủ**: Design System Usage + Project Architecture Guidelines

---

## ✅ Checklist Tuân Thủ Bắt Buộc

### Design System (MANDATORY)
- [ ] **KHÔNG** sử dụng `Text` - SỬ DỤNG `AppText` với `context.l10n`
- [ ] **KHÔNG** sử dụng `ListView.builder` - SỬ DỤNG `AppListView`
- [ ] **KHÔNG** sử dụng `GridView.builder` - SỬ DỤNG `AppGridView`
- [ ] **KHÔNG** sử dụng `TextField` - SỬ DỤNG `AppTextField`
- [ ] **KHÔNG** sử dụng `ElevatedButton` - SỬ DỤNG `AppButton`
- [ ] **KHÔNG** sử dụng `Container` trực tiếp cho cards - SỬ DỤNG `AppCard`
- [ ] **KHÔNG** sử dụng `AlertDialog` - SỬ DỤNG `AppAlertDialog.show()`
- [ ] **KHÔNG** hardcode strings - SỬ DỤNG `context.l10n.keyName`
- [ ] **KHÔNG** sử dụng `Colors.*` - SỬ DỤNG `AppColors.*DarkMode`
- [ ] **KHÔNG** hardcode dimensions - SỬ DỤNG `AppDimens.*`

### Clean Architecture (MANDATORY)
- [ ] BLoC **PHẢI** extend `BaseBloc<Event, State>`
- [ ] State **PHẢI** extend `BaseState` với `@freezed`
- [ ] StatefulWidget **PHẢI** extend `BaseStatefulWidget`
- [ ] StatelessWidget **PHẢI** extend `BaseStatelessWidget`
- [ ] Repository **PHẢI** trả về `Either<Failure, T>`
- [ ] **KHÔNG** import Flutter packages trong Domain layer
- [ ] **KHÔNG** import Data models trong Presentation layer
- [ ] **PHẢI** sử dụng Logger service, **KHÔNG** dùng `print()`

---

## Phase 1: Domain Layer (Business Logic - NO Flutter imports)

### 1.1 Entities (Domain Models)

#### File: `lib/domain/entities/chat_info/shared_media.dart`
```dart
import 'package:equatable/equatable.dart';

/// Loại media được chia sẻ
enum SharedMediaType {
  photo,
  video,
  file,
  link,
}

/// Entity cho media được chia sẻ trong chat
class SharedMedia extends Equatable {
  final String id;
  final SharedMediaType type;
  final String url;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final String senderId;
  final String senderName;

  const SharedMedia({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.senderId,
    required this.senderName,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        url,
        thumbnailUrl,
        fileName,
        fileSize,
        createdAt,
        senderId,
        senderName,
      ];
}
```

#### File: `lib/domain/entities/chat_info/notification_settings.dart`
```dart
import 'package:equatable/equatable.dart';

/// Thời lượng mute notification
enum MuteDuration {
  oneHour,
  eightHours,
  oneDay,
  forever,
}

/// Entity cho notification settings
class NotificationSettings extends Equatable {
  final String chatId;
  final bool isMuted;
  final DateTime? mutedUntil;
  final bool mentionOnly;

  const NotificationSettings({
    required this.chatId,
    required this.isMuted,
    this.mutedUntil,
    this.mentionOnly = false,
  });

  NotificationSettings copyWith({
    String? chatId,
    bool? isMuted,
    DateTime? mutedUntil,
    bool? mentionOnly,
  }) {
    return NotificationSettings(
      chatId: chatId ?? this.chatId,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      mentionOnly: mentionOnly ?? this.mentionOnly,
    );
  }

  @override
  List<Object?> get props => [chatId, isMuted, mutedUntil, mentionOnly];
}
```

### 1.2 Repository Interfaces

#### File: `lib/domain/repositories/i_chat_info_repository.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

/// Repository interface cho Chat Info
abstract class IChatInfoRepository {
  /// Lấy danh sách shared media theo loại
  Future<Either<Failure, List<SharedMedia>>> getSharedMedia({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  });

  /// Lấy notification settings
  Future<Either<Failure, NotificationSettings>> getNotificationSettings({
    required String chatId,
  });

  /// Cập nhật notification settings
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    required String chatId,
    required NotificationSettings settings,
  });

  /// Block user (direct chat only)
  Future<Either<Failure, void>> blockUser({
    required String userId,
  });

  /// Unblock user
  Future<Either<Failure, void>> unblockUser({
    required String userId,
  });

  /// Report chat/user
  Future<Either<Failure, void>> reportChat({
    required String chatId,
    required String reason,
  });
}
```

### 1.3 Use Cases

#### File: `lib/domain/usecases/chat_info/get_shared_media_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để lấy shared media
@injectable
class GetSharedMediaUseCase {
  final IChatInfoRepository _repository;

  GetSharedMediaUseCase(this._repository);

  Future<Either<Failure, List<SharedMedia>>> call({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  }) async {
    return await _repository.getSharedMedia(
      chatId: chatId,
      type: type,
      limit: limit,
      offset: offset,
    );
  }
}
```

#### File: `lib/domain/usecases/chat_info/update_notification_settings_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để cập nhật notification settings
@injectable
class UpdateNotificationSettingsUseCase {
  final IChatInfoRepository _repository;

  UpdateNotificationSettingsUseCase(this._repository);

  Future<Either<Failure, NotificationSettings>> call({
    required String chatId,
    required NotificationSettings settings,
  }) async {
    return await _repository.updateNotificationSettings(
      chatId: chatId,
      settings: settings,
    );
  }
}
```

#### File: `lib/domain/usecases/chat_info/block_user_usecase.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// UseCase để block user
@injectable
class BlockUserUseCase {
  final IChatInfoRepository _repository;

  BlockUserUseCase(this._repository);

  Future<Either<Failure, void>> call({required String userId}) async {
    return await _repository.blockUser(userId: userId);
  }
}
```

---

## Phase 2: Data Layer

### 2.1 Models với Mappers

#### File: `lib/data/models/chat_info/shared_media_model.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';

part 'shared_media_model.freezed.dart';
part 'shared_media_model.g.dart';

/// Model cho shared media (Data layer)
@freezed
class SharedMediaModel with _$SharedMediaModel {
  const factory SharedMediaModel({
    required String id,
    required String type,
    required String url,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    required DateTime createdAt,
    required String senderId,
    required String senderName,
  }) = _SharedMediaModel;

  factory SharedMediaModel.fromJson(Map<String, dynamic> json) =>
      _$SharedMediaModelFromJson(json);

  const SharedMediaModel._();

  /// Convert model to domain entity
  SharedMedia toEntity() {
    return SharedMedia(
      id: id,
      type: _parseMediaType(type),
      url: url,
      thumbnailUrl: thumbnailUrl,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: createdAt,
      senderId: senderId,
      senderName: senderName,
    );
  }

  /// Convert từ entity sang model
  static SharedMediaModel fromEntity(SharedMedia entity) {
    return SharedMediaModel(
      id: entity.id,
      type: entity.type.name,
      url: entity.url,
      thumbnailUrl: entity.thumbnailUrl,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      createdAt: entity.createdAt,
      senderId: entity.senderId,
      senderName: entity.senderName,
    );
  }

  static SharedMediaType _parseMediaType(String type) {
    switch (type.toLowerCase()) {
      case 'photo':
        return SharedMediaType.photo;
      case 'video':
        return SharedMediaType.video;
      case 'file':
        return SharedMediaType.file;
      case 'link':
        return SharedMediaType.link;
      default:
        return SharedMediaType.file;
    }
  }
}
```

#### File: `lib/data/models/chat_info/notification_settings_model.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

part 'notification_settings_model.freezed.dart';
part 'notification_settings_model.g.dart';

@freezed
class NotificationSettingsModel with _$NotificationSettingsModel {
  const factory NotificationSettingsModel({
    required String chatId,
    required bool isMuted,
    DateTime? mutedUntil,
    @Default(false) bool mentionOnly,
  }) = _NotificationSettingsModel;

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsModelFromJson(json);

  const NotificationSettingsModel._();

  NotificationSettings toEntity() {
    return NotificationSettings(
      chatId: chatId,
      isMuted: isMuted,
      mutedUntil: mutedUntil,
      mentionOnly: mentionOnly,
    );
  }

  static NotificationSettingsModel fromEntity(NotificationSettings entity) {
    return NotificationSettingsModel(
      chatId: entity.chatId,
      isMuted: entity.isMuted,
      mutedUntil: entity.mutedUntil,
      mentionOnly: entity.mentionOnly,
    );
  }
}
```

### 2.2 Data Sources

#### File: `lib/data/datasources/chat_info/chat_info_remote_datasource.dart`
```dart
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/data/models/chat_info/shared_media_model.dart';
import 'package:flutter_chat_app/data/models/chat_info/notification_settings_model.dart';
import 'package:flutter_chat_app/core/network/api_client.dart';

/// Remote data source interface
abstract class IChatInfoRemoteDataSource {
  Future<List<SharedMediaModel>> getSharedMedia({
    required String chatId,
    required String type,
    int? limit,
    int? offset,
  });

  Future<NotificationSettingsModel> getNotificationSettings({
    required String chatId,
  });

  Future<NotificationSettingsModel> updateNotificationSettings({
    required String chatId,
    required Map<String, dynamic> settings,
  });

  Future<void> blockUser({required String userId});
  Future<void> unblockUser({required String userId});
  Future<void> reportChat({required String chatId, required String reason});
}

/// Implementation
@LazySingleton(as: IChatInfoRemoteDataSource)
class ChatInfoRemoteDataSource implements IChatInfoRemoteDataSource {
  final ApiClient _apiClient;

  ChatInfoRemoteDataSource(this._apiClient);

  @override
  Future<List<SharedMediaModel>> getSharedMedia({
    required String chatId,
    required String type,
    int? limit,
    int? offset,
  }) async {
    // TODO: Implement GraphQL query hoặc REST endpoint
    // Tạm thời return empty list
    return [];
  }

  @override
  Future<NotificationSettingsModel> getNotificationSettings({
    required String chatId,
  }) async {
    // TODO: Implement API call
    return const NotificationSettingsModel(
      chatId: '',
      isMuted: false,
    );
  }

  @override
  Future<NotificationSettingsModel> updateNotificationSettings({
    required String chatId,
    required Map<String, dynamic> settings,
  }) async {
    // TODO: Implement API call
    return NotificationSettingsModel.fromJson(settings);
  }

  @override
  Future<void> blockUser({required String userId}) async {
    // TODO: Implement API call
  }

  @override
  Future<void> unblockUser({required String userId}) async {
    // TODO: Implement API call
  }

  @override
  Future<void> reportChat({
    required String chatId,
    required String reason,
  }) async {
    // TODO: Implement API call
  }
}
```

### 2.3 Repository Implementation

#### File: `lib/data/repositories/chat_info_repository_impl.dart`
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/core/error/exceptions.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';
import 'package:flutter_chat_app/data/datasources/chat_info/chat_info_remote_datasource.dart';
import 'package:flutter_chat_app/data/models/chat_info/notification_settings_model.dart';

@LazySingleton(as: IChatInfoRepository)
class ChatInfoRepositoryImpl implements IChatInfoRepository {
  final IChatInfoRemoteDataSource _remoteDataSource;

  ChatInfoRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<SharedMedia>>> getSharedMedia({
    required String chatId,
    required SharedMediaType type,
    int? limit,
    int? offset,
  }) async {
    try {
      final models = await _remoteDataSource.getSharedMedia(
        chatId: chatId,
        type: type.name,
        limit: limit,
        offset: offset,
      );

      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> getNotificationSettings({
    required String chatId,
  }) async {
    try {
      final model = await _remoteDataSource.getNotificationSettings(
        chatId: chatId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }

  @override
  Future<Either<Failure, NotificationSettings>> updateNotificationSettings({
    required String chatId,
    required NotificationSettings settings,
  }) async {
    try {
      final model = await _remoteDataSource.updateNotificationSettings(
        chatId: chatId,
        settings: NotificationSettingsModel.fromEntity(settings).toJson(),
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser({required String userId}) async {
    try {
      await _remoteDataSource.blockUser(userId: userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser({required String userId}) async {
    try {
      await _remoteDataSource.unblockUser(userId: userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }

  @override
  Future<Either<Failure, void>> reportChat({
    required String chatId,
    required String reason,
  }) async {
    try {
      await _remoteDataSource.reportChat(chatId: chatId, reason: reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: '$e'));
    }
  }
}
```

---

## Phase 3: Presentation Layer - BLoC

### 3.1 Events

#### File: `lib/presentation/blocs/chat_info/chat_info_event.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';

part 'chat_info_event.freezed.dart';

@freezed
class ChatInfoEvent with _$ChatInfoEvent {
  /// Load shared media
  const factory ChatInfoEvent.loadSharedMedia({
    required String chatId,
    required SharedMediaType type,
  }) = ChatInfoLoadSharedMedia;

  /// Load notification settings
  const factory ChatInfoEvent.loadNotificationSettings({
    required String chatId,
  }) = ChatInfoLoadNotificationSettings;

  /// Update notification settings
  const factory ChatInfoEvent.updateNotificationSettings({
    required NotificationSettings settings,
  }) = ChatInfoUpdateNotificationSettings;

  /// Block user
  const factory ChatInfoEvent.blockUser({
    required String userId,
  }) = ChatInfoBlockUser;

  /// Report chat
  const factory ChatInfoEvent.reportChat({
    required String chatId,
    required String reason,
  }) = ChatInfoReportChat;
}
```

### 3.2 States

#### File: `lib/presentation/blocs/chat_info/chat_info_state.dart`
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_app/core/error/failures.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/shared_media.dart';
import 'package:flutter_chat_app/domain/entities/chat_info/notification_settings.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';

part 'chat_info_state.freezed.dart';

@freezed
class ChatInfoState extends BaseState with _$ChatInfoState {
  const factory ChatInfoState.initial() = ChatInfoInitial;

  const factory ChatInfoState.loading({
    String? message,
  }) = ChatInfoLoading;

  const factory ChatInfoState.sharedMediaLoaded({
    required List<SharedMedia> media,
    required SharedMediaType type,
  }) = ChatInfoSharedMediaLoaded;

  const factory ChatInfoState.notificationSettingsLoaded({
    required NotificationSettings settings,
  }) = ChatInfoNotificationSettingsLoaded;

  const factory ChatInfoState.notificationSettingsUpdated({
    required NotificationSettings settings,
  }) = ChatInfoNotificationSettingsUpdated;

  const factory ChatInfoState.userBlocked({
    required String userId,
  }) = ChatInfoUserBlocked;

  const factory ChatInfoState.chatReported() = ChatInfoChatReported;

  const factory ChatInfoState.error({
    required String message,
    Failure? failure,
    VoidCallback? retryAction,
  }) = ChatInfoError;
}
```

### 3.3 BLoC Implementation

#### File: `lib/presentation/blocs/chat_info/chat_info_bloc.dart`
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_state.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/get_shared_media_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/update_notification_settings_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/block_user_usecase.dart';

@injectable
class ChatInfoBloc extends BaseBloc<ChatInfoEvent, ChatInfoState> {
  final GetSharedMediaUseCase _getSharedMediaUseCase;
  final UpdateNotificationSettingsUseCase _updateNotificationSettingsUseCase;
  final BlockUserUseCase _blockUserUseCase;
  final Logger _logger;

  ChatInfoBloc({
    required GetSharedMediaUseCase getSharedMediaUseCase,
    required UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase,
    required BlockUserUseCase blockUserUseCase,
    required Logger logger,
  })  : _getSharedMediaUseCase = getSharedMediaUseCase,
        _updateNotificationSettingsUseCase = updateNotificationSettingsUseCase,
        _blockUserUseCase = blockUserUseCase,
        _logger = logger,
        super(const ChatInfoState.initial()) {
    on<ChatInfoLoadSharedMedia>(_onLoadSharedMedia);
    on<ChatInfoUpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<ChatInfoBlockUser>(_onBlockUser);
  }

  Future<void> _onLoadSharedMedia(
    ChatInfoLoadSharedMedia event,
    Emitter<ChatInfoState> emit,
  ) async {
    emitLoading(message: 'Loading media...');

    _logger.d('Loading shared media: ${event.type}');

    final result = await _getSharedMediaUseCase(
      chatId: event.chatId,
      type: event.type,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load shared media', error: failure);
        emitError(
          failure.message,
          error: failure,
          retryAction: () => add(event),
        );
      },
      (media) {
        _logger.i('Loaded ${media.length} media items');
        emit(ChatInfoState.sharedMediaLoaded(
          media: media,
          type: event.type,
        ));
      },
    );
  }

  Future<void> _onUpdateNotificationSettings(
    ChatInfoUpdateNotificationSettings event,
    Emitter<ChatInfoState> emit,
  ) async {
    emitLoading(message: 'Updating settings...');

    final result = await _updateNotificationSettingsUseCase(
      chatId: event.settings.chatId,
      settings: event.settings,
    );

    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (settings) => emit(ChatInfoState.notificationSettingsUpdated(
        settings: settings,
      )),
    );
  }

  Future<void> _onBlockUser(
    ChatInfoBlockUser event,
    Emitter<ChatInfoState> emit,
  ) async {
    emitLoading(message: 'Blocking user...');

    final result = await _blockUserUseCase(userId: event.userId);

    result.fold(
      (failure) => emitError(failure.message, error: failure),
      (_) => emit(ChatInfoState.userBlocked(userId: event.userId)),
    );
  }

  @override
  Future<void> close() {
    _logger.d('ChatInfoBloc closed');
    return super.close();
  }
}
```

---

## Phase 4: UI Widgets (TUÂN THỦ DESIGN SYSTEM)

### 4.1 Main Panel Widget

#### File: `lib/presentation/widgets/chat_info/chat_info_panel.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_bloc.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/chat_info_header.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/members_section.dart';
import 'package:flutter_chat_app/presentation/widgets/chat_info/user_info_section.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/buttons.dart';

/// Chat Info Panel Widget - TUÂN THỦ DESIGN SYSTEM
class ChatInfoPanel extends BaseStatelessWidget {
  final Chat chat;
  final VoidCallback? onClose;

  const ChatInfoPanel({
    Key? key,
    required this.chat,
    this.onClose,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<ChatInfoBloc>(),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            ChatInfoHeader(
              chat: chat,
              onClose: onClose,
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User info (Direct chat) or Members (Group)
                    if (chat.type == ChatType.direct)
                      UserInfoSection(chat: chat)
                    else
                      MembersSection(chat: chat),

                    // TODO: SharedMediaSection
                    // TODO: SettingsSection
                    // TODO: DangerZoneSection
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4.2 Header Widget

#### File: `lib/presentation/widgets/chat_info/chat_info_header.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/base/base_widget.dart';
import 'package:flutter_chat_app/core/theme/app_colors.dart';
import 'package:flutter_chat_app/core/constants/app_dimens.dart';
import 'package:flutter_chat_app/l10n/l10n.dart';
import 'package:flutter_chat_app/shared/domain/entities/chat.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/typography/app_text.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/media/media.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/buttons/buttons.dart';

/// Header cho Chat Info Panel - TUÂN THỦ DESIGN SYSTEM
class ChatInfoHeader extends BaseStatelessWidget {
  final Chat chat;
  final VoidCallback? onClose;

  const ChatInfoHeader({
    Key? key,
    required this.chat,
    this.onClose,
  }) : super(key: key);

  @override
  Widget buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(AppDimens.paddingMedium),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDarkMode
            : AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Close button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                context.l10n.chatInfo,
                style: AppTextStyle.titleLarge,
                color: isDark
                    ? AppColors.textPrimaryDarkMode
                    : AppColors.textPrimary,
              ),
              AppIconButton(
                icon: Icons.close,
                onPressed: onClose,
                tooltip: context.l10n.close,
              ),
            ],
          ),

          SizedBox(height: AppDimens.spaceMedium),

          // Avatar
          AppAvatar(
            imageUrl: chat.avatarUrl,
            size: AvatarSize.large,
            fallbackText: chat.name?.substring(0, 1),
          ),

          SizedBox(height: AppDimens.spaceSmall),

          // Name
          AppText(
            chat.name ?? '',
            style: AppTextStyle.headlineSmall,
            color: isDark
                ? AppColors.textPrimaryDarkMode
                : AppColors.textPrimary,
          ),

          // Status/Member count
          if (chat.type == ChatType.group)
            AppText(
              context.l10n.membersCount(chat.members.length),
              style: AppTextStyle.bodyMedium,
              color: isDark
                  ? AppColors.textSecondaryDarkMode
                  : AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
```

---

## Phase 5: Localization

### File: `lib/l10n/app_en.arb`
```json
{
  "chatInfo": "Chat Info",
  "members": "Members",
  "membersCount": "{count, plural, =0{No members} =1{1 member} other{{count} members}}",
  "@membersCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "addMembers": "Add Members",
  "sharedMedia": "Shared Media",
  "photos": "Photos",
  "videos": "Videos",
  "files": "Files",
  "links": "Links",
  "notifications": "Notifications",
  "muteNotifications": "Mute Notifications",
  "muteFor": "Mute for",
  "oneHour": "1 hour",
  "eightHours": "8 hours",
  "oneDay": "1 day",
  "forever": "Forever",
  "blockUser": "Block User",
  "unblockUser": "Unblock User",
  "leaveGroup": "Leave Group",
  "deleteChat": "Delete Chat",
  "report": "Report",
  "admin": "Admin",
  "owner": "Owner",
  "removeFromGroup": "Remove from Group",
  "makeAdmin": "Make Admin",
  "removeAdmin": "Remove Admin",
  "viewProfile": "View Profile",
  "close": "Close"
}
```

### File: `lib/l10n/app_vi.arb`
```json
{
  "chatInfo": "Thông tin chat",
  "members": "Thành viên",
  "membersCount": "{count, plural, =0{Không có thành viên} =1{1 thành viên} other{{count} thành viên}}",
  "addMembers": "Thêm thành viên",
  "sharedMedia": "Media đã chia sẻ",
  "photos": "Ảnh",
  "videos": "Video",
  "files": "Tệp",
  "links": "Liên kết",
  "notifications": "Thông báo",
  "muteNotifications": "Tắt thông báo",
  "muteFor": "Tắt trong",
  "oneHour": "1 giờ",
  "eightHours": "8 giờ",
  "oneDay": "1 ngày",
  "forever": "Vĩnh viễn",
  "blockUser": "Chặn người dùng",
  "unblockUser": "Bỏ chặn",
  "leaveGroup": "Rời nhóm",
  "deleteChat": "Xóa chat",
  "report": "Báo cáo",
  "admin": "Quản trị viên",
  "owner": "Chủ sở hữu",
  "removeFromGroup": "Xóa khỏi nhóm",
  "makeAdmin": "Đặt làm quản trị viên",
  "removeAdmin": "Gỡ quản trị viên",
  "viewProfile": "Xem hồ sơ",
  "close": "Đóng"
}
```

---

## Phase 6: Integration vào ChatDetailsPage

### File: `lib/features/chat/presentation/pages/chat/chat_details_page.dart`
```dart
// Thêm vào existing file

void _showChatInfo() {
  final screenWidth = MediaQuery.of(context).size.width;
  final isWideScreen = screenWidth > 900;

  if (isWideScreen) {
    // TODO: Show as side panel
    setState(() => _showInfoPanel = true);
  } else {
    // Show as modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatInfoPanel(
        chat: widget.chat,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}

// Update ChatHeader onInfoPressed callback
ChatHeader(
  chat: widget.chat,
  onInfoPressed: _showChatInfo, // Kết nối với callback
)
```

---

## Commands

### 1. Code Generation
```bash
# Generate Freezed, Injectable, JSON
dart run build_runner build --delete-conflicting-outputs

# Generate localization
flutter gen-l10n
```

### 2. Analysis
```bash
flutter analyze
```

### 3. Testing
```bash
flutter test
```

---

## Checklist Cuối Cùng

### Design System Compliance
- [ ] Tất cả text sử dụng `AppText` với `context.l10n`
- [ ] Tất cả buttons sử dụng `AppButton`, `AppIconButton`
- [ ] Tất cả inputs sử dụng `AppTextField`, `AppSwitch`, etc.
- [ ] Tất cả lists sử dụng `AppListView`, `AppGridView`
- [ ] Tất cả colors sử dụng `AppColors.*DarkMode`
- [ ] Tất cả dimensions sử dụng `AppDimens.*`
- [ ] Không có hardcoded strings

### Clean Architecture Compliance
- [ ] BLoC extends `BaseBloc<Event, State>`
- [ ] State extends `BaseState` với `@freezed`
- [ ] Widgets extend `BaseStatefulWidget` hoặc `BaseStatelessWidget`
- [ ] Repository trả về `Either<Failure, T>`
- [ ] Domain layer không import Flutter packages
- [ ] Presentation không import Data models
- [ ] Sử dụng Logger, không dùng `print()`
- [ ] Null-safe code, không dùng `!` operator

### Localization
- [ ] Tất cả strings có trong `app_en.arb` và `app_vi.arb`
- [ ] Đã chạy `flutter gen-l10n`

### Dependency Injection
- [ ] Repositories có `@LazySingleton(as: IInterface)`
- [ ] UseCases có `@injectable`
- [ ] BLoC có `@injectable`
- [ ] DataSources có `@LazySingleton(as: IInterface)`

---

**Prepared by**: Claude Opus 4.5
**Date**: 2026-02-25
**Status**: READY FOR IMPLEMENTATION
