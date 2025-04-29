

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
  Future<String> create(ChatRoomModel chatRoom, User creator) async{
    state = ChatRoomCreateState.submitted;
    final repository = ref.read(repositoryProvider);
    final result = await repository.create(chatRoom, creator);
    state = ChatRoomCreateState.done;
    return result;
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