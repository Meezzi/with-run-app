import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:with_run_app/features/auth/presentation/login/login_page.dart';
import 'package:with_run_app/features/auth/user_view_model.dart';
import 'package:with_run_app/features/map/presentation/map/map_page.dart';
import 'package:with_run_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: ".env");

  // 앱 방향 전환
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 네이버 맵 초기화
  await FlutterNaverMap().init(
    clientId: dotenv.env['NAVER_MAPS_CLIENT_ID'],
    onAuthFailed:
        (ex) => switch (ex) {
          NQuotaExceededException(:final message) => debugPrint(
            "사용량 초과 (message: $message)",
          ),
          NUnauthorizedClientException() ||
          NClientUnspecifiedException() ||
          NAnotherAuthFailedException() => debugPrint("인증 실패: $ex"),
        },
  );

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
    final userState = ref.watch(userViewModelProvider);

    return MaterialApp(home: userState != null ? MapPage() : LoginPage());
  }
}
