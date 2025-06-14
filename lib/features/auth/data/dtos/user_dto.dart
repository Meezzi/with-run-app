import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';

class UserDto {
  String id;
  String nickname;
  String profileImageUrl;
  String chatRoomId;

  UserDto({
    required this.id,
    required this.nickname,
    required this.profileImageUrl,
    required this.chatRoomId,
  });

  UserDto copyWith({
    String? id,
    String? nickname,
    String? profileImageUrl,
    String? chatRoomId,
  }) {
    return UserDto(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  // 1. fromJson 네임드 생성자
  UserDto.fromJson(Map<String, dynamic> map)
    : this(
        id: map['id'],
        nickname: map['nickname'],
        profileImageUrl: map['profileImageUrl'],
        chatRoomId: map['chatRoomId'],
      );

  // 2. toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'chatRoomId': chatRoomId,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
      chatRoomId : '',
    );
  }

  factory UserDto.fromEntity(UserEntity entity) {
    return UserDto(
      id: entity.id,
      nickname: entity.nickname,
      profileImageUrl: entity.profileImageUrl,
      chatRoomId: entity.chatRoomId,
    );
  }
}
