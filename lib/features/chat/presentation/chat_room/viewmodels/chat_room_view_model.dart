import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/chat/data/chat_room_model.dart';
import 'package:with_run_app/features/chat/data/chat_room_firebase_repository.dart';
import 'package:with_run_app/features/chat/data/chat_room_repository.dart';

class ChatRoomViewModel extends Notifier<ChatRoomModel?>{
  Future<ChatRoomModel?> enterChatRoom(String roomId) async{
    final repository = ref.read(chatRoomRepositoryProvider);
    ChatRoomModel? result = await repository.get(roomId);
    state = result;
    return result;
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