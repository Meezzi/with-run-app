import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:with_run_app/firebase_options.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: ".env");

  // iOS에서 GoogleMaps 초기화
  if (Platform.isIOS) {
    final String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey != null) {
      final methodChannel = MethodChannel('com.example.with_run_app/maps');
      try {
        await methodChannel.invokeMethod('initGoogleMaps', {'apiKey': apiKey});
      } catch (e) {
        debugPrint('GoogleMaps 초기화 오류: $e');
      }
    } else {
      debugPrint('Google Maps API Key가 .env 파일에 없습니다');
    }
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('ko_KR', null); // 'ko_KR' 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeProvider);
    final userState = ref.watch(userViewModelProvider);

  return MaterialApp(
    
      theme: themeState.lightTheme,
      darkTheme: themeState.darkTheme,
      themeMode: themeState.themeMode,
      home: userState != null ? MapPage() : LoginPage(),
    );
  }
}
