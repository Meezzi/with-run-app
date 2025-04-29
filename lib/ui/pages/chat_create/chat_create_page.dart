import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:with_run_app/core/loading_bar.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_notifier.dart';
import 'package:with_run_app/ui/pages/chat_create/date_picker_input.dart';
import 'package:with_run_app/ui/pages/chat_create/time_range_picker_input.dart';
import 'package:with_run_app/ui/pages/chat_create/util/chat_creat_input_validator.dart';
import 'package:with_run_app/ui/pages/chat_create/util/chat_create_util.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_information_page.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
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
  final loadingBar = LoadingOverlay();
  TimeRange? timeRange;
  DateTime? date;
  bool isLoadingLocation = true;
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    // 화면이 렌더링 된 후에 위치 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocationData();
    });
  }

  Future<void> _loadLocationData() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // map_provider에서 selectedPosition 가져오기
      final mapState = ref.read(mapProvider);
      final position = mapState.selectedPosition;

      if (position != null) {
        selectedLocation = position;
        
        // 역지오코딩으로 주소 변환
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, 
            position.longitude
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String addressText = '${place.street ?? ''}, ${place.thoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
            
            if (addressText.isNotEmpty) {
              locationController.text = addressText;
            } else {
              locationController.text = '${position.latitude}, ${position.longitude}';
            }
          } else {
            locationController.text = '${position.latitude}, ${position.longitude}';
          }
        } catch (e) {
          debugPrint('주소 변환 오류: $e');
          locationController.text = '${position.latitude}, ${position.longitude}';
        }
      } else {
        locationController.text = '위치를 선택해주세요';
      }
    } catch (e) {
      debugPrint('위치 초기화 오류: $e');
      locationController.text = '위치 정보를 가져올 수 없습니다';
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

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
                            isLoading: isLoadingLocation,
                            onTap: () {
                              // 맵 화면으로 돌아가서 위치 선택하도록
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('지도 화면으로 돌아가서 위치를 선택해주세요'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.pop(context);
                            },
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
                    if (selectedLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('지도에서 위치를 선택해주세요'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // 폼 유효성 검사
                    final isFormValid = formKey.currentState?.validate() ?? false;
                    if (!isFormValid) {
                      return;
                    }

                    try {
                      loadingBar.show(context);
                      
                      // 사용자 정보 가져오기
                      await ref
                          .read(userViewModelProvider.notifier)
                          .getById(
                            FirebaseAuth.instance.currentUser?.uid as String,
                          );
                      final user = ref.read(userViewModelProvider);
                      
                      if (user == null) {
                        throw Exception('사용자 정보를 가져올 수 없습니다.');
                      }
                      
                      // 채팅방 생성
                      final chatRoom = getChatRoom(user);
                      final result = await notifier.create(chatRoom, user);
                      
                      // 채팅방 입장
                      await ref
                          .read(chatRoomViewModel.notifier)
                          .enterChatRoom(result);
                      
                      loadingBar.hide();
                      
                      // 채팅방 정보 페이지로 이동
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => ChatInformationPage()),
                        );
                      }
                    } catch (e) {
                      loadingBar.hide();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('채팅방 생성 실패: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('채팅방 만들기'),
                ),
              )
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
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requiredInput(name, isRequired)),
          SizedBox(height: 8),
          isLoading 
            ? const Center(child: CircularProgressIndicator())
            : customInput ?? GestureDetector(
                onTap: onTap,
                child: TextFormField(
                  validator: validator,
                  controller: controller,
                  readOnly: readOnly,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: readOnly && onTap != null 
                      ? const Icon(Icons.edit_location_alt) 
                      : null,
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
      location: selectedLocation != null 
        ? GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude)
        : GeoPoint(37.355149, 126.922238), // 기본값, 실제로는 유효성 검사에서 걸러짐
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