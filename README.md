### ✨ withRun: 함께 뛰는 즐거움

![1](https://github.com/user-attachments/assets/1f0056dd-e6d9-41a8-9974-f599527f3fed)



## 🏃‍♂️ 개요

**withRun**은 Flutter와 Dart로 개발된 모바일 애플리케이션입니다.  
Google Maps API를 활용하여 사용자의 현재 위치를 표시하고, 채팅방을 개설해 함께 러닝을 즐길 수 있도록 지원합니다.  
러닝 종료 후에는 결과와 랭킹을 확인할 수 있습니다.

---

## 👥 Team - 3조 타코야끼 대머리 클럽

| 강민지 (조장) | 김기현 (조원) | 김지은 (조원) | 이성엽 (조원) | 이현진 (조원) |
|:-------------:|:-------------:|:-------------:|:-------------:|:-------------:|
| [@Meezzi](https://github.com/Meezzi) | [@arcmee](https://github.com/arcmee) | [@jek1m](https://github.com/jek1m) | [@bang9lee](https://github.com/bang9lee) | [@hyunjin912](https://github.com/hyunjin912) |
| 전체 총괄 | 채팅 | 채팅 | 지도 | 로그인 |

---

### 📱 앱 스크린샷

<p align="center">
  <img src="https://github.com/user-attachments/assets/b8ac29b3-e24a-45cb-b8ad-edaa2ddf9ba7" alt="Login Screen" width="250"/>
  <img src="https://github.com/user-attachments/assets/03244ca5-cb49-4b6c-9321-53377be02f64" alt="Map Screen" width="250"/>
  <img src="https://github.com/user-attachments/assets/042ecf41-6f14-4828-b953-9de79423442e" alt="Dark Mode Map Screen" width="250"/>
</p>

---

## 🏃‍♂️ 앱 주요 기능 미리보기

- 📱 간편한 **Google 로그인**으로 빠르게 시작

- 🗺️ **현재 위치 기반 지도 표시** 및 **채팅방 생성**

- 🌙 **다크 모드 지원**으로 야간에도 편리한 이용

---

## ✨ 상세 기능 소개

- **Google 로그인**: 사용자 인증 및 프로필 설정 (사진, 닉네임)

- **Google Maps 연동**: 현재 위치 표시, 채팅방 개설/참여, 채팅방 목록 확인

- **채팅방 기능**

  - 개설자: 시작/종료 버튼 제공
  - 참여자: "러닝 대기중" 상태 표시
  - 위치기반으로 채팅을 개설
  - 내주변의 채팅방 지도화면에서 마커로 확인가능

- **러닝 결과 표시**

  - 총 이동 거리 (km), 평균 속도, 소모 칼로리, 이동 시간

- **랭킹 기능**

  - 채팅방 내 닉네임 기반 랭킹
  - "오늘의 TOP 러너" 표시 (닉네임, 키로수, 이동 시간)

---

## 🛠️ 사용 기술 스택

- **Flutter (Dart)**
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Riverpod

### 🔌 주요 패키지 기능 설명

| 패키지 | 설명 |
|:------|:-----|
| `firebase_auth` | Firebase 기반 사용자 인증 |
| `cloud_firestore` | 실시간 채팅 및 유저 정보 저장용 NoSQL 데이터베이스 |
| `firebase_core` | Firebase 앱 초기화 및 연결 |
| `firebase_storage` | 사용자 프로필 이미지 저장 |
| `google_sign_in` | Google 계정 로그인 지원 |
| `google_maps_flutter` | 지도 및 위치 마커 구현 |
| `geolocator` | 현재 위치 및 위치 권한 처리 |
| `geocoding` | 위도/경도를 주소로 변환 |
| `flutter_dotenv` | `.env` 파일을 통한 API 키 관리 |
| `flutter_riverpod` | 상태 관리 라이브러리 (MVVM 아키텍처에 적합) |
| `provider` | 의존성 주입과 간단한 상태 관리 |
| `cupertino_icons` | iOS 스타일 기본 아이콘 제공 |
| `flutter_svg` | SVG 이미지 렌더링 |
| `http` | HTTP 통신 (서버와 데이터 송수신) |
| `intl` | 날짜, 시간, 숫자 포맷 처리 |
| `image_picker` | 갤러리/카메라에서 이미지 선택 |
| `time_range_picker` | 시간 범위 선택 UI |
| `shared_preferences` | 간단한 로컬 저장소 (ex: 토큰 저장) |
| `permission_handler` | 위치/사진 등 접근 권한 요청 처리 |
| `pedometer` | 걸음 수 측정 기능 제공 |
| `lottie` | 애니메이션 효과로 UI 향상 |

---

## 🔧 설치 및 실행 방법

- Google Maps API 키
- Firebase 인증 및 콘솔 설정
- `.env` 파일에 API 키 입력
- 인터넷 연결 및 위치 정보 접근 허용

---


# 1. 프로젝트 클론

- git clone https://github.com/Meezzi/with-run-app.git

# 2. 의존성 설치

- flutter pub get

## 🔐 .env 파일 설정

- GOOGLE_MAPS_API_KEY=<your-api-key>

## 🍎 iOS 설정

- ios/Flutter/Environment.xcconfig 파일에 추가

- GOOGLE_MAPS_API_KEY=<your-api-key>

- ios/Runner/Info.plist에 추가 (필요 시)

- <key>GoogleMapsApiKey</key>
- <string>$(GOOGLE_MAPS_API_KEY)</string>

## ▶ 앱 실행

- flutter run

## 📁 .gitignore

- gitignore

*.tmp
-android/app/google-services.json
-ios/Runner/GoogleService-Info.plist
-lib/firebase_options.dart
-.env
-ios/Flutter/Environment.xcconfig

## 📂 Directory Structure
(작성 예정)

## 📝 Additional Notes
향후 디렉토리 구조 설명, 기능 흐름도, 시연 영상 추가 예정

조별과제 및 발표용 문서로 최적화 완료

### 🔥 withRun: 함께 뛰는 러닝을 시작하세요!
