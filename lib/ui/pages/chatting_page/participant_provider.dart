import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final participantProvider = FutureProvider.family<Map<String, Participant>, String>((ref, chatRoomId) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('chatRooms')
      .doc(chatRoomId)
      .collection('participants')
      .get();

  final participants = {
    for (var doc in snapshot.docs)
      doc.id: Participant.fromMap(doc.data())
  };
  
  return participants;
});

class Participant {
  final String nickname;
  final String profileImageUrl;

  Participant({
    required this.nickname,
    required this.profileImageUrl,
  });

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      nickname: map['nickname'] ?? '알 수 없음',
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'profileImageUrl': profileImageUrl,
    };
  }
}