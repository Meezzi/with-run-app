import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/features/chat/data/dtos/chat_room_dto.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/models/chat_room_model.dart';
import 'package:with_run_app/features/auth/data/user.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';
import 'package:with_run_app/features/chat/domain/repositories/chat_room_repository.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> create(ChatRoom chatRoom) async {
    final result = await _firestore
        .collection('chatRooms')
        .add(ChatRoomDto.fromEntity(chatRoom).toMap())
        .then((documentSnapshot) {
          print("Added Data with ID: ${documentSnapshot.id}");
          // addParticipant(chatRoom.creator, documentSnapshot.id);
          return documentSnapshot.id;
        });
    return result;
  }

  @override
  Future<ChatRoomModel> get(String id) async {
    final doc = await _firestore.collection('chatRooms').doc(id).get();

    if (!doc.exists) {
      throw Exception('ChatRoom not found');
    }

    // 서브 컬렉션 participants 불러오기
    final participantsSnapshot =
        await _firestore
            .collection('chatRooms')
            .doc(id)
            .collection('participants')
            .get();

    final participants =
        participantsSnapshot.docs.map((e) {
          print('${e.id} : ${e.data()['nickName']}');
          final user = User.fromJson(e.data());
          user.uid = e.id;
          return user;
        }).toList();

    return ChatRoomModel.fromFirestore(doc, participants);
  }

  @override
  Future<void> addParticipant(User user, String chatRoomId) async {
    _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('participants')
        .doc(user.uid)
        .set({
          'nickname': user.nickname,
          'profileImageUrl': user.profileImageUrl,
        });
  }
}
