

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/feature/chat/data/chat_room_model.dart';
import 'package:with_run_app/feature/auth/data/user.dart';
import 'package:with_run_app/feature/chat/data/chat_room_firebase_repository.dart';
import 'package:with_run_app/feature/chat/data/chat_room_repository.dart';

enum ChatRoomCreateState {
  intialize,
  submitted,
  done,
  error,
}
// 뷰모델이니깐 나중에 뷰모델로 이름 변경하기~
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