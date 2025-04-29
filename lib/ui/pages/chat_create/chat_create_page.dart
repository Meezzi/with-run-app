import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_notifier.dart';
import 'package:with_run_app/ui/pages/chat_create/date_picker_input.dart';
import 'package:with_run_app/ui/pages/chat_create/time_range_picker_input.dart';
import 'package:with_run_app/ui/pages/chat_create/util/chat_creat_input_validator.dart';
import 'package:with_run_app/ui/pages/chat_create/util/chat_create_util.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_information_page.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

class ChatCreatePage extends ConsumerStatefulWidget {
  const ChatCreatePage({super.key});

  @override
  ConsumerState<ChatCreatePage> createState() => _ChatCreatePage();
}

class _ChatCreatePage extends ConsumerState<ChatCreatePage> {
  final titleController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  TimeRange? timeRange;
  DateTime? date;

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(chatCreateNotifier.notifier);
    final formKey = GlobalKey<FormState>();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: Text('채팅방 만들기')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(minHeight: 350),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          inputElement(
                            name: '장소',
                            readOnly: true,
                            controller: locationController,
                          ),
                          inputElement(
                            name: '채팅방 이름',
                            isRequired: true,
                            controller: titleController,
                            validator: titleInputValidator,
                          ),
                          inputElement(
                            name: '날짜',
                            isRequired: true,
                            customInput: DatePickerInput(
                              validator: datePickerValidation,
                              onDateChanged: (date) {
                                this.date = date;
                              },
                            ),
                          ),
                          inputElement(
                            name: '시간',
                            isRequired: true,
                            customInput: TimeRangePickerInput(
                              validator: timeRangePickerValidator,
                              onRangeChanged: (timeRange) {
                                this.timeRange = timeRange;
                              },
                            ),
                          ),
                          inputElement(
                            name: '설명',
                            maxLines: 5,
                            controller: descriptionController,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(userViewModelProvider.notifier)
                        .getById(
                          FirebaseAuth.instance.currentUser?.uid as String,
                        );
                    final user = await ref.read(userViewModelProvider);
                    final isFormValid =
                        formKey.currentState?.validate() ?? false;

                    // 커스텀 위젯 유효성 검사

                    if (!isFormValid) {
                      // 유효하지 않으면 종료
                      return;
                    }
                    print('created');
                    final chatRoom = getChatRoom(user!);
                    
                    final result = await notifier.create(
                      chatRoom,
                      user,
                    );
                    await ref.read(chatRoomViewModel.notifier).enterChatRoom(result);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatInformationPage()),
                    );
                  },
                  child: Text('채팅방 만들기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputElement({
    required String name,
    bool isRequired = false,
    int maxLines = 1,
    bool readOnly = false,
    Widget? customInput,
    TextEditingController? controller,
    String? Function(String?) validator = alwaysValid,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requiredInput(name, isRequired)),
          SizedBox(height: 8),
          customInput ??
              TextFormField(
                validator: validator,
                controller: controller,
                readOnly: readOnly,
                maxLines: maxLines,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  ChatRoomModel getChatRoom(User user) {
    return ChatRoomModel(
      title: titleController.text,
      description: descriptionController.text,
      location: GeoPoint(37.355149, 126.922238),
      creator: user,
      createdAt: DateTime.now(),
      startTime: makeDateTimeWithTime(date!, timeRange!.startTime),
      endTime: makeDateTimeWithTime(date!, timeRange!.endTime),
    );
  }

  String requiredInput(String name, bool isRequired) {
    return isRequired ? '* $name' : name;
  }
}
