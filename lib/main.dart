import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart' as provider;
import 'package:with_run_app/firebase_options.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';

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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      child: provider.ChangeNotifierProvider(
        create: (context) => AppThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('✅firebaseAuth - ${FirebaseAuth.instance.currentUser}');
    return provider.Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          // theme: themeProvider.lightTheme.copyWith(
          //   highlightColor: const Color(0xff2196F3),
          // ),
          // darkTheme: themeProvider.darkTheme.copyWith(
          //   highlightColor: const Color(0xff2196F3),
          // ),
          // themeMode: themeProvider.themeMode,
          home:
              FirebaseAuth.instance.currentUser != null
                  ? MapPage()
                  : LoginPage(),
        );
      },
    );
  }
}
