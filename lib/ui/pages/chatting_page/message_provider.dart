import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class MessageNotifier extends StateNotifier<List<Message>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String chatRoomId;
  final String myUserId;
  StreamSubscription? _subscription;

  MessageNotifier({
    required this.chatRoomId,
    required this.myUserId,
  }) : super([]) {
    _loadMessages();
  }

  void _loadMessages() {
    debugPrint('Loading messages for chatRoomId: $chatRoomId');
    _subscription = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      debugPrint('Snapshot received: ${snapshot.docs.length} messages');
      final msgs = snapshot.docs.map((doc) {
        final data = doc.data();
        return Message.fromMap(data, doc.id);
      }).toList();
      state = msgs;
      debugPrint('State updated with ${msgs.length} messages');
    }, onError: (error) {
      debugPrint('Error loading messages: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    try {
      // 참가자 정보 확인하여 닉네임 추가
      final userDoc = await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('participants')
          .doc(myUserId)
          .get();
      
      String nickname = '알 수 없음';
      String profileImageUrl = '';
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        nickname = userData?['nickname'] ?? '알 수 없음';
        profileImageUrl = userData?['profileImageUrl'] ?? '';
        
        // 사용자 정보가 없으면 Firebase Auth에서 가져오기 시도
        if (nickname == '알 수 없음') {
          final authUser = await _firestore.collection('users').doc(myUserId).get();
          if (authUser.exists) {
            final authData = authUser.data();
            nickname = authData?['nickname'] ?? '알 수 없음';
            profileImageUrl = authData?['profileImageUrl'] ?? '';
          }
        }
      } else {
        // 참가자 목록에 없는 경우 사용자 정보 가져와서 추가하기
        final authUser = await _firestore.collection('users').doc(myUserId).get();
        if (authUser.exists) {
          final authData = authUser.data();
          nickname = authData?['nickname'] ?? '알 수 없음';
          profileImageUrl = authData?['profileImageUrl'] ?? '';
          
          // 참가자로 등록
          await _firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .collection('participants')
              .doc(myUserId)
              .set({
                'nickname': nickname,
                'profileImageUrl': profileImageUrl,
              });
        }
      }
      
      final newMessage = {
        'chatRoomId': chatRoomId,
        'senderId': myUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderNickname': nickname, // 닉네임 추가
        'senderProfileImageUrl': profileImageUrl, // 프로필 이미지 추가
      };

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);
      debugPrint('Message sent by $nickname: $text');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}

final messageProvider =
    StateNotifierProvider.family<MessageNotifier, List<Message>, MessageProviderArgs>(
  (ref, args) => MessageNotifier(
    chatRoomId: args.chatRoomId,
    myUserId: args.myUserId,
  ),
);

class MessageProviderArgs {
  final String chatRoomId;
  final String myUserId;

  MessageProviderArgs({
    required this.chatRoomId,
    required this.myUserId,
  });
}

class Message {
  final String messageId;
  final String chatRoomId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String senderNickname;
  final String senderProfileImageUrl;

  Message({
    required this.messageId,
    required this.chatRoomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.senderNickname = '',
    this.senderProfileImageUrl = '',
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    final timestamp = map['timestamp'];
    return Message(
      messageId: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      senderNickname: map['senderNickname'] ?? '',
      senderProfileImageUrl: map['senderProfileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'senderNickname': senderNickname,
      'senderProfileImageUrl': senderProfileImageUrl,
    };
  }
}