import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';

class UserModel {
  String id;
  String nickname;
  String profileImageUrl;
  String chatRoomId;

  UserModel({
    required this.id,
    required this.nickname,
    required this.profileImageUrl,
    required this.chatRoomId,
  });

  UserModel copyWith({
    String? id,
    String? nickname,
    String? profileImageUrl,
    String? chatRoomId,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
      chatRoomId: '',
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      nickname: entity.nickname,
      profileImageUrl: entity.profileImageUrl,
      chatRoomId: entity.chatRoomId,
    );
  }
}
