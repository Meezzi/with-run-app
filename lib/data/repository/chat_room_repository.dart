
import 'package:with_run_app/models/chat_room.dart';

abstract interface class ChatRoomRepository {
  Future<void> create(ChatRoom chatRoom);

  Future<void> get(String id);
}