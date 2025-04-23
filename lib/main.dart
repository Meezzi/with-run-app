import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';

void main() async {
  // main함수에 async 사용할 때, 시스템 설정을 위해
  // runApp보다 먼저 호출
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 방향만 허용
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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
