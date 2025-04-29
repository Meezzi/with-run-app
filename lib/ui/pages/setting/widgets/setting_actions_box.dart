import 'package:flutter/material.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';

class SettingActionBox extends StatelessWidget {
  const SettingActionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("로그아웃"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // 로그아웃 다이얼로그를 표시하고, 확인 시 로그아웃 처리
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 다이얼로그 닫기
              Navigator.of(dialogContext).pop();
              // 로그아웃 처리
              _performLogout(context);
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  // 실제 로그아웃 수행 메서드
  Future<void> _performLogout(BuildContext context) async {
    try {
      await signOutGoogle();
      
      // 비동기 작업 후 context 사용 전 mounted 체크
      if (!context.mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      // 비동기 작업 후 context 사용 전 mounted 체크
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')),
      );
    }
  }
}