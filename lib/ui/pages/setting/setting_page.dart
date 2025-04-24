import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/setting/widgets/profile_header.dart';
import 'package:with_run_app/ui/pages/setting/widgets/setting_body_container.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: const [
          ProfileHeader(),
          SettingBodyContainer(),
        ],
      ),
    );
  }
}
