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
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/chatting_page/chatting_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
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
      _checkExistingRoom();
    });
  }
  
  // 이미 채팅방을 만들었는지 확인
  Future<void> _checkExistingRoom() async {
    try {
      final chatRoomVm = ref.read(chatRoomViewModel.notifier);
      final hasCreatedRoom = await chatRoomVm.userHasCreatedRoom();
      
      if (!mounted) return;
      
      if (hasCreatedRoom) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 생성한 채팅방이 있습니다. 한 번에 하나의 채팅방만 만들 수 있습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        
        // 맵 페이지로 돌아가기
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('채팅방 확인 오류: $e');
    }
  }

  Future<void> _loadLocationData() async {
    if (!mounted) return;
    
    // 로딩 상태 설정
    setState(() {
      isLoadingLocation = true;
    });

    debugPrint('위치 정보 로드 시작');

    try {
      // map_provider에서 selectedPosition 가져오기
      final mapState = ref.read(mapProvider);
      final position = mapState.selectedPosition;

      debugPrint('Map Provider에서 받은 선택된 위치: $position');
      
      if (position != null) {
        setState(() {
          selectedLocation = position;
        });
        
        // 역지오코딩으로 주소 변환
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, 
            position.longitude
          );
          
          if (!mounted) return;
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            String addressText = '${place.street ?? ''}, ${place.thoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
            
            setState(() {
              locationController.text = addressText.isNotEmpty
                  ? addressText
                  : '${position.latitude}, ${position.longitude}';
              isLoadingLocation = false;
            });
            
            debugPrint('역지오코딩 결과: $addressText');
          } else {
            setState(() {
              locationController.text = '${position.latitude}, ${position.longitude}';
              isLoadingLocation = false;
            });
            
            debugPrint('역지오코딩 결과 없음, 좌표 사용');
          }
        } catch (e) {
          debugPrint('주소 변환 오류: $e');
          if (!mounted) return;
          
          setState(() {
            locationController.text = '${position.latitude}, ${position.longitude}';
            isLoadingLocation = false;
          });
        }
      } else {
        debugPrint('선택된 위치 없음, 맵 상태 디버그 출력');
        ref.read(mapProvider.notifier).printDebugInfo();
        
        // 위치가 없으면 현재 위치로 설정 시도
        _tryUseCurrentLocation();
      }
    } catch (e) {
      debugPrint('위치 초기화 오류: $e');
      if (!mounted) return;
      
      setState(() {
        locationController.text = '위치 정보를 가져올 수 없습니다';
        isLoadingLocation = false;
      });
    }
  }

  // 현재 위치 사용 메서드 분리
  void _tryUseCurrentLocation() {
    final locationState = ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      debugPrint('현재 위치 사용: ${locationState.currentPosition}');
      final currentPos = LatLng(
        locationState.currentPosition!.latitude,
        locationState.currentPosition!.longitude
      );
      
      setState(() {
        selectedLocation = currentPos;
        locationController.text = '${currentPos.latitude}, ${currentPos.longitude}';
        isLoadingLocation = false;
      });
      
      // 임시 마커 추가
      ref.read(mapProvider.notifier).addTemporaryMarker(currentPos);
    } else {
      debugPrint('현재 위치도 없음, 선택 요청 메시지 표시');
      
      if (!mounted) return;
      
      setState(() {
        locationController.text = '위치를 선택해주세요';
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
    final formKey = GlobalKey<FormState>();
    
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: const Text('채팅방 만들기')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 350),
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
                  onPressed: () {
                    if (selectedLocation == null) {
                      // 위치가 없으면 맵 상태 확인
                      debugPrint('선택된 위치 없음, 맵 상태 확인');
                      final mapState = ref.read(mapProvider);
                      
                      if (mapState.selectedPosition != null) {
                        // 맵 상태에는 위치가 있는데 로컬 상태에는 없는 경우 업데이트
                        debugPrint('맵 상태에 위치 있음, 로컬 상태 업데이트: ${mapState.selectedPosition}');
                        setState(() {
                          selectedLocation = mapState.selectedPosition;
                        });
                      } else {
                        // 둘 다 없는 경우 메시지 표시
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('지도에서 위치를 선택해주세요'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }
                    
                    // 폼 유효성 검사
                    final isFormValid = formKey.currentState?.validate() ?? false;
                    if (!isFormValid) {
                      return;
                    }

                    // 비동기 작업을 자체 메소드로 분리
                    _createChatRoom();
                  },
                  child: const Text('채팅방 만들기'),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 채팅방 생성 로직을 별도 메서드로 분리
  Future<void> _createChatRoom() async {
    // mounted 체크와 컨텍스트 사용을 한 곳에서 처리
    if (!mounted) return;
    
    loadingBar.show(context);

    try {
      // 사용자 정보 가져오기
      await ref
          .read(userViewModelProvider.notifier)
          .getById(
            FirebaseAuth.instance.currentUser?.uid as String,
          );
      
      if (!mounted) {
        loadingBar.hide();
        return;
      }
      
      final user = ref.read(userViewModelProvider);
      
      if (user == null) {
        loadingBar.hide();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사용자 정보를 가져올 수 없습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // 채팅방 생성
      final chatRoom = getChatRoom(user);
      final result = await ref.read(chatCreateNotifier.notifier).create(chatRoom, user);
      
      // 마운트 상태 확인
      if (!mounted) {
        loadingBar.hide();
        return;
      }
      
      // 채팅방 입장
      await ref
          .read(chatRoomViewModel.notifier)
          .enterChatRoom(result);
      
      // 마운트 상태 재확인
      if (!mounted) {
        loadingBar.hide();
        return;
      }
      
      // 채팅방 생성 후 임시 마커 제거 및 채팅방 생성 모드 비활성화
      ref.read(mapProvider.notifier).removeTemporaryMarker();
      ref.read(mapProvider.notifier).setCreatingChatRoom(false);
      
      loadingBar.hide();
      
      // 모든 비동기 작업 이후에 mounted 체크를 직접 해준 다음 NavigatorPushReplacement 호출
      if (mounted) {
        Navigator.pushReplacement(
          context, // 여기서 context 사용은 바로 위의 mounted 체크로 보호됨
          MaterialPageRoute(
            builder: (context) => ChattingPage(
              chatRoomId: result,
              myUserId: user.uid ?? '',
              roomName: chatRoom.title,
              location: locationController.text,
            ),
          ),
        );
      }
    } catch (e) {
      // 마운트 상태 확인
      loadingBar.hide();
      
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 생성 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          const SizedBox(height: 8),
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
    // 선택된 위치가 null인 경우, 맵 프로바이더에서 다시 가져오기 시도
    if (selectedLocation == null) {
      final mapState = ref.read(mapProvider);
      if (mapState.selectedPosition != null) {
        selectedLocation = mapState.selectedPosition;
        debugPrint('getChatRoom: 맵 프로바이더에서 위치 가져옴: $selectedLocation');
      } else {
        debugPrint('getChatRoom: 위치 정보가 없음, 기본값 사용');
      }
    }

    return ChatRoomModel(
      title: titleController.text,
      description: descriptionController.text,
      location: selectedLocation != null 
        ? GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude)
        : const GeoPoint(37.355149, 126.922238), // 기본값, 실제로는 유효성 검사에서 걸러짐
      creator: user,
      createdAt: DateTime.now(),
      participants: [user], // 생성자를 participants에 추가
      startTime: makeDateTimeWithTime(date!, timeRange!.startTime),
      endTime: makeDateTimeWithTime(date!, timeRange!.endTime),
    );
  }

  String requiredInput(String name, bool isRequired) {
    return isRequired ? '* $name' : name;
  }
}