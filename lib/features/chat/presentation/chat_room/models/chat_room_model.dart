import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/features/auth/presentation/login/models/login_model.dart';
import 'package:with_run_app/features/chat/domain/entities/chat_room.dart';

class ChatRoomModel {
  final String? id;
  final String title;
  final String? description;
  final GeoPoint location;
  final UserModel creator;
  final DateTime createdAt;
  final List<UserModel>? participants;
  final String? lastMessage;
  final String address;
  final int memberCount;
  final DateTime? lastMessageTimestamp;
  final DateTime startTime;
  final DateTime endTime;

  ChatRoomModel({
    this.id,
    required this.title,
    this.description,
    required this.location,
    required this.creator,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.address,
    required this.memberCount,
    this.participants,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  ChatRoom toEntity() {
    return ChatRoom(
      id: id!,
      participants: participants!.map((e) => e.toEntity()).toList(),
      creator: creator.toEntity(),
      title: title,
      description: description!,
      createdAt: createdAt,
      location: location,
      address: address,
      memberCount: memberCount,
    );
  }

  factory ChatRoomModel.fromEntity(ChatRoom room) {
    return ChatRoomModel(
      id: room.id,
      participants: room.participants.map((e) => UserModel.fromEntity(e)).toList(),
      creator: UserModel.fromEntity(room.creator),
      title: room.title,
      description: room.description,
      createdAt: room.createdAt,
      address: room.address,
      memberCount: room.memberCount,
      location: room.location,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
    );
  }
}
