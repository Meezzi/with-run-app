import 'package:flutter/material.dart';
import 'package:with_run_app/features/profile/presentation/setting/widgets/setting_actions_box.dart';

class SettingBodyContainer extends StatelessWidget {
  const SettingBodyContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.32,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(48),
            topRight: Radius.circular(48),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: SettingActionBox(),
            ),
          ],
        ),
      ),
    );
  }
}
