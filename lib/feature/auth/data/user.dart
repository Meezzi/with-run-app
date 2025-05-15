class User {
  String? uid;
  String? nickname;
  String? profileImageUrl;

  User({this.uid, this.nickname, this.profileImageUrl});

  User copyWith({String? uid, String? nickname, String? profileImageUrl}) {
    return User(
      uid: uid ?? this.uid,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  // 1. fromJson 네임드 생성자
  User.fromJson(Map<String, dynamic> map)
    : this(
        uid: map['uid'],
        nickname: map['nickname'],
        profileImageUrl: map['profileImageUrl'],
      );

  // 2. toJson 메서드
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
    };
  }
}
