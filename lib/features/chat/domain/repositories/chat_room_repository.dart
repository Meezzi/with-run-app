

import 'package:with_run_app/features/chat/presentation/chat_room/models/chat_room_model.dart';
import 'package:with_run_app/features/auth/data/user.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';

abstract interface class ChatRoomRepository {
  Future<String> create(ChatRoom chatRoom);

  Future<ChatRoomModel> get(String id);

  Future<void> addParticipant(User user, String chatRoomId);
}