import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String? id;
  final String title;
  final String? description;
  final GeoPoint location;
  final String creatorId;
  final DateTime createdAt;
  final List<String>? participants;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final DateTime startTime; 
  final DateTime endTime; 

  ChatRoom({
    this.id,
    required this.title,
    this.description,
    required this.location,
    required this.creatorId,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
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
      location : data['location'],
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      participants: data['participants'] != null 
          ? List<String>.from(data['participants']) 
          : null,
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: data['lastMessageTimestamp'] != null 
          ? (data['lastMessageTimestamp'] as Timestamp).toDate() 
          : null,
      startTime: data['startTime'],
      endTime : data['endTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location' : GeoPoint(location.latitude, location.longitude),
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null 
          ? Timestamp.fromDate(lastMessageTimestamp!) 
          : null,
      'startTime' : startTime,
      'endTime' : endTime,
    };
  }
}