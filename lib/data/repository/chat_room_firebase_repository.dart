
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:with_run_app/data/model/user.dart';
=======
>>>>>>> b0eb9b75791ccee419b7d06dfb11b6ed8e525f4c
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:with_run_app/models/chat_room.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> create(ChatRoom chatRoom, User user) async{
    await _firestore.collection('chatRooms').add(chatRoom.toMap()).then((documentSnapshot) {
      print("Added Data with ID: ${documentSnapshot.id}");
      documentSnapshot.collection('participants').doc(user.uid).set({
        'nickName' : user.nickname,
        'profileImageUrl' : user.profileImageUrl,
      });
    });
  }
  
  @override
  Future<ChatRoom> get(String id) async{
    final result = await _firestore.collection('chatRooms').doc(id).get();
    return ChatRoom.fromFirestore(result);
  }

  @override
  Future<void> addParticipant(User user, String chatRoomId) async {
    _firestore.collection('chatRooms')
    .doc(chatRoomId)
    .collection('participants')
    .doc(user.uid)
    .set({
      'nickName' : user.nickname,
      'profileImageUrl' : user.profileImageUrl,
    });
  }

  

}
