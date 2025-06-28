import 'package:bikerr/features/auth/data/datasource/auth_remote_data_source.dart';
import 'package:bikerr/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bikerr/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/login_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/refesh_token_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/register_usecase.dart';
import 'package:bikerr/features/auth/domain/usecase/verify_email_usecase.dart';
import 'package:bikerr/features/auth/presentation/bloc/auth_bloc.dart';
// Import the concrete data source if needed elsewhere, but repo depends on abstract
// import 'package:bikerr/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:bikerr/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:bikerr/features/chat/domain/repositories/chat_repository.dart';
import 'package:bikerr/features/chat/domain/usecases/get_all_messages_in_chatroom_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/get_older_messages_in_chat_room_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/remove_user_from_chat_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/reply_to_message_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:bikerr/features/chat/domain/usecases/update_last_read_usecase.dart';
// Import the GetChatroomdetailsUsecase
import 'package:bikerr/features/chat/domain/usecases/get_chatroomDetails_usecase.dart';
import 'package:bikerr/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:bikerr/features/conversations/data/datasources/conversation_remote_data_source.dart';
import 'package:bikerr/features/conversations/data/repositories/conversation_repository_impl.dart';
import 'package:bikerr/features/conversations/domain/usecases/fetch_all_user_conversation_usecase.dart';
import 'package:bikerr/features/conversations/domain/usecases/get_all_chat_rooms_usecase.dart';
import 'package:bikerr/features/conversations/domain/usecases/join_new_chat_group_use_case.dart';
import 'package:bikerr/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:bikerr/features/map/data/datasource/traccar_remote_data_source.dart';
import 'package:bikerr/features/map/data/repository/location_repository_impl.dart';
import 'package:bikerr/features/map/data/repository/traccar_repository.impl.dart';
import 'package:bikerr/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:bikerr/features/map/domain/usecases/traccar_use_case.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:bikerr/services/notifications/notification_service.dart';
import 'package:bikerr/utils/network/network_api_services.dart';
import 'package:get_it/get_it.dart';

// Assuming Conversation and Location also have abstract data sources
// import 'package:bikerr/features/conversations/domain/datasources/conversation_data_source.dart';
// import 'package:bikerr/features/auth/domain/datasources/auth_data_source.dart';
// import 'package:bikerr/features/location/domain/datasources/location_data_source.dart';

// Import concrete data sources that implement the abstract ones
import 'package:bikerr/features/chat/data/datasources/chat_remote_data_source.dart';
// import 'package:bikerr/features/conversations/data/datasource/conversation_remote_data_source.dart';
// import 'package:bikerr/features/auth/data/datasource/auth_remote_data_source.dart';
// import 'package:bikerr/features/location/data/datasources/location_remote_data_source.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // services
  // NetworkServicesApi currently creates its own http.Client internally
  sl.registerFactory(() => NetworkServicesApi());
  sl.registerFactory(() => NotificationService());

  // remote data sources

  sl.registerLazySingleton<ChatDataSource>(
    () => ChatRemoteDataSource(),
  ); // Register ChatRemoteDataSource under ChatDataSource
  sl.registerLazySingleton(
    () => AuthRemoteDataSource(),
  ); // Keep as is per user request
  sl.registerLazySingleton(
    () => ConversationRemoteDataSource(),
  );
  sl.registerLazySingleton(
    () => TraccarRemoteDataSource(),
  );

  // repositories
  // Keep dependencies on RemoteDataSources as in your original code
  sl.registerLazySingleton(
    () => AuthRepositoryImpl(authRemoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LocationRepositoryImpl());
  sl.registerLazySingleton(() => TraccarRepositoryImpl(traccarRemoteDataSource: sl()));
  // ChatRepository depends on ChatDataSource (abstract)
  sl.registerLazySingleton(
    () => ChatRepositoryImpl(chatRemoteDataSource: sl()),
  );
  sl.registerLazySingleton(
    () => ConversationRepositoryImpl(conversationRemoteDataSource: sl()),
  );


  //use cases
  // Keep dependencies on RepositoryImpl as in your original code
  sl.registerLazySingleton(() => RegisterUsecase(repositoryImpl: sl()));
  sl.registerLazySingleton(() => VerifyEmailUsecase(repositoryImpl: sl()));
  sl.registerLazySingleton(() => LoginUsecase(authRepositoryImpl: sl()));
  sl.registerLazySingleton(
    () => RemoveUserFromChatUsecase(chatRepositoryImpl: sl()),
  );

  sl.registerLazySingleton(
    () => ForgotPasswordUsecase(authRepositoryImpl: sl()),
  );
  sl.registerLazySingleton(
    () => GetCurrentLocationUsecase(locationRepositoryImpl: sl()),
  );
  sl.registerLazySingleton(() => RefeshTokenUsecase(authRepositoryImpl: sl()));
  // These Chat UseCases already depended on ChatRepository (abstract)
  sl.registerLazySingleton(
    () => GetAllMessagesInChatroomUsecase(chatRepository: sl()),
  );
  sl.registerLazySingleton(
    () => FetchAllUserConversationUseCase(conversationRepositoryImpl: sl()),
  );
  // SendMessageUseCase dependency name and type as in your original code
  sl.registerLazySingleton(() => SendMessageUseCase(repository: sl()));
  sl.registerLazySingleton(
    () => UpdateLastReadUsecase(chatRepositoryImpl: sl()),
  );
  // These Chat UseCases already depended on ChatRepository (abstract)
  sl.registerLazySingleton(
    () => GetOlderMessagesInChatroomUsecase(chatRepository: sl()),
  );
  sl.registerLazySingleton(
    () => ReplyToMessageUsecase(chatRepositoryImpl: sl()),
  );
  // FIX: Add registration for GetChatroomdetailsUsecase
  sl.registerLazySingleton(
    () => GetChatroomdetailsUsecase(chatRepositoryImpl: sl()),
  ); // Depends on ChatRepositoryImpl
  sl.registerLazySingleton(
    () => GetAllChatRoomsUsecase(conversationRepositoryImpl: sl()),
  ); // Depends on ChatRepositoryImpl
  sl.registerLazySingleton(() => JoinNewChatGroupUseCase(conversationRepositoryImpl: sl()));
  sl.registerLazySingleton(() => TraccarUseCase(traccarRepositoryImpl: sl()));
  // Blocs
  sl.registerFactory(
    () => AuthBloc(
      registerUsecase: sl(),
      verifyEmailUsecase: sl(),
      loginUsecase: sl(),
      forgotPasswordUsecase: sl(),
      refreshTokenUsecase: sl(),
    ),
  );
  sl.registerFactory(() => MapBloc(sl()));
  sl.registerFactory(
    () => ChatBloc(
      sl(),
      sl(),
      getAllMessagesInChatroomUsecase: sl(),
      sendMessageUsecase: sl(),
      updateLastReadUsecase: sl(),
      getOlderMessagesInChatroomUsecase: sl(),
      replyToMessageUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ConversationBloc(
      fetchAllUserConversationUsecase: sl(),
      getAllChatRoomsUsecase: sl(), joinNewChatGroupUseCase: sl(),

    ),
  );
}
