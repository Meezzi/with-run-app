import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase의 현재 User를 제공하는 Provider
final firebaseUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});