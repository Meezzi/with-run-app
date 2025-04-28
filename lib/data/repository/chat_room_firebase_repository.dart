
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> create(ChatRoomModel chatRoom, User creator) async{
    await _firestore.collection('chatRooms').add(chatRoom.toMap()).then((documentSnapshot){
      print("Added Data with ID: ${documentSnapshot.id}");
      documentSnapshot.collection('participants').doc(creator.uid).set({
        'nickName' : creator.nickname,
        'profileImageUrl' : creator.profileImageUrl,
      });
    });
  }
  
  @override
  Future<ChatRoomModel> get(String id) async{
    final result = await _firestore.collection('chatRooms').doc(id).get();
    return ChatRoomModel.fromFirestore(result);
  }

}
