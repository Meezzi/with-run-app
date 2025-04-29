import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/setting/setting_page.dart';
import 'package:with_run_app/ui/pages/map/viewmodels/map_viewmodel.dart';
import 'package:with_run_app/ui/pages/map/viewmodels/chat_list_viewmodel.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> with WidgetsBindingObserver {
  // 현재 지도 줌 레벨 저장 변수
  double _currentZoomLevel = 15.0;
  bool _isInitialized = false;
  bool _initialLocationMoved = false;
  Timer? _locationMoveTimer;

  @override
  void initState() {
    super.initState();
    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('MapPage PostFrameCallback 실행');
        
        // MapViewModel 초기화 (비동기 작업 전에 미리 실행)
        ref.read(mapViewModelProvider.notifier).initialize(context);
        
        // 저장된 상태 확인 및 복원
        _checkAndRestoreState().then((_) {
          if (mounted) { // 비동기 작업 후 mounted 체크 추가
            // 위치 정보를 우선 새로고침
            ref.read(locationProvider.notifier).refreshLocation();
            
            // 위치 이동 순차적 시도
            _scheduleLocationMoves();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // 앱 생명주기 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    ref.read(mapViewModelProvider.notifier).dispose();
    _locationMoveTimer?.cancel();
    super.dispose();
  }

  // 순차적으로 위치 이동 시도
  void _scheduleLocationMoves() {
    // 기존 타이머가 있으면 취소
    _locationMoveTimer?.cancel();
    
    // 맵 컨트롤러와 위치 정보 모두 준비될 때까지 대기하는 방식으로 변경
    _locationMoveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final locationState = ref.read(locationProvider);
      final mapState = ref.read(mapProvider);
      
      debugPrint('위치 이동 시도 - 타이머 틱: ${timer.tick}, 위치 정보: ${locationState.currentPosition}, 맵 컨트롤러: ${mapState.mapController.isCompleted}');
      
      if (locationState.currentPosition != null && 
          mapState.mapController.isCompleted && 
          !_initialLocationMoved) {
        
        _tryMoveToCurrentLocation();
        
        if (_initialLocationMoved) {
          debugPrint('위치 이동 성공, 타이머 취소');
          timer.cancel(); // 이동 성공 시 타이머 취소
        }
      }
      
      // 20초 후에도 이동 안되면 타이머 취소 (무한 대기 방지)
      if (timer.tick > 20) {
        debugPrint('20초 제한 도달, 타이머 취소');
        timer.cancel();
      }
    });
    
    // 위치 변경 감지 리스너 설정
    ref.listen(locationProvider, (previous, current) {
      if (!_initialLocationMoved && current.currentPosition != null && mounted) {
        _tryMoveToCurrentLocation();
      }
    });
  }

  void _tryMoveToCurrentLocation() {
    final locationState = ref.read(locationProvider);
    final mapState = ref.read(mapProvider);
    
    debugPrint('위치 이동 시도 - 위치 정보: ${locationState.currentPosition}, 맵 컨트롤러: ${mapState.mapController.isCompleted}');
    
    if (locationState.currentPosition != null && mapState.mapController.isCompleted) {
      mapState.mapController.future.then((controller) {
        if (mounted) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  locationState.currentPosition!.latitude,
                  locationState.currentPosition!.longitude,
                ),
                zoom: _currentZoomLevel,
              ),
            ),
          ).then((_) {
            debugPrint('카메라 이동 완료');
            setState(() {
              _initialLocationMoved = true;
            });
          }).catchError((e) {
            debugPrint('카메라 이동 실패: $e');
          });
        }
      });
    }
  }

  // 앱 생명주기 변화 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // 앱이 백그라운드로 가거나 비활성화될 때 상태 저장
      _saveAppState();
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 돌아올 때 상태 복원
      if (_isInitialized) {
        _restoreAppState();
      }
    }
  }

  // 초기 상태 확인 및 복원 메서드
  Future<void> _checkAndRestoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 상태가 있는지 확인
      final hasState = prefs.containsKey('last_latitude') && 
                       prefs.containsKey('last_longitude');
      
      if (hasState) {
        // 저장된 상태가 있으면 복원
        if (mounted) {
          await _restoreAppState();
        }
      }
      
      // 채팅방 생성 모드와 임시 마커 상태 명시적으로 초기화
      if (mounted) {
        ref.read(mapProvider.notifier).setCreatingChatRoom(false);
        ref.read(mapProvider.notifier).removeTemporaryMarker();
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('초기 상태 확인 오류: $e');
    }
  }

  // 앱 상태 저장 메서드
  Future<void> _saveAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationState = ref.read(locationProvider);
      final mapState = ref.read(mapProvider);
      
      // 현재 위치 저장
      if (locationState.currentPosition != null) {
        await prefs.setDouble('last_latitude', locationState.currentPosition!.latitude);
        await prefs.setDouble('last_longitude', locationState.currentPosition!.longitude);
      }
      
      // 지도 줌 레벨 저장
      await prefs.setDouble('last_zoom_level', _currentZoomLevel);
      
      // 채팅방 생성 모드 상태 저장
      await prefs.setBool('is_creating_chat_room', mapState.isCreatingChatRoom);
      
      // 선택된 위치 저장 (채팅방 생성 중이라면)
      if (mapState.selectedPosition != null) {
        await prefs.setDouble('selected_latitude', mapState.selectedPosition!.latitude);
        await prefs.setDouble('selected_longitude', mapState.selectedPosition!.longitude);
        await prefs.setBool('has_selected_position', true);
      } else {
        await prefs.setBool('has_selected_position', false);
      }
      
      debugPrint('앱 상태 저장 완료');
    } catch (e) {
      debugPrint('앱 상태 저장 오류: $e');
    }
  }

  // 앱 상태 복원 메서드
  Future<void> _restoreAppState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 지도 줌 레벨 복원
      if (prefs.containsKey('last_zoom_level')) {
        _currentZoomLevel = prefs.getDouble('last_zoom_level') ?? 15.0;
      }
      
      // 채팅방 생성 모드 복원
      if (prefs.containsKey('is_creating_chat_room')) {
        final isCreatingChatRoom = prefs.getBool('is_creating_chat_room') ?? false;
        ref.read(mapProvider.notifier).setCreatingChatRoom(isCreatingChatRoom);
      }
      
      // 선택된 위치 복원 (채팅방 생성 중이라면)
      final hasSelectedPosition = prefs.getBool('has_selected_position') ?? false;
      final isCreatingChatRoom = prefs.getBool('is_creating_chat_room') ?? false;
      
      if (hasSelectedPosition && isCreatingChatRoom && 
          prefs.containsKey('selected_latitude') && 
          prefs.containsKey('selected_longitude')) {
        final lat = prefs.getDouble('selected_latitude');
        final lng = prefs.getDouble('selected_longitude');
        
        if (lat != null && lng != null) {
          final position = LatLng(lat, lng);
          ref.read(mapProvider.notifier).addTemporaryMarker(position);
        }
      } else {
        // 채팅방 생성 모드가 아니면 임시 마커 제거
        ref.read(mapProvider.notifier).removeTemporaryMarker();
      }
      
      // 마지막 위치로 카메라 이동
      if (prefs.containsKey('last_latitude') && prefs.containsKey('last_longitude')) {
        final lat = prefs.getDouble('last_latitude');
        final lng = prefs.getDouble('last_longitude');
        
        if (lat != null && lng != null) {
          // 맵 컨트롤러가 준비될 때까지 대기
          final mapState = ref.read(mapProvider);
          if (mapState.mapController.isCompleted) {
            final controller = await mapState.mapController.future;
            if (mounted) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(lat, lng),
                    zoom: _currentZoomLevel,
                  ),
                ),
              );
            }
          } else {
            // 맵 컨트롤러가 완료되지 않았다면, 맵이 생성될 때 이동하도록 콜백 설정
            _setupMapCreatedCallback(LatLng(lat, lng));
          }
        }
      }
      
      debugPrint('앱 상태 복원 완료');
    } catch (e) {
      debugPrint('앱 상태 복원 오류: $e');
    }
  }

  // 맵 생성 시 카메라 이동을 위한 콜백 설정
  void _setupMapCreatedCallback(LatLng target) {
    ref.listen(
      mapProvider.select((state) => state.mapController),
      (previous, current) {
        if (current.isCompleted && previous != null && !previous.isCompleted) {
          current.future.then((controller) {
            if (mounted) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: target,
                    zoom: _currentZoomLevel,
                  ),
                ),
              );
            }
          });
        }
      },
    );
  }

  // 앱 최소화 메서드
  Future<bool> _minimizeApp() async {
    // 앱을 최소화하기 전에 상태 저장
    await _saveAppState();
    await SystemNavigator.pop();
    return false;
  }

  // 지도 줌 레벨 변경 콜백
  void _onCameraMove(CameraPosition position) {
    _currentZoomLevel = position.zoom;
  }

  // 앱바 아이콘 버튼 통일 함수
  Widget _buildAppBarIconButton({
    required IconData icon, 
    required Color color, 
    required String tooltip, 
    required void Function() onPressed,
    bool isLoading = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 48, // 고정 너비
      height: 48, // 고정 높이
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: isLoading 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                ),
              )
            : Icon(
                icon,
                color: color,
                size: 24, // 아이콘 크기 통일
              ),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildAppTitle(AppThemeState themeState) {
    return GestureDetector(
      onTap: () => ref.read(appThemeProvider.notifier).toggleTheme(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: themeState.isDarkMode ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_run,
              color:
                  themeState.isDarkMode
                      ? Colors.green[600]
                      : const Color(0xFF00E676),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "WithRun",
              style: TextStyle(
                color:
                    themeState.isDarkMode
                        ? Colors.black
                        : const Color(0xFF212121),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeProvider);
    final locationState = ref.watch(locationProvider);
    final mapState = ref.watch(mapProvider);

    final initialPosition =
        locationState.currentPosition != null
            ? CameraPosition(
              target: LatLng(
                locationState.currentPosition!.latitude,
                locationState.currentPosition!.longitude,
              ),
              zoom: 15,
            )
            : const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 11);

    // PopScope를 사용하여 뒤로가기 동작 제어
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _minimizeApp();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0, // 제목 간격 줄임
          leading: _buildAppBarIconButton(
            icon: Icons.menu,
            color: themeState.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
            tooltip: '설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
          
          // 새로고침 버튼을 리딩 바로 오른쪽에 배치 (메뉴 바로 오른쪽)
          leadingWidth: 48, // 리딩 영역 폭
          title: Row(
            children: [
              // 새로고침 버튼을 메뉴 버튼 바로 오른쪽에 배치
              _buildAppBarIconButton(
                icon: Icons.refresh,
                color: themeState.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
                tooltip: '새로고침',
                isLoading: mapState.isRefreshing,
                onPressed: () async {
                  await ref.read(mapProvider.notifier).refreshMap();
                  // 채팅방 목록도 함께 새로고침
                  ref.read(chatListViewModelProvider.notifier).refreshChatRooms();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('새로고침 완료'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              // 중앙 타이틀
              Expanded(
                child: Center(
                  child: _buildAppTitle(themeState),
                ),
              ),
            ],
          ),
          
          actions: [
            // 내 위치 버튼
            _buildAppBarIconButton(
              icon: Icons.my_location,
              color: themeState.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
              tooltip: '내 위치로 이동',
              onPressed: () {
                ref.read(mapViewModelProvider.notifier).moveToCurrentLocation(context);
              },
            ),
            // 채팅 목록 버튼
            _buildAppBarIconButton(
              icon: Icons.forum_outlined,
              color: themeState.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
              tooltip: '채팅 목록',
              onPressed: () {
                ref.read(mapViewModelProvider.notifier).showChatListOverlay(context);
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: initialPosition,
              markers: mapState.markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: false,
              onMapCreated: (controller) {
                ref.read(mapProvider.notifier).setMapController(controller);
                
                // 맵이 생성되면 위치 정보가 있는지 확인하고 이동
                if (!_initialLocationMoved && locationState.currentPosition != null) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              locationState.currentPosition!.latitude,
                              locationState.currentPosition!.longitude,
                            ),
                            zoom: _currentZoomLevel,
                          ),
                        ),
                      ).then((_) {
                        debugPrint('onMapCreated 내 카메라 이동 완료');
                        setState(() {
                          _initialLocationMoved = true;
                        });
                      }).catchError((e) {
                        debugPrint('onMapCreated 내 카메라 이동 실패: $e');
                      });
                    }
                  });
                }
              },
              onCameraMove: _onCameraMove,
              onTap: (position) {
                if (mapState.isCreatingChatRoom) {
                  ref.read(mapProvider.notifier).onMapTap(position);
                }
              },
              mapType: MapType.normal,
              liteModeEnabled: false,
              style:
                  themeState.isDarkMode
                      ? themeState.darkMapStyle
                      : themeState.lightMapStyle,
            ),
            // 채팅방 생성 모드 안내 메시지 (임시 마커가 있을 때)
            if (mapState.isCreatingChatRoom && mapState.selectedPosition != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '초록색 마커를 탭하여 채팅방 생성',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 240,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          themeState.isDarkMode
                              ? [Colors.blue[400]!, Colors.green[400]!]
                              : [
                                const Color(0xFF2196F3),
                                const Color(0xFF00E676),
                              ],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(30)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        // 이미 생성 모드이고 위치가 선택된 경우 - 바로 채팅방 생성 페이지로 이동
                        if (mapState.isCreatingChatRoom && mapState.selectedPosition != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChatCreatePage()),
                          );
                        } else {
                          // 아직 생성 모드가 아니면 생성 모드 시작
                          ref.read(mapViewModelProvider.notifier).startChatRoomCreationMode(context);
                        }
                      },
                      splashColor: const Color(0x33FFFFFF),
                      highlightColor: const Color(0x22FFFFFF),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 16,
                            child: Icon(
                              Icons.add_comment_outlined,
                              color:
                                  themeState.isDarkMode
                                      ? Colors.green[600]
                                      : const Color(0xFF2196F3),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            mapState.isCreatingChatRoom && mapState.selectedPosition != null
                                ? '채팅방 만들기'
                                : '새 채팅방 만들기',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}