import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:with_run_app/data/model/user.dart';

class UserRepository {
  /// firebase database에 로그인한 User정보 추가
  Future<bool> insert({
    required String uid,
    required String nickname,
    required String profileImageUrl,
  }) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference collectionRef = firestore.collection('users');
      DocumentReference documentRef = collectionRef.doc(uid);

      await documentRef.set({
        'uid': uid,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
      });

      return true;
    } catch (e) {
      debugPrint('UserRepository.insert catch문 - $e');
      return false;
    }
  }

  Future<User?> getById(String? uid) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection('users');
      final documentRef = collectionRef.doc(uid);
      final doc = await documentRef.get();

      return User.fromJson({...doc.data()!});
    } catch (e) {
      debugPrint('UserRepository.getById catch문 - $e');
      return null;
    }
  }
}