import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:with_run_app/firebase_options.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';

void main() async {
  // main함수에 async awati을 사용해 비동기 함수를
  // 호출하면, 시스템 설정을 위해 runApp보다 먼저 호출
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 방향만 허용
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(highlightColor: Color(0xff2196F3)),
      home: LoginPage(),
    );
  }
}
