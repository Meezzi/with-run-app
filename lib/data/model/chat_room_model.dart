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

    participants.forEach((e){
      print(e.nickname);
    });

    return ChatRoomModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      location: data['location'],
      creator: User.fromJson(data['creator']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      participants: participants,
      lastMessage: data['lastMessage'],
      lastMessageTimestamp:
          data['lastMessageTimestamp'] != null
              ? (data['lastMessageTimestamp'] as Timestamp).toDate()
              : null,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
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
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
