

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/repository/chat_room_firebase_repository.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:with_run_app/models/chat_room.dart';

enum ChatRoomCreateState {
  intialize,
  submitted,
  done,
  error,
}

class ChatCreateNotifier extends AutoDisposeNotifier<ChatRoomCreateState>{
  void create(ChatRoom chatRoom){
    state = ChatRoomCreateState.submitted;
    final repository = ref.read(repositoryProvider);
    print(chatRoom);
    repository.create(chatRoom);
    state = ChatRoomCreateState.done;
  }
  @override
  ChatRoomCreateState build() {
    return ChatRoomCreateState.intialize;
  }
}

final repositoryProvider = Provider<ChatRoomRepository>((ref) {
  return ChatRoomFirebaseRepository();
});


final chatCreateNotifier = NotifierProvider.autoDispose<ChatCreateNotifier, ChatRoomCreateState>(() {
  return ChatCreateNotifier();
});