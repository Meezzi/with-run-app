import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';

abstract interface class ChatRoomRepository {
  Future<String> create(ChatRoom chatRoom);

  Future<ChatRoom> get(String id);

  Future<void> addParticipant(UserEntity user, String chatRoomId);
}
