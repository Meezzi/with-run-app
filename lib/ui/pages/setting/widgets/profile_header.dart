import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/setting/provider/firebase_user_provider.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userViewModelProvider);
    final firebaseUser = ref.watch(firebaseUserProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final profileImageUrl = user?.profileImageUrl ?? firebaseUser?.photoURL;
    final nickname = user?.nickname ?? "닉네임 없음";
    final name = firebaseUser?.displayName ?? "이름 없음";
    final email = firebaseUser?.email ?? "이메일 없음";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 프로필 이미지
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              border: Border.all(
                color: isDarkMode ? Colors.blueAccent : Colors.blue,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.2 * 255).round()), // 0.2 투명도
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              image:
                  profileImageUrl != null
                      ? DecorationImage(
                        image: NetworkImage(profileImageUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                profileImageUrl == null
                    ? Icon(
                      Icons.person,
                      size: 60,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[400],
                    )
                    : null,
          ),

          const SizedBox(height: 16),

          // 닉네임
          Text(
            nickname,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          // 이름
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[300] : Colors.black54,
            ),
          ),

          const SizedBox(height: 4),

          // 이메일
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}
