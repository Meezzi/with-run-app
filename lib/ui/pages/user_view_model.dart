import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/user_repository.dart';

class UserViewModel extends Notifier<User?> {
  @override
  User? build() {
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
}

final userViewModelProvider = NotifierProvider<UserViewModel, User?>(() {
  return UserViewModel();
});
