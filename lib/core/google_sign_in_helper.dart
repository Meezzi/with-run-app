import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart'; // debugPrint를 사용하기 위해 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 추가

Future<UserCredential?> signInWithGoogle() async {
  try {
    // 이미 로그인되어 있는지 확인
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint('이미 로그인된 사용자: ${currentUser.uid}');
      
      // 사용자 정보가 Firestore에 있는지 확인
      bool userExists = await _checkUserExists(currentUser.uid);
      
      // 이미 로그인되어 있고 사용자 정보가 있으면 새 인증 없이 null 반환
      // (null 대신 사용자 정보가 있다는 표시를 반환하도록 로직을 수정해야 함)
      if (userExists) {
        debugPrint('기존 사용자 정보가 있습니다. 다시 로그인하지 않고 기존 정보 반환');
        // UserCredential은 직접 생성할 수 없으므로 null을 반환하고 로직을 수정
        return null;
      }
      
      // 사용자 정보가 없으면 프로필 정보 입력 화면으로 넘어가도록 null 반환
      debugPrint('기존 사용자 정보가 없습니다. 프로필 설정 필요');
      return null;
    }

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    
    // 사용자가 로그인을 취소한 경우
    if (googleUser == null) {
      debugPrint('Google 로그인 취소됨');
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    // 신규 로그인 시 사용자 정보가 있는지 확인
    bool userExists = await _checkUserExists(userCredential.user!.uid);
    
    debugPrint('새로운 로그인 완료: ${userCredential.user!.uid}, 기존 정보 있음: $userExists');
    return userCredential;
  } catch (e) {
    debugPrint('Google 로그인 오류: $e');
    return null;
  }
}

// 사용자 정보가 Firestore에 있는지 확인하는 함수
Future<bool> _checkUserExists(String uid) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists;
  } catch (e) {
    debugPrint('사용자 정보 확인 오류: $e');
    return false;
  }
}

Future<void> signOutGoogle() async {
  try {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('로그아웃 오류: $e');
  }
}