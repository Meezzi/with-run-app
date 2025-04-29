import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/user_repository.dart';

class UserViewModel extends Notifier<User?> {
  @override
  User? build() {
    getById(FirebaseAuth.instance.currentUser?.uid);
    return null;
  }

  /// 상태에 User정보 추가
  Future<bool> insert({
    required uid,
    required nickname,
    required profileImageUrl,
  }) async {
    final result = await UserRepository().insert(
      uid: uid,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
    );

    if (result) {
      state = User(
        uid: uid,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );

      return true;
    }

    return false;
  }

  /// 해당 User의 정보를 가져옴
  Future<User?> getById(String? uid) async {
    User? user = await UserRepository().getById(uid);
    state = user;

    return user;
  }
}

final userViewModelProvider = NotifierProvider<UserViewModel, User?>(() {
  return UserViewModel();
});
