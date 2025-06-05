import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/auth/data/user_repository.dart';
import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';

class UserViewModel extends Notifier<UserEntity?> {
  @override
  UserEntity? build() {
    getById(FirebaseAuth.instance.currentUser?.uid);
    return null;
  }

  /// 상태에 User정보 추가
  Future<bool> insert({
    required id,
    required nickname,
    required profileImageUrl,
  }) async {
    final result = await UserRepository().insert(
      id: id,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
    );

    if (result) {
      state = UserEntity(
        id: id,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        chatRoomId: '',
      );

      return true;
    }

    return false;
  }

  /// 해당 User의 정보를 가져옴
  Future<UserEntity?> getById(String? id) async {
    final user = await UserRepository().getById(id);
    state = user;

    return user;
  }
}

final userViewModelProvider = NotifierProvider<UserViewModel, UserEntity?>(() {
  return UserViewModel();
});
