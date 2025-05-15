import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:with_run_app/feature/widgets/loading_bar.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/my_info/my_info_view_model.dart';
import 'package:with_run_app/ui/pages/my_info/widgets/nickname_field.dart';
import 'package:with_run_app/ui/pages/my_info/widgets/profile_image_picker.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

class MyInfoPage extends ConsumerStatefulWidget {
  final String uid;

  const MyInfoPage({super.key, required this.uid});

  @override
  ConsumerState<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends ConsumerState<MyInfoPage> {
  final formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController();
  late final myInfoVm = ref.read(myInfoViewModelProvider.notifier);
  final loadingBar = LoadingOverlay();
  bool isAndroid = Platform.isAndroid;
  bool isClosed = false;

  /// 완료 버튼 이벤트
  void _onComplete() async {
    final isNicknameValid = formKey.currentState!.validate();
    final userVm = ref.read(userViewModelProvider.notifier);
    final myInfoState = ref.read(myInfoViewModelProvider);

    if (myInfoState.xFile == null) {
      myInfoVm.changeValid(true);
    }

    if (isNicknameValid && myInfoState.xFile != null) {
      loadingBar.show(context);

      MyInfoState? newState = await myInfoVm.uploadImage(myInfoState.xFile!);

      final isSignin = await userVm.insert(
        uid: widget.uid,
        nickname: nicknameController.text,
        profileImageUrl: newState?.imageUrl,
      );

      loadingBar.hide();

      if (isSignin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MapPage();
            },
          ),
        );
      }
    }
  }

  /// 프로필 사진 추가 이벤트
  void _onSelectImage() async {
    // 이미지 피커 객체 생성
    ImagePicker imagePicker = ImagePicker();

    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      myInfoVm.selectImage(xFile);
      myInfoVm.changeValid(false);
    }
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myInfoState = ref.watch(myInfoViewModelProvider);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: isAndroid ? isClosed : true,
        onPopInvokedWithResult: (didPop, result) {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('앱을 종료하시려면 한번 더 뒤로가기 버튼을 눌러주세요'),
              ),
            );

            isClosed = true;
          });
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text('내 정보'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _onComplete();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 50,
                    child: Text(
                      '완료',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Form(
            key: formKey,
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    GestureDetector(
                      onTap: _onSelectImage,
                      child: ProfileImagePicker(
                        myInfoState.xFile,
                        myInfoState.isImageValid,
                      ),
                    ),
                    SizedBox(height: 20),
                    NicknameField(nicknameController),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
