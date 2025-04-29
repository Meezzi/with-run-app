import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/chat_room_firebase_repository.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';

enum ChatRoomCreateState {
  initialize,
  submitted,
  done,
  error,
}

class ChatCreateNotifier extends AutoDisposeNotifier<ChatRoomCreateState>{
  Future<String> create(ChatRoomModel chatRoom, User creator) async{
    state = ChatRoomCreateState.submitted;
    final repository = ref.read(repositoryProvider);
    
    try {
      final result = await repository.create(chatRoom, creator);
      
      // 채팅방 생성 후 지도 새로고침
      await ref.read(mapProvider.notifier).refreshMap();
      
      state = ChatRoomCreateState.done;
      return result;
    } catch (e) {
      state = ChatRoomCreateState.error;
      rethrow;
    }
  }
  
  @override
  ChatRoomCreateState build() {
    return ChatRoomCreateState.initialize;
  }
}

final repositoryProvider = Provider<ChatRoomRepository>((ref) {
  return ChatRoomFirebaseRepository();
});

final chatCreateNotifier = NotifierProvider.autoDispose<ChatCreateNotifier, ChatRoomCreateState>(() {
  return ChatCreateNotifier();
});