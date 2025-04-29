### withRun


### Overview
withRun은 Flutter와 Dart로 개발된 모바일 앱으로, Google Maps API를 활용해 사용자의 위치를 표시하고 채팅방을 개설해 함께 러닝을 즐길 수 있는 서비스입니다. 러닝 종료 후 결과와 랭킹을 확인할 수 있습니다.

### Features

Google 로그인: 사용자 인증 및 프로필 설정(사진, 닉네임).
Google Maps 페이지: 현재 위치 표시, 채팅방 개설/참여, 채팅방 목록 확인.
채팅방 기능:
개설자: 시작/종료 버튼 제공.
참여자: "러닝 대기중" 문구 표시.


러닝 결과:
키로수, 속도, 소모 칼로리, 이동 시간 표시.
채팅방 인원 간 닉네임 기반 랭킹 제공.


오늘의 TOP 러너: 닉네임, 키로수, 이동 시간 표시.

### How It Works

앱 실행 후 Google 로그인.
프로필 설정(사진, 닉네임).
Google Maps 페이지에서:
현재 위치 확인.
채팅방 개설 또는 참여.
채팅방 목록 확인.


채팅방에서:
개설자는 시작/종료 버튼으로 러닝 관리.
참여자는 대기 상태 확인.


러닝 종료 후:
키로수, 속도, 칼로리, 이동 시간 확인.
채팅방 인원 랭킹 및 "오늘의 TOP 러너" 확인.



### Requirements

Google Maps API 키
Google 로그인 설정
인터넷 연결
위치 정보 접근 허용

### Installation

Google Maps API 키와 Google 로그인 설정.
프로젝트 클론 및 의존성 설치:git clone <repository-url>
cd withRun
flutter pub get


.env 파일에 API 키 추가:GOOGLE_MAPS_API_KEY=<your-api-key>


iOS 설정:
ios/Flutter/Environment.xcconfig 파일에 Google Maps API 키 추가:GOOGLE_MAPS_API_KEY=<your-api-key>


ios/Runner/Info.plist에 API 키 추가 (필요 시):<key>GoogleMapsApiKey</key>
<string>$(GOOGLE_MAPS_API_KEY)</string>




앱 실행:flutter run



.gitignore
*.tmp
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
.env
ios/Flutter/Environment.xcconfig

### Usage

Google 로그인 후 프로필 설정.
Google Maps 페이지에서 채팅방 개설/참여.
채팅방에서 러닝 시작 및 종료.
러닝 결과와 랭킹 확인.

### Contributing

기여를 원하시면 이슈를 등록하거나 풀 리퀘스트를 보내주세요.

### License
MIT License
