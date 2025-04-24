import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MyInfoPage extends StatefulWidget {
  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  bool isSelected = false;
  final formKey = GlobalKey<FormState>();
  late final contentController = TextEditingController();

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
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
                  print('완료');
                  final result = formKey.currentState!.validate();
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
                    onTap: () async {
                      print('프로필 추가');
                      // 이미지 피커 객체 생성
                      ImagePicker imagePicker = ImagePicker();
                      XFile? xFile = await imagePicker.pickImage(
                        source: ImageSource.gallery,
                      );
                    },
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(74),
                          child: Container(
                            width: 74,
                            height: 74,
                            color: Colors.grey[300],
                            child:
                                isSelected
                                    ? Image.network(
                                      'https://picsum.photos/200/300',
                                      fit: BoxFit.cover,
                                    )
                                    : Icon(Icons.person, size: 36),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.add_circle),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '닉네임을 입력해 주세요',
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey), // 비활성 상태일 때
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).highlightColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return '닉네임을 입력해 주세요';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
