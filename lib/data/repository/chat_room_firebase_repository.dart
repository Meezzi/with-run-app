import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/feature/chat/data/chat_room_model.dart';
import 'package:with_run_app/feature/auth/data/user.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> create(ChatRoomModel chatRoom, User creator) async {
    final result = await _firestore
        .collection('chatRooms')
        .add(chatRoom.toMap())
        .then((documentSnapshot) {
          print("Added Data with ID: ${documentSnapshot.id}");
          addParticipant(creator, documentSnapshot.id);
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
