import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/auth/data/dtos/user_dto.dart';
import 'package:with_run_app/features/auth/data/user_repository.dart';

class UserViewModel extends Notifier<UserDto?> {
  @override
  UserDto? build() {
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
      state = UserDto(
        uid: uid,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );

      return true;
    }

    return false;
  }

  /// 해당 User의 정보를 가져옴
  Future<UserDto?> getById(String? uid) async {
    UserDto? user = await UserRepository().getById(uid);
    state = user;

    return user;
  }
}

final userViewModelProvider = NotifierProvider<UserViewModel, UserDto?>(() {
  return UserViewModel();
});
