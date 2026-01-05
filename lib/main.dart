import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'data/datasources/datasources.dart';
import 'presentation/bloc/bloc.dart';
import 'presentation/pages/pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1A2E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize offline queue
  final offlineQueue = OfflineQueueDataSourceImpl();
  await offlineQueue.initialize();
  
  // Generate a unique hauler ID for this device/session
  // In production, this would come from authentication
  final haulerId = 'HLR-${const Uuid().v4().substring(0, 8)}';
  
  // Initialize dependency injection
  await di.init(haulerId);
  
  runApp(HaulerTruckApp(haulerId: haulerId));
}

class HaulerTruckApp extends StatelessWidget {
  final String haulerId;
  
  const HaulerTruckApp({super.key, required this.haulerId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HaulerBloc>(
          create: (_) => di.sl<HaulerBloc>(),
        ),
        BlocProvider<SimulationBloc>(
          create: (context) => SimulationBloc(
            haulerBloc: context.read<HaulerBloc>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Hauler Truck',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE94560),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F23),
          fontFamily: 'Inter',
        ),
        home: const HomePage(),
      ),
    );
  }
}
