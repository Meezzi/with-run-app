import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:with_run_app/data/repository/image_repository.dart';
import 'package:with_run_app/data/repository/user_repository.dart';

class MyInfoState {
  String? imageName;
  String? imageUrl;

  MyInfoState({this.imageName, this.imageUrl});
}

class MyInfoViewModel extends Notifier<MyInfoState?> {
  @override
  MyInfoState? build() {
    return null;
  }

  /// 상태에 이미지 정보 업로드
  Future<void> uploadImage(XFile xfile) async {
    final imageRepo = ImageRepository();
    final re = await imageRepo.uploadImage(xfile);

    if (re != null) {
      String? prevImageName = state?.imageName;

      // 기존 이미지 firestorage에서 삭제
      if (state != null) {
        imageRepo.deleteImage(prevImageName!);
      }
      state = MyInfoState(imageName: re['imageName'], imageUrl: re['imageUrl']);
    }
  }
}

final myInfoViewModelProvider = NotifierProvider<MyInfoViewModel, MyInfoState?>(
  () {
    return MyInfoViewModel();
  },
);
