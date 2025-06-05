import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/models/chat_room_model.dart';
import 'package:with_run_app/features/chat/data/repositories/chat_room_firebase_repository.dart';
import 'package:with_run_app/features/chat/domain/repositories/chat_room_repository.dart';

class ChatRoomViewModel extends Notifier<ChatRoomModel?>{
  Future<ChatRoomModel?> enterChatRoom(String roomId) async{
    final repository = ref.read(chatRoomRepositoryProvider);
    ChatRoom? result = await repository.get(roomId);
    state = ChatRoomModel.fromEntity(result);
    return state;
  }

  void leaveChatRoom(){
    state = null;
  }
  
  @override
  ChatRoomModel? build() {
    return null;
  }

}

final chatRoomRepositoryProvider = Provider<ChatRoomRepository>((ref) {
  return ChatRoomFirebaseRepository();
});


final chatRoomViewModel = NotifierProvider<ChatRoomViewModel, ChatRoomModel?>(() {
  return ChatRoomViewModel();
});