import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/model/user.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';

class ChatRoomFirebaseRepository implements ChatRoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> create(ChatRoomModel chatRoom, User creator) async {
    final result = await _firestore
        .collection('chatRooms')
        .add(chatRoom.toMap())
        .then((documentSnapshot) {
          debugPrint("Added Data with ID: ${documentSnapshot.id}");
          addParticipant(creator, documentSnapshot.id);
          return documentSnapshot.id;
        });
    return result;
  }

  @override
  Future<ChatRoomModel> get(String id) async {
    final doc = await _firestore.collection('chatRooms').doc(id).get();

    if (!doc.exists) {
      throw Exception('ChatRoom not found');
    }

    // 서브 컬렉션 participants 불러오기
    final participantsSnapshot =
        await _firestore
            .collection('chatRooms')
            .doc(id)
            .collection('participants')
            .get();

    final participants =
        participantsSnapshot.docs.map((e) {
          debugPrint('${e.id} : ${e.data()['nickname']}');
          final user = User.fromJson(e.data());
          user.uid = e.id;
          return user;
        }).toList();

    return ChatRoomModel.fromFirestore(doc, participants);
  }

  @override
  Future<void> addParticipant(User user, String chatRoomId) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('participants')
        .doc(user.uid)
        .set({
          'nickname': user.nickname,
          'profileImageUrl': user.profileImageUrl,
        });
  }
  
  @override
  Future<void> deleteRoom(String chatRoomId) async {
    // 참가자 컬렉션 삭제
    final participantsSnapshot = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('participants')
        .get();
        
    final batch = _firestore.batch();
    
    for (var doc in participantsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // 메시지 컬렉션 삭제
    final messagesSnapshot = await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .get();
        
    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // 채팅방 문서 삭제
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();
  }
  
  @override
  Future<void> removeParticipant(String userId, String chatRoomId) async {
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('participants')
        .doc(userId)
        .delete();
  }
  
  @override
  Future<List<ChatRoomModel>> getAllRooms() async {
    final snapshot = await _firestore.collection('chatRooms').get();
    
    final List<ChatRoomModel> rooms = [];
    
    for (final doc in snapshot.docs) {
      try {
        final participantsSnapshot = await _firestore
            .collection('chatRooms')
            .doc(doc.id)
            .collection('participants')
            .get();
            
        final participants = participantsSnapshot.docs.map((e) {
          final user = User.fromJson(e.data());
          user.uid = e.id;
          return user;
        }).toList();
        
        rooms.add(ChatRoomModel.fromFirestore(doc, participants));
      } catch (e) {
        debugPrint('Error loading room ${doc.id}: $e');
      }
    }
    
    return rooms;
  }
}