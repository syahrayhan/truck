import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Data Sources
import 'data/datasources/datasources.dart';

// Repositories
import 'data/repositories/repositories.dart';
import 'domain/repositories/repositories.dart';

// Use Cases
import 'domain/usecases/usecases.dart';

// BLoCs
import 'presentation/bloc/bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init(String haulerId) async {
  // ==================== BLoCs ====================
  sl.registerFactory<HaulerBloc>(
    () => HaulerBloc(
      haulerId: haulerId,
      getOrCreateHauler: sl(),
      updateHaulerLocation: sl(),
      updateBodyUp: sl(),
      saveHaulerEvent: sl(),
      updateHauler: sl(),
      startCycle: sl(),
      completeCycle: sl(),
      updateCycle: sl(),
      haulerRepository: sl(), // For streams only
      loaderRepository: sl(), // For streams only
      locationRepository: sl(), // Infrastructure
      connectivityRepository: sl(), // Infrastructure
    ),
  );

  sl.registerFactory<SimulationBloc>(
    () => SimulationBloc(haulerBloc: sl()),
  );

  // ==================== Use Cases ====================
  sl.registerLazySingleton(() => GetOrCreateHauler(sl()));
  sl.registerLazySingleton(() => UpdateHaulerLocation(sl()));
  sl.registerLazySingleton(() => UpdateBodyUp(sl()));
  sl.registerLazySingleton(() => SaveHaulerEvent(sl()));
  sl.registerLazySingleton(() => UpdateHauler(sl()));
  sl.registerLazySingleton(() => StartCycle(sl()));
  sl.registerLazySingleton(() => CompleteCycle(sl()));
  sl.registerLazySingleton(() => UpdateCycle(sl()));

  // ==================== Repositories ====================
  sl.registerLazySingleton<HaulerRepository>(
    () => HaulerRepositoryImpl(
      remoteDataSource: sl(),
      offlineQueue: sl(),
      connectivityRepository: sl(),
    ),
  );

  sl.registerLazySingleton<CycleRepository>(
    () => CycleRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<LoaderRepository>(
    () => LoaderRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(),
  );

  sl.registerLazySingleton<ConnectivityRepository>(
    () => ConnectivityRepositoryImpl(
      offlineQueue: sl(),
      firestoreDataSource: sl(),
    ),
  );

  // ==================== Data Sources ====================
  sl.registerLazySingleton<FirestoreDataSource>(
    () => FirestoreDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<OfflineQueueDataSource>(
    () => OfflineQueueDataSourceImpl(),
  );

  // ==================== External ====================
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
}

/// Reset all dependencies (useful for testing)
Future<void> reset() async {
  await sl.reset();
}


