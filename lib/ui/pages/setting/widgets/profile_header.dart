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

    final profileImageUrl = user?.profileImageUrl ?? firebaseUser?.photoURL;

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blue[100],
            backgroundImage:
                profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
          ),
          const SizedBox(height: 8),
          Text(
            user?.nickname ?? "닉네임 없음",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            firebaseUser?.displayName ?? "이름 없음",
            style: TextStyle(fontSize: 16, fontWeight:  FontWeight.bold),
          ),
          Text(
            firebaseUser?.email ?? "이메일 없음",
            style: TextStyle(fontSize: 14, fontWeight:  FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
