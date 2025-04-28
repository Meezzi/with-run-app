import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final String creatorId;
  final DateTime createdAt;
  final List<String>? participants;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;

  ChatRoom({
    required this.id,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.creatorId,
    required this.createdAt,
    this.participants,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatRoom(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      participants: data['participants'] != null 
          ? List<String>.from(data['participants']) 
          : null,
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: data['lastMessageTimestamp'] != null 
          ? (data['lastMessageTimestamp'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'participants': participants ?? [],
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null 
          ? Timestamp.fromDate(lastMessageTimestamp!) 
          : null,
    };
  }
}