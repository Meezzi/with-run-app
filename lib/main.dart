import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider, Consumer;
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:provider/provider.dart';
import 'package:with_run_app/firebase_options.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 
  await dotenv.load(fileName: ".env");

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ProviderScope(
      child: ChangeNotifierProvider(
        create: (context) => AppThemeProvider(),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: themeProvider.lightTheme.copyWith(
            highlightColor: const Color(0xff2196F3),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            highlightColor: const Color(0xff2196F3),
          ),
          themeMode: themeProvider.themeMode,
          home:  LoginPage(),
        );
      },
    );
  }
}