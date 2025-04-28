

import 'package:with_run_app/data/model/chat_room_model.dart';

abstract interface class ChatRoomRepository {
  Future<void> create(ChatRoomModel chatRoom);

  Future<void> get(String id);
}