import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    print('Loading messages for chatRoomId: $chatRoomId');
    _subscription = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('Snapshot received: ${snapshot.docs.length} messages');
      final msgs = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Message data: $data');
        return Message.fromMap(data, doc.id);
      }).toList();
      state = msgs;
      print('State updated with ${msgs.length} messages');
    }, onError: (error) {
      print('Error loading messages: $error');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> sendMessage(String text) async {
    try {
      final newMessage = {
        'chatRoomId': chatRoomId,
        'senderId': myUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);
      print('Message sent: $text');
    } catch (e) {
      print('Error sending message: $e');
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

  Message({
    required this.messageId,
    required this.chatRoomId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    final timestamp = map['timestamp'];
    return Message(
      messageId: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}