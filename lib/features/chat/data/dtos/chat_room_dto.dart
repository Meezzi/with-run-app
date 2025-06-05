import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';


class ChatRoomDto {
  final String id;
  // final List<UserDto> participants;
  // final UserDto creator;
  final String title;
  final String description;
  final DateTime createdAt;
  final GeoPoint location;

  ChatRoomDto({
    required this.id,
    // required this.participants,
    // required this.creator,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // 'participants': participants.map((e) => e.toMap()).toList(),
      // 'creator': creator.toMap(),
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
    };
  }

  factory ChatRoomDto.fromMap(Map<String, dynamic> map) {
    return ChatRoomDto(
      id: map['id'] ?? '',
      // participants: (map['participants'] as List<dynamic>)
      //     .map((e) => UserDto.fromMap(e as Map<String, dynamic>))
      //     .toList(),
      // creator: UserDto.fromMap(map['creator']),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      location: map['location'] as GeoPoint,
    );
  }

  factory ChatRoomDto.fromEntity(ChatRoom room) {
    return ChatRoomDto(
      id: room.id,
      // participants: room.participants.map(UserDto.fromEntity).toList(),
      // creator: UserDto.fromEntity(room.creator),
      title: room.title,
      description: room.description,
      createdAt: room.createdAt,
      location: room.location,
    );
  }

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      // participants: participants.map((e) => e.toEntity()).toList(),
      // creator: creator.toEntity(),
      title: title,
      description: description,
      createdAt: createdAt,
      location: location,
    );
  }
}
