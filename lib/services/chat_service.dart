import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/models/message.dart';
import 'dart:math' as math;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 주변 채팅방 가져오기
  Stream<List<ChatRoom>> getNearbyRooms({
    required double latitude,
    required double longitude,
    double radiusInKm = 5.0, // 기본 반경은 5km
  }) {
    // Firestore는 지리적 쿼리를 직접 지원하지 않으므로 모든 채팅방을 가져와서 클라이언트에서 필터링
    return _firestore.collection('chatRooms').snapshots().map((snapshot) {
      List<ChatRoom> rooms = [];
      for (var doc in snapshot.docs) {
        final chatRoom = ChatRoom.fromFirestore(doc);
        
        // 거리 계산 (지구의 곡률을 고려한 간단한 근사)
        double distance = _calculateDistance(
          latitude, longitude, 
          chatRoom.latitude, chatRoom.longitude,
        );
        
        // 주어진 반경 내에 있는 채팅방만 추가
        if (distance <= radiusInKm) {
          rooms.add(chatRoom);
        }
      }
      return rooms;
    });
  }

  // 사용자가 참여한 채팅방 가져오기
  Future<List<ChatRoom>> getJoinedChatRooms(String userId) async {
    try {
      final createdRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('creatorId', isEqualTo: userId)
          .get();

      final participatingRoomsSnapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();

      Set<String> roomIds = {};
      List<ChatRoom> rooms = [];

      // 생성한 채팅방 추가
      for (var doc in createdRoomsSnapshot.docs) {
        if (!roomIds.contains(doc.id)) {
          roomIds.add(doc.id);
          rooms.add(ChatRoom.fromFirestore(doc));
        }
      }

      // 참여 중인 채팅방 추가 (중복 제거)
      for (var doc in participatingRoomsSnapshot.docs) {
        if (!roomIds.contains(doc.id)) {
          roomIds.add(doc.id);
          rooms.add(ChatRoom.fromFirestore(doc));
        }
      }

      return rooms;
    } catch (e) {
      debugPrint('참여 중인 채팅방 가져오기 오류: $e');
      return [];
    }
  }

  // 채팅방 생성
  Future<ChatRoom?> createChatRoom({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 이미 방을 생성했는지 확인
      final hasCreated = await hasUserCreatedRoom(user.uid);
      if (hasCreated) {
        throw Exception('이미 생성한 채팅방이 있습니다.');
      }

      final newChatRoomRef = _firestore.collection('chatRooms').doc();
      
      final chatRoom = ChatRoom(
        id: newChatRoomRef.id,
        title: title,
        description: description,
        latitude: latitude,
        longitude: longitude,
        creatorId: user.uid,
        createdAt: DateTime.now(),
        participants: [user.uid], // 생성자를 참여자로 자동 추가
      );

      await newChatRoomRef.set(chatRoom.toMap());
      
      return chatRoom;
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');
      return null;
    }
  }

  // 채팅방 참여
  Future<bool> joinChatRoom(String roomId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }
      
      // 이미 다른 방에 참여 중인지 확인
      final joinedRooms = await getJoinedChatRooms(user.uid);
      if (joinedRooms.isNotEmpty) {
        // 이미 해당 방에 참여 중인지 확인
        bool alreadyInThisRoom = joinedRooms.any((room) => room.id == roomId);
        if (alreadyInThisRoom) {
          // 이미 참여 중이라면 성공으로 간주
          return true;
        }
        
        // 다른 방에 참여 중이면 실패
        throw Exception('이미 다른 채팅방에 참여 중입니다.');
      }

      // 채팅방 참여
      await _firestore.collection('chatRooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([user.uid])
      });
      
      return true;
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      return false;
    }
  }

  // 메시지 보내기
  Future<bool> sendMessage(String roomId, String content, {String? imageUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final messageRef = _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc();

      final message = Message(
        id: messageRef.id,
        senderId: user.uid,
        senderName: user.displayName ?? '익명',
        content: content,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await messageRef.set(message.toMap());
      
      // 채팅방 최근 메시지 업데이트
      await _firestore.collection('chatRooms').doc(roomId).update({
        'lastMessage': content,
        'lastMessageTimestamp': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      debugPrint('메시지 전송 오류: $e');
      return false;
    }
  }

  // 채팅방 메시지 스트림
  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    });
  }

  // 두 지점 간의 거리 계산 (Haversine 공식)
  double _calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const double earthRadius = 6371; // 지구 반지름 (km)
    
    // 라디안으로 변환
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    double distance = earthRadius * c;
    
    return distance;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // 사용자가 생성한 방이 있는지 확인하는 함수
  Future<bool> hasUserCreatedRoom(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('chatRooms')
          .where('creatorId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('사용자 채팅방 조회 오류: $e');
      return false;
    }
  }

  // 채팅방 삭제 함수
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      // 먼저 채팅방 정보 가져오기
      final roomDoc = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .get();
      
      if (!roomDoc.exists) {
        return false; // 채팅방이 존재하지 않음
      }
      
      // 채팅방에 속한 메시지 삭제
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // 채팅방 문서 삭제
      batch.delete(roomDoc.reference);
      await batch.commit();
      
      return true;
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      return false;
    }
  }

  // 채팅방 나가기 함수
  Future<bool> leaveChatRoom(String roomId, String userId) async {
    try {
      // 참여자 목록에서 제거
      await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .update({
            'participants': FieldValue.arrayRemove([userId])
          });
      
      return true;
    } catch (e) {
      debugPrint('채팅방 나가기 오류: $e');
      return false;
    }
  }
}

// math 라이브러리 추가
