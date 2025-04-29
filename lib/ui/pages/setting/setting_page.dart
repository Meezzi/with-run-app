import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
import 'package:with_run_app/ui/pages/login/login_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/setting/widgets/profile_header.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appThemeProvider);
    final isDarkMode = themeState.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('설정'),
      ),
      body: Column(
        children: [
          // 프로필 영역
          const Flexible(flex: 3, child: ProfileHeader()),

          // 설정 메뉴 영역
          Flexible(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(48),
                  topRight: Radius.circular(48),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ListView(
                  children: [
                    // 다크 모드 설정
                    _buildSettingTile(
                      context,
                      icon: Icons.dark_mode,
                      title: '다크 모드',
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(appThemeProvider.notifier).toggleTheme();
                        },
                        activeColor: Colors.blue,
                      ),
                    ),

                    const Divider(height: 1),

                    // 로그아웃 버튼
                    _buildSettingTile(
                      context,
                      icon: Icons.logout,
                      title: '로그아웃',
                      iconColor: Colors.red,
                      textColor: Colors.red,
                      onTap: () => _showLogoutConfirmDialog(context),
                    ),

                    const Divider(height: 1),

                    // 버전 정보
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          '버전 1.0.0',
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => _logout(context),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('로그아웃'),
              ),
            ],
          ),
    );
  }

  void _logout(BuildContext context) async {
    try {
      await signOutGoogle();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그아웃 중 오류가 발생했습니다.')));
      }
    }
  }
}
