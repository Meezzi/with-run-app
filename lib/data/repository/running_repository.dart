import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/core/result/result.dart'; // Result import
import 'package:with_run_app/data/model/running_data.dart';

class RunningRepository {
  final String chatRoomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RunningRepository({required this.chatRoomId});

  /// 참가자의 러닝 데이터를 Firestore에 저장
  Future<Result<bool>> saveRunningData(RunningData data) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      final docRef = _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('participants')
          .doc(userId);

      await docRef.set(data.toMap(), SetOptions(merge: true));
      return Result.ok(true);
    } catch (e) {
      return Result.error(Exception('러닝 데이터 저장 실패: $e'));
    }
  }
}
