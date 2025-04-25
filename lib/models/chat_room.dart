import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final double latitude;
  final double longitude;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final String title;
  final String? description;

  ChatRoom({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.title,
    this.description,
  });

  // Firebase에서 데이터를 가져와 ChatRoom 객체로 변환
  factory ChatRoom.fromMap(Map<String, dynamic> map, String documentId) {
    return ChatRoom(
      id: documentId,
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      title: map['title'] ?? '',
      description: map['description'],
    );
  }

  // ChatRoom 객체를 Firebase에 저장하기 위한 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt,
      'title': title,
      'description': description,
    };
  }
}