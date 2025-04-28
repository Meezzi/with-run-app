

import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';

abstract interface class ChatRoomRepository {
  Future<void> create(ChatRoomModel chatRoom, User creator);

  Future<void> get(String id);
}