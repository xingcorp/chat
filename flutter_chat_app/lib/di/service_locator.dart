import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/core/network/graphql_client.dart';
import 'package:flutter_chat_app/core/network/network_info.dart';
import 'package:flutter_chat_app/core/storage/local_storage.dart';
import 'package:flutter_chat_app/core/storage/secure_storage.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/chat/chat_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/message/message_remote_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_local_datasource.dart';
import 'package:flutter_chat_app/data/datasources/user/user_remote_datasource.dart';
import 'package:flutter_chat_app/data/repositories/auth_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/chat_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/message_repository_impl.dart';
import 'package:flutter_chat_app/data/repositories/user_repository_impl.dart';
import 'package:flutter_chat_app/domain/repositories/auth_repository.dart';
import 'package:flutter_chat_app/domain/repositories/chat_repository.dart';
import 'package:flutter_chat_app/domain/repositories/message_repository.dart';
import 'package:flutter_chat_app/domain/repositories/user_repository.dart';
import 'package:flutter_chat_app/domain/usecases/auth/check_auth_status_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/login_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/logout_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/auth/register_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/create_group_chat_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_chat_details_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/chat/get_user_chats_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/get_chat_messages_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/message/send_message_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/get_user_contacts_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/get_user_profile_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/search_users_usecase.dart';
import 'package:flutter_chat_app/domain/usecases/user/update_user_profile_usecase.dart';
import 'package:flutter_chat_app/presentation/blocs/app/app_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/chat/chat_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/message/message_bloc.dart';
import 'package:flutter_chat_app/presentation/blocs/user/user_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

final getIt = GetIt.instance;

/// Configure dependency injection
Future<void> configureDependencies() async {
  // External Libraries
  getIt.registerSingleton<Logger>(Logger());
  
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  
  // GraphQL Client
  final clientValueNotifier = ValueNotifier<GraphQLClient>(
    GraphQLClient(
      cache: GraphQLCache(),
      link: HttpLink('https://example.com/graphql'), // Default, will be replaced
    ),
  );
  
  getIt.registerSingleton<ValueNotifier<GraphQLClient>>(clientValueNotifier);
  
  // Core
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(getIt()));
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorageImpl(getIt()));
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
  
  // GraphQL Client
  getIt.registerLazySingletonAsync<GraphQLClient>(() async {
    final secureStorage = getIt<SecureStorage>();
    final token = await secureStorage.getString('auth_token');
    return GraphQLClientWrapperImpl.createClient(
      token: token,
      clientNotifier: getIt<ValueNotifier<GraphQLClient>>(),
    );
  });
  
  getIt.registerLazySingleton<GraphQLClientWrapper>(
    () => GraphQLClientWrapperImpl(
      getIt.getAsync<GraphQLClient>(),
      getIt<NetworkInfo>(),
    ),
  );
  
  getIt.registerLazySingleton<io.Socket>(() {
    return io.io('wss://socket.example.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
  });
  
  // Data Sources
  getIt.registerLazySingleton<UserLocalDataSource>(() => UserLocalDataSourceImpl(getIt()));
  getIt.registerLazySingleton<UserRemoteDataSource>(() => UserRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<ChatLocalDataSource>(() => ChatLocalDataSourceImpl(getIt()));
  getIt.registerLazySingleton<ChatRemoteDataSource>(() => ChatRemoteDataSourceImpl(getIt(), getIt()));
  getIt.registerLazySingleton<MessageLocalDataSource>(() => MessageLocalDataSourceImpl(getIt()));
  getIt.registerLazySingleton<MessageRemoteDataSource>(() => MessageRemoteDataSourceImpl(getIt(), getIt()));
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<MessageRepository>(() => MessageRepositoryImpl(getIt(), getIt(), getIt()));
  
  // Use Cases - Auth
  getIt.registerLazySingleton(() => CheckAuthStatusUseCase(getIt()));
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  
  // Use Cases - User
  getIt.registerLazySingleton(() => GetUserProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateUserProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => GetUserContactsUseCase(getIt()));
  getIt.registerLazySingleton(() => SearchUsersUseCase(getIt()));
  
  // Use Cases - Chat
  getIt.registerLazySingleton(() => GetUserChatsUseCase(getIt()));
  getIt.registerLazySingleton(() => GetChatDetailsUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateGroupChatUseCase(getIt()));
  
  // Use Cases - Message
  getIt.registerLazySingleton(() => GetChatMessagesUseCase(getIt()));
  getIt.registerLazySingleton(() => SendMessageUseCase(getIt()));
  
  // BLoCs
  getIt.registerFactory(() => AppBloc());
  getIt.registerFactory(() => ConnectivityBloc(getIt()));
  getIt.registerFactory(() => AuthBloc(getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactory(() => UserBloc(getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactory(() => ChatBloc(getIt(), getIt(), getIt()));
  getIt.registerFactory(() => MessageBloc(getIt(), getIt()));
} 