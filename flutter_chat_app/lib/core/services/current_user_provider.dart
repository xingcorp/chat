import 'dart:async';

import 'package:flutter_chat_app/core/network/auth/token_repository.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/models/user_model.dart';
import 'package:flutter_chat_app/shared/domain/entities/user.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class CurrentUserProvider {
  Stream<User?> get userStream;

  User? get currentUser;

  String get currentUserId;

  Future<void> initialize();

  Future<User?> refresh();

  Future<void> setCurrentUser(User user);

  Future<void> clear();
}

@LazySingleton(as: CurrentUserProvider)
class CurrentUserProviderImpl implements CurrentUserProvider {
  final UserLocalDataSource _userLocalDataSource;
  final TokenRepository _tokenRepository;

  final BehaviorSubject<User?> _userController = BehaviorSubject<User?>();
  StreamSubscription<AuthTokens?>? _tokensSubscription;

  bool _initialized = false;

  CurrentUserProviderImpl({
    required UserLocalDataSource userLocalDataSource,
    required TokenRepository tokenRepository,
  })  : _userLocalDataSource = userLocalDataSource,
        _tokenRepository = tokenRepository;

  @override
  Stream<User?> get userStream => _userController.stream;

  @override
  User? get currentUser => _userController.valueOrNull;

  @override
  String get currentUserId => currentUser?.id ?? '';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    await _tokenRepository.initialize();

    final initialUser = await _readLocalUser();
    _userController.add(initialUser);

    _tokensSubscription = _tokenRepository.tokensStream.listen((tokens) async {
      if (tokens == null || tokens.isEmpty) {
        await _userLocalDataSource.clearCurrentUser();
        _userController.add(null);
        return;
      }

      final localUser = await _readLocalUser();
      _userController.add(localUser);
    });

    _initialized = true;
  }

  @override
  Future<User?> refresh() async {
    if (!_initialized) {
      await initialize();
    }

    final localUser = await _readLocalUser();
    _userController.add(localUser);
    return localUser;
  }

  @override
  Future<void> setCurrentUser(User user) async {
    if (!_initialized) {
      await initialize();
    }

    final model = UserModel.fromDomain(user);
    await _userLocalDataSource.saveCurrentUser(model);
    _userController.add(user);
  }

  @override
  Future<void> clear() async {
    if (!_initialized) {
      await initialize();
    }

    await _userLocalDataSource.clearCurrentUser();
    _userController.add(null);
  }

  Future<User?> _readLocalUser() async {
    final model = await _userLocalDataSource.getCurrentUser();
    return model?.toDomain();
  }

  Future<void> dispose() async {
    await _tokensSubscription?.cancel();
    await _userController.close();
  }
}
