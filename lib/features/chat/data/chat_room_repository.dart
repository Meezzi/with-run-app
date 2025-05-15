

import 'package:with_run_app/features/chat/data/chat_room_model.dart';
import 'package:with_run_app/features/auth/data/user.dart';

abstract interface class ChatRoomRepository {
  Future<String> create(ChatRoomModel chatRoom, User creator);

  Future<ChatRoomModel> get(String id);

  Future<void> addParticipant(User user, String chatRoomId);
}