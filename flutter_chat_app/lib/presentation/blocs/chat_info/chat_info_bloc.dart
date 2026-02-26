import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_chat_app/core/utils/logger.dart';
import 'package:flutter_chat_app/presentation/blocs/base/base_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_event.dart';
import 'package:flutter_chat_app/presentation/blocs/chat_info/chat_info_state.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/get_shared_media_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/get_notification_settings_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/update_notification_settings_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/block_user_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/unblock_user_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat_info/report_chat_usecase.dart';
import 'package:flutter_chat_app/domain/repositories/i_chat_info_repository.dart';

/// BLoC cho Chat Info operations
/// TUÂN THỦ: PHẢI extend BaseBloc, KHÔNG extend Bloc trực tiếp
@injectable
class ChatInfoBloc extends BaseBloc<ChatInfoEvent, ChatInfoState> {
  final GetSharedMediaUseCase _getSharedMediaUseCase;
  final GetNotificationSettingsUseCase _getNotificationSettingsUseCase;
  final UpdateNotificationSettingsUseCase _updateNotificationSettingsUseCase;
  final BlockUserUseCase _blockUserUseCase;
  final UnblockUserUseCase _unblockUserUseCase;
  final ReportChatUseCase _reportChatUseCase;
  final IChatInfoRepository _repository;
  final AppLogger _logger;

  ChatInfoBloc({
    required GetSharedMediaUseCase getSharedMediaUseCase,
    required GetNotificationSettingsUseCase getNotificationSettingsUseCase,
    required UpdateNotificationSettingsUseCase updateNotificationSettingsUseCase,
    required BlockUserUseCase blockUserUseCase,
    required UnblockUserUseCase unblockUserUseCase,
    required ReportChatUseCase reportChatUseCase,
    required IChatInfoRepository repository,
    required AppLogger logger,
  })  : _getSharedMediaUseCase = getSharedMediaUseCase,
        _getNotificationSettingsUseCase = getNotificationSettingsUseCase,
        _updateNotificationSettingsUseCase = updateNotificationSettingsUseCase,
        _blockUserUseCase = blockUserUseCase,
        _unblockUserUseCase = unblockUserUseCase,
        _reportChatUseCase = reportChatUseCase,
        _repository = repository,
        _logger = logger,
        super(const ChatInfoInitial()) {
    // Register event handlers
    on<ChatInfoLoadSharedMedia>(_onLoadSharedMedia);
    on<ChatInfoLoadNotificationSettings>(_onLoadNotificationSettings);
    on<ChatInfoUpdateNotificationSettings>(_onUpdateNotificationSettings);
    on<ChatInfoMuteNotifications>(_onMuteNotifications);
    on<ChatInfoUnmuteNotifications>(_onUnmuteNotifications);
    on<ChatInfoBlockUser>(_onBlockUser);
    on<ChatInfoUnblockUser>(_onUnblockUser);
    on<ChatInfoCheckUserBlocked>(_onCheckUserBlocked);
    on<ChatInfoReportChat>(_onReportChat);
  }

  /// Handler: Load shared media
  Future<void> _onLoadSharedMedia(
    ChatInfoLoadSharedMedia event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Loading media...'));

    _logger.d('Loading shared media: chatId=${event.chatId}, type=${event.type.name}');

    final result = await _getSharedMediaUseCase(
      chatId: event.chatId,
      type: event.type,
      limit: event.limit,
      offset: event.offset,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to load shared media', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (media) {
        _logger.i('Loaded ${media.length} media items');
        emit(ChatInfoSharedMediaLoaded(
          media: media,
          type: event.type,
        ));
      },
    );
  }

  /// Handler: Load notification settings
  Future<void> _onLoadNotificationSettings(
    ChatInfoLoadNotificationSettings event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Loading notification settings...'));

    _logger.d('Loading notification settings: chatId=${event.chatId}');

    final result = await _getNotificationSettingsUseCase(chatId: event.chatId);

    result.fold(
      (failure) {
        _logger.e('Failed to load notification settings', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (settings) {
        _logger.i('Loaded notification settings: isMuted=${settings.isMuted}');
        emit(ChatInfoNotificationSettingsLoaded(settings: settings));
      },
    );
  }

  /// Handler: Update notification settings
  Future<void> _onUpdateNotificationSettings(
    ChatInfoUpdateNotificationSettings event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Updating settings...'));

    _logger.d('Updating notification settings: chatId=${event.settings.chatId}');

    final result = await _updateNotificationSettingsUseCase(
      chatId: event.settings.chatId,
      settings: event.settings,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to update notification settings', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (settings) {
        _logger.i('Updated notification settings successfully');
        emit(ChatInfoNotificationSettingsUpdated(settings: settings));
      },
    );
  }

  /// Handler: Mute notifications
  Future<void> _onMuteNotifications(
    ChatInfoMuteNotifications event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Muting notifications...'));

    _logger.d('Muting notifications: chatId=${event.chatId}, duration=${event.duration.name}');

    // Get current settings first
    final currentResult = await _getNotificationSettingsUseCase(
      chatId: event.chatId,
    );

    await currentResult.fold(
      (failure) async {
        _logger.e('Failed to get current settings', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (currentSettings) async {
        // Apply mute
        final updatedSettings = currentSettings.muteFor(event.duration);

        final result = await _updateNotificationSettingsUseCase(
          chatId: event.chatId,
          settings: updatedSettings,
        );

        result.fold(
          (failure) {
            _logger.e('Failed to mute notifications', error: failure);
            emit(ChatInfoError(message: failure.message, error: failure));
          },
          (settings) {
            _logger.i('Muted notifications successfully');
            emit(ChatInfoNotificationSettingsUpdated(settings: settings));
          },
        );
      },
    );
  }

  /// Handler: Unmute notifications
  Future<void> _onUnmuteNotifications(
    ChatInfoUnmuteNotifications event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Unmuting notifications...'));

    _logger.d('Unmuting notifications: chatId=${event.chatId}');

    final currentResult = await _getNotificationSettingsUseCase(
      chatId: event.chatId,
    );

    await currentResult.fold(
      (failure) async {
        _logger.e('Failed to get current settings', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (currentSettings) async {
        final updatedSettings = currentSettings.unmute();

        final result = await _updateNotificationSettingsUseCase(
          chatId: event.chatId,
          settings: updatedSettings,
        );

        result.fold(
          (failure) {
            _logger.e('Failed to unmute notifications', error: failure);
            emit(ChatInfoError(message: failure.message, error: failure));
          },
          (settings) {
            _logger.i('Unmuted notifications successfully');
            emit(ChatInfoNotificationSettingsUpdated(settings: settings));
          },
        );
      },
    );
  }

  /// Handler: Block user
  Future<void> _onBlockUser(
    ChatInfoBlockUser event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Blocking user...'));

    _logger.d('Blocking user: userId=${event.userId}');

    final result = await _blockUserUseCase(userId: event.userId);

    result.fold(
      (failure) {
        _logger.e('Failed to block user', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (_) {
        _logger.i('Blocked user successfully: userId=${event.userId}');
        emit(ChatInfoUserBlocked(userId: event.userId));
      },
    );
  }

  /// Handler: Unblock user
  Future<void> _onUnblockUser(
    ChatInfoUnblockUser event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Unblocking user...'));

    _logger.d('Unblocking user: userId=${event.userId}');

    final result = await _unblockUserUseCase(userId: event.userId);

    result.fold(
      (failure) {
        _logger.e('Failed to unblock user', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (_) {
        _logger.i('Unblocked user successfully: userId=${event.userId}');
        emit(ChatInfoUserUnblocked(userId: event.userId));
      },
    );
  }

  /// Handler: Check if user is blocked
  Future<void> _onCheckUserBlocked(
    ChatInfoCheckUserBlocked event,
    Emitter<ChatInfoState> emit,
  ) async {
    _logger.d('Checking if user is blocked: userId=${event.userId}');

    final result = await _repository.isUserBlocked(userId: event.userId);

    result.fold(
      (failure) {
        _logger.e('Failed to check block status', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (isBlocked) {
        _logger.d('User block status checked: userId=${event.userId}, isBlocked=$isBlocked');
        emit(ChatInfoUserBlockStatusChecked(
          userId: event.userId,
          isBlocked: isBlocked,
        ));
      },
    );
  }

  /// Handler: Report chat
  Future<void> _onReportChat(
    ChatInfoReportChat event,
    Emitter<ChatInfoState> emit,
  ) async {
    emit(const ChatInfoLoading(message: 'Reporting chat...'));

    _logger.d('Reporting chat: chatId=${event.chatId}, reason=${event.reason}');

    final result = await _reportChatUseCase(
      chatId: event.chatId,
      reason: event.reason,
    );

    result.fold(
      (failure) {
        _logger.e('Failed to report chat', error: failure);
        emit(ChatInfoError(message: failure.message, error: failure));
      },
      (_) {
        _logger.i('Reported chat successfully: chatId=${event.chatId}');
        emit(const ChatInfoChatReported());
      },
    );
  }

  @override
  Future<void> close() {
    _logger.d('ChatInfoBloc closed');
    return super.close();
  }
}
