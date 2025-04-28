

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/chat_room_firebase_repository.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';

enum ChatRoomCreateState {
  intialize,
  submitted,
  done,
  error,
}

class ChatCreateNotifier extends AutoDisposeNotifier<ChatRoomCreateState>{
  void create(ChatRoomModel chatRoom, User creator){
    state = ChatRoomCreateState.submitted;
    final repository = ref.read(repositoryProvider);
    repository.create(chatRoom, creator);
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