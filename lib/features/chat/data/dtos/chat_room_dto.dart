import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/features/auth/data/dtos/user_dto.dart';
import '../../domain/entities/chat_room.dart';


class ChatRoomDto {
  final String id;
  final List<UserDto> participants;
  final UserDto creator;
  final String title;
  final String description;
  final DateTime createdAt;
  final GeoPoint location;
  final String address;
  final int memberCount;

  ChatRoomDto({
    required this.id,
    required this.participants,
    required this.creator,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.location,
    required this.address,
    required this.memberCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants.map((e) => e.toJson()).toList(),
      'creator': creator.toJson(),
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
    };
  }

  factory ChatRoomDto.fromMap(Map<String, dynamic> map) {
    return ChatRoomDto(
      id: map['id'] ?? '',
      participants: (map['participants'] as List<dynamic>)
          .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      creator: UserDto.fromJson(map['creator']),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      location: map['location'] as GeoPoint,
      address: map['address'],
      memberCount: map['memberCount'],
    );
  }

  factory ChatRoomDto.fromEntity(ChatRoom room) {
    return ChatRoomDto(
      id: room.id,
      participants: room.participants.map((e) => UserDto.fromEntity(e),).toList(),
      creator: UserDto.fromEntity(room.creator),
      title: room.title,
      description: room.description,
      createdAt: room.createdAt,
      location: room.location,
      address: room.address,
      memberCount: room.memberCount,
    );
  }

  ChatRoom toEntity() {
    return ChatRoom(
      id: id,
      participants: participants.map((e) => e.toEntity()).toList(),
      creator: creator.toEntity(),
      title: title,
      description: description,
      createdAt: createdAt,
      location: location,
      address: address,
      memberCount: memberCount,
    );
  }
}
