
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/models/chat_room.dart';

abstract interface class ChatRoomRepository {
  Future<void> create(ChatRoom chatRoom, User user);

  Future<void> get(String id);

  Future<void> addParticipant(User user, String chatRoomId);
}