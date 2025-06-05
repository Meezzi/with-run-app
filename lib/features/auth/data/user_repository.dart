import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/features/auth/data/dtos/user_dto.dart';
import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';

class UserRepository {
  /// firebase database에 로그인한 User정보 추가
  Future<bool> insert({
    required String id,
    required String nickname,
    required String profileImageUrl,
  }) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      CollectionReference collectionRef = firestore.collection('users');
      DocumentReference documentRef = collectionRef.doc(id);

      await documentRef.set({
        'id': id,
        'nickname': nickname,
        'profileImageUrl': profileImageUrl,
      });

      return true;
    } catch (e) {
      print('UserRepository.insert catch문 - $e');
      return false;
    }
  }

  Future<UserEntity?> getById(String? id) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection('users');
      final documentRef = collectionRef.doc(id);
      final doc = await documentRef.get();

      return UserDto.fromJson({...doc.data()!}).toEntity();
    } catch (e) {
      print('UserRepository.getById catch문 - $e');
      return null;
    }
  }
}
