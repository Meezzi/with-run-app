import 'package:flutter/material.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';

class SettingActionBox extends StatelessWidget {
  const SettingActionBox({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black : Colors.white,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("로그아웃"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await signOutGoogle();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return LoginPage();
          },
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')));
    }
  }
}
