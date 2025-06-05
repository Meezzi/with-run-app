class UserDto {
  String uid;
  String nickname;
  String profileImageUrl;
  String chatRoomId;

  UserDto({
    required this.uid,
    required this.nickname,
    required this.profileImageUrl,
    required this.chatRoomId,
  });

  UserDto copyWith({
    String? uid,
    String? nickname,
    String? profileImageUrl,
    String? chatRoomId,
  }) {
    return UserDto(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      chatRoomId: chatRoomId ?? this.chatRoomId,
    );
  }

  // 1. fromJson 네임드 생성자
  UserDto.fromJson(Map<String, dynamic> map)
    : this(
        uid: map['uid'],
        nickname: map['nickname'],
        profileImageUrl: map['profileImageUrl'],
        chatRoomId: map['chatRoomId'],
      );

  // 2. toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
      'chatRoomId': chatRoomId,
    };
  }
}
