import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:with_run_app/models/chat_room.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 컬렉션 참조
  CollectionReference get _chatRoomsCollection => 
      _firestore.collection('chatRooms');

  // 현재 로그인한 사용자 가져오기
  User? get currentUser => _auth.currentUser;

  // 채팅방 생성
  Future<ChatRoom?> createChatRoom({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final chatRoomData = {
        'latitude': latitude,
        'longitude': longitude,
        'creatorId': user.uid,
        'creatorName': user.displayName ?? '이름 없음',
        'createdAt': FieldValue.serverTimestamp(),
        'title': title,
        'description': description,
        'participants': [user.uid],
      };

      final docRef = await _chatRoomsCollection.add(chatRoomData);
      
      final chatRoomWithTimestamp = await docRef.get();
      final data = chatRoomWithTimestamp.data() as Map<String, dynamic>;
      
      return ChatRoom.fromMap(data, docRef.id);
    } catch (e) {
      debugPrint('채팅방 생성 중 오류 발생: $e');
      return null;
    }
  }

  // 특정 지역 범위 내의 채팅방 가져오기
  Stream<List<ChatRoom>> getNearbyRooms({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0,
  }) {
    return _chatRoomsCollection.snapshots().map((snapshot) {
      List<ChatRoom> chatRooms = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final chatRoom = ChatRoom.fromMap(data, doc.id);
        chatRooms.add(chatRoom);
      }
      return chatRooms;
    }).handleError((e) {
      debugPrint('주변 채팅방 가져오기 중 오류 발생: $e');
      return [];
    });
  }

  // 사용자가 참여한 채팅방 목록 가져오기
  Future<List<ChatRoom>> getJoinedChatRooms(String userId) async {
    try {
      final snapshot = await _chatRoomsCollection
          .where('participants', arrayContains: userId)
          .get();
      
      List<ChatRoom> chatRooms = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final chatRoom = ChatRoom.fromMap(data, doc.id);
        chatRooms.add(chatRoom);
      }
      return chatRooms;
    } catch (e) {
      debugPrint('참여한 채팅방 가져오기 중 오류 발생: $e');
      return [];
    }
  }

  // 채팅방 참가
  Future<bool> joinChatRoom(String chatRoomId) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      await _chatRoomsCollection.doc(chatRoomId).update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      
      return true;
    } catch (e) {
      debugPrint('채팅방 참가 중 오류 발생: $e');
      return false;
    }
  }
}