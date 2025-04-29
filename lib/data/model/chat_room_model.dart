import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/data/model/user.dart';

class ChatRoomModel {
  final String? id;
  final String title;
  final String? description;
  final GeoPoint location;
  final User? creator;
  final DateTime createdAt;
  final List<User>? participants;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final DateTime startTime;
  final DateTime endTime;
  final bool isStart; // 러닝 시작 상태

  ChatRoomModel({
    this.id,
    required this.title,
    this.description,
    required this.location,
    this.creator,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    this.participants,
    this.lastMessage,
    this.lastMessageTimestamp,
    this.isStart = false,
  });

  factory ChatRoomModel.fromFirestore(
    DocumentSnapshot doc,
    List<User> participants,
  ) {
    final rawData = doc.data();
    if (rawData == null) {
      throw Exception('Document data is null');
    }
    final data = rawData as Map<String, dynamic>;

    return ChatRoomModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      location: data['location'],
      creator: data['creator'] != null ? User.fromJson(data['creator']) : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      participants: participants,
      lastMessage: data['lastMessage'],
      lastMessageTimestamp:
          data['lastMessageTimestamp'] != null
              ? (data['lastMessageTimestamp'] as Timestamp).toDate()
              : null,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      isStart: data['isStart'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': GeoPoint(location.latitude, location.longitude),
      'creator': creator!.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTimestamp':
          lastMessageTimestamp != null
              ? Timestamp.fromDate(lastMessageTimestamp!)
              : null,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isStart': isStart,
    };
  }
}