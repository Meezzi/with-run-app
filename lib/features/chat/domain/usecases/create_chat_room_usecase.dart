import 'package:with_run_app/core/result/result.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';
import 'package:with_run_app/features/chat/domain/repositories/chat_room_repository.dart';

class CreateChatRoomUsecase {
  final ChatRoomRepository _repository;

  CreateChatRoomUsecase(this._repository);

  Future<String> execute(ChatRoom chatRoom){
    return _repository.create(chatRoom);
  }
}