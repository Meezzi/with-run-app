import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/my_info/my_info_view_model.dart';
import 'package:with_run_app/ui/pages/my_info/widgets/nickname_field.dart';
import 'package:with_run_app/ui/pages/my_info/widgets/profile.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

class MyInfoPage extends ConsumerStatefulWidget {
  String uid;

  MyInfoPage({required this.uid});

  @override
  ConsumerState<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends ConsumerState<MyInfoPage> {
  final formKey = GlobalKey<FormState>();
  final nicknameController = TextEditingController();
  bool isAndroid = Platform.isAndroid;
  bool isClosed = false;
  bool isImageValid = false;

  /// 완료 버튼 이벤트
  void _onComplete(myInfoState) async {
    final isNicknameValid = formKey.currentState!.validate();

    if (myInfoState?.imageUrl == null) {
      setState(() {
        isImageValid = true;
      });
    }

    if (isNicknameValid && myInfoState?.imageUrl != null) {
      final userVm = ref.read(userViewModelProvider.notifier);
      final isSignin = await userVm.insert(
        uid: widget.uid,
        nickname: nicknameController.text,
        profileImageUrl: myInfoState?.imageUrl,
      );

      if (isSignin != null) {
        Navigator.push(
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
    print('프로필 추가');
    // 이미지 피커 객체 생성
    ImagePicker imagePicker = ImagePicker();

    XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (xFile != null) {
      final myInfoVm = ref.read(myInfoViewModelProvider.notifier);
      await myInfoVm.uploadImage(xFile);

      setState(() {
        isImageValid = false;
      });
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
          print('hhhhhhhhh  hhhhhhhh: $isAndroid');

          setState(() {
            print('앱을 종료하시려면 한번 더 뒤로가기 버튼을 눌러주세요');
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
                    _onComplete(myInfoState);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 50,
                    child: Text(
                      '완료',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
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
                      child: Profile(myInfoState?.imageUrl, isImageValid),
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
