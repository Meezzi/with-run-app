import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:with_run_app/features/auth/data/image_repository.dart';

class MyInfoState {
  // 이미지 피커에 의해 선택된 이미지
  XFile? xFile;
  // 프로필 이미지가 있는지 유효성 체크
  bool? isImageValid;
  // firestore에 있는 이미지를 삭제하기 위한 속성
  String? imageName;
  // 다른 사람 프로필을 나타내기 위해 Image.network로 사용할 속성
  String? imageUrl;

  MyInfoState({this.xFile, this.isImageValid, this.imageName, this.imageUrl});

  MyInfoState copyWith({
    XFile? xFile,
    bool? isImageValid,
    String? imageName,
    String? imageUrl,
  }) {
    return MyInfoState(
      xFile: xFile ?? this.xFile,
      isImageValid: isImageValid ?? this.isImageValid,
      imageName: imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageName,
    );
  }
}

class MyInfoViewModel extends Notifier<MyInfoState> {
  @override
  MyInfoState build() {
    return MyInfoState();
  }

  /// 이미지 유효성 체크를 위한 불리언 타입 변경
  void changeValid(bool isImageValid) {
    state = state.copyWith(isImageValid: isImageValid);
  }

  /// 프로필에 사용할 이미지를 상태에 저장
  void selectImage(XFile xFile) {
    state = state.copyWith(xFile: xFile);
  }

  /// firestore에 업로드할 이미지 정보를 상태에 저장
  Future<MyInfoState?> uploadImage(XFile xFile) async {
    final imageRepo = ImageRepository();
    final result = await imageRepo.uploadImage(xFile);

    if (result != null) {
      String? prevImageName = state.imageName;

      // 기존 이미지 firestorage에서 삭제
      if (prevImageName != null) {
        imageRepo.deleteImage(prevImageName);
      }

      state = state.copyWith(
        imageName: result['imageName'],
        imageUrl: result['imageUrl'],
      );

      return state;
    }

    return null;
  }
}

final myInfoViewModelProvider = NotifierProvider<MyInfoViewModel, MyInfoState>(
  () {
    return MyInfoViewModel();
  },
);
