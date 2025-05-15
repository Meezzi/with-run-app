import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/setting/widgets/profile_header.dart';
import 'package:with_run_app/ui/pages/setting/widgets/setting_body_container.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.blue[900] : Colors.blue[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Column(
        children: const [
          Flexible(flex: 3, child: ProfileHeader()),
          Flexible(flex: 6, child: SettingBodyContainer()),
        ],
      ),
    );
  }
}
