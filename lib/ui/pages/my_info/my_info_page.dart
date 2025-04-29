import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:with_run_app/core/loading_bar.dart';
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

  // 중복 처리 방지 플래그
  bool _isProcessing = false;
  
  /// 완료 버튼 이벤트 - 성능 최적화
  Future<void> _onComplete() async {
    // 중복 처리 방지
    if (_isProcessing) return;
    _isProcessing = true;
    
    final isNicknameValid = formKey.currentState!.validate();
    final userVm = ref.read(userViewModelProvider.notifier);
    final myInfoState = ref.read(myInfoViewModelProvider);

    if (myInfoState.xFile == null) {
      myInfoVm.changeValid(true);
    }

    if (!isNicknameValid || myInfoState.xFile == null) {
      _isProcessing = false;
      return; // 유효성 검사 실패 시 빠른 반환
    }
    
    // 비동기 작업 전에 context가 여전히 유효한지 확인
    if (!mounted) {
      _isProcessing = false;
      return;
    }
    
    loadingBar.show(context);

    try {
      // 페이지 전환 미리 준비 (성능 개선)
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => Container(color: Colors.transparent),
        ),
      );
      
      // 이미지 업로드 최적화 (비동기 처리)
      final newStateFuture = myInfoVm.uploadImage(myInfoState.xFile!);
      
      // 사용자 정보 저장 준비
      MyInfoState? newState = await newStateFuture;
      
      // 마운트 상태 확인
      if (!mounted) {
        loadingBar.hide();
        _isProcessing = false;
        return;
      }
      
      // 사용자 정보 저장
      final isSignin = await userVm.insert(
        uid: widget.uid,
        nickname: nicknameController.text,
        profileImageUrl: newState?.imageUrl,
      );
      
      // 마운트 상태 재확인
      if (!mounted) {
        loadingBar.hide();
        _isProcessing = false;
        return;
      }
      
      loadingBar.hide();

      if (isSignin) {
        // 모든 비동기 작업 후 context 사용 전 마운트 상태 확인
        if (!mounted) {
          _isProcessing = false;
          return;
        }
        
        // 미리 열었던 페이지 제거 후 맵 페이지로 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MapPage()),
          (route) => false,
        );
      }
    } catch (e) {
      // 오류 발생 시 로딩바 숨김
      if (mounted) {
        loadingBar.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 프로필 사진 추가 이벤트
  void _onSelectImage() async {
    // 이미지 피커 객체 생성
    final ImagePicker imagePicker = ImagePicker();

    try {
      final XFile? xFile = await imagePicker.pickImage(source: ImageSource.gallery);
      
      // 마운트 상태 확인
      if (!mounted) return;
      
      if (xFile != null) {
        myInfoVm.selectImage(xFile);
        myInfoVm.changeValid(false);
      }
    } catch (e) {
      // 이미지 선택 중 오류 발생 시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
        );
      }
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
    
    // iOS 스타일 테마 색상
    const Color iosBlue = Color(0xFF007AFF);
    
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: PopScope(
        canPop: isAndroid ? isClosed : true,
        onPopInvokedWithResult: (didPop, result) {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
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
            title: const Text('내 정보'),
            backgroundColor: iosBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onComplete,
                  child: Container(
                    alignment: Alignment.center,
                    width: 50,
                    child: const Text(
                      '',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F5F7), Colors.white],
              ),
            ),
            child: Form(
              key: formKey,
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '프로필 설정',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: iosBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _onSelectImage,
                              child: ProfileImagePicker(
                                myInfoState.xFile,
                                myInfoState.isImageValid,
                              ),
                            ),
                            const SizedBox(height: 24),
                            NicknameField(nicknameController),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _onComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: iosBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '완료',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}