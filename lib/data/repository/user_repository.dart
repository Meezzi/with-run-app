import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/data/model/user.dart';

class UserRepository {
  /// firebase database에 로그인한 User정보 추가
  Future<bool> insert({
    String? uid,
    String? nickname,
    String? profileImageUrl,
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
      print(e);
      return false;
    }
  }
}
