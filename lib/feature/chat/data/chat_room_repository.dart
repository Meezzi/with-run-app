

import 'package:with_run_app/feature/chat/data/chat_room_model.dart';
import 'package:with_run_app/feature/auth/data/user.dart';

abstract interface class ChatRoomRepository {
  Future<String> create(ChatRoomModel chatRoom, User creator);

  Future<ChatRoomModel> get(String id);

  Future<void> addParticipant(User user, String chatRoomId);
}