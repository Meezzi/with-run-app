import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';
import 'package:with_run_app/features/chat/data/repositories/chat_room_firebase_repository.dart';
import 'package:with_run_app/features/chat/domain/repositories/chat_room_repository.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/models/chat_room_model.dart';

enum ChatRoomCreateState { intialize, submitted, done, error }

// 뷰모델이니깐 나중에 뷰모델로 이름 변경하기~
class ChatCreateViewModel extends AutoDisposeNotifier<ChatRoomCreateState> {
  Future<String> create(ChatRoomModel chatRoom, UserEntity creator) async {
    state = ChatRoomCreateState.submitted;
    final repository = ref.read(repositoryProvider);
    final chatRoomEntity = chatRoom.toEntity();

    final result = await repository.create(chatRoomEntity);
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

final chatCreateViewModel =
    NotifierProvider.autoDispose<ChatCreateViewModel, ChatRoomCreateState>(() {
      return ChatCreateViewModel();
    });
