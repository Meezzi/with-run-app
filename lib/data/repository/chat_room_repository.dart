

import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';

abstract interface class ChatRoomRepository {
  Future<String> create(ChatRoomModel chatRoom, User creator);

  Future<ChatRoomModel> get(String id);

  Future<void> addParticipant(User user, String chatRoomId);
}