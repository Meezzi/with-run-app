---
name: Refactor
about: Refactor
title: "[Rank] 위젯 분리"
labels: refactor
assignees: ''

---

### 🔧 리팩토링 항목
UserService 내부의 회원 가입/로그인 관련 로직

### :pushpin: 리팩토링 목적
- 현재 UserService에 인증/계정/권한 관련 책임이 모두 몰려 있음
- 중복된 로직 존재 (예: 이메일 검증 로직)
- 테스트 코드 작성이 어려운 구조

### :white_check_mark: 기대 효과
- 서비스 클래스의 책임 분리가 이루어져 변경에 유연하게 대응 가능
- 로직 재사용성 증가
- 단위 테스트 가능하도록 구조 개선

### :mag: 참고 사항
- 기존 API 응답 및 동작은 변경되지 않아야 함
