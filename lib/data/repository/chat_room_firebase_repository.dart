
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:with_run_app/models/chat_room.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository{

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> create(ChatRoom chatRoom) async{
    await _firestore.collection('chatRooms').add(chatRoom.toMap()).then((documentSnapshot) =>
    print("Added Data with ID: ${documentSnapshot.id}"));;
  }
  
  @override
  Future<ChatRoom> get(String id) async{
    final result = await _firestore.collection('chatRooms').doc(id).get();
    return ChatRoom.fromFirestore(result);
  }

}
