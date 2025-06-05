import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/features/auth/domain/entity/user_entity.dart';

class ChatRoom {
  final String id;
  final List<UserEntity> participants;
  final UserEntity creator;
  final String title;
  final String description;
  final DateTime createdAt;
  final GeoPoint location;
  final String address;
  final int memberCount;

  ChatRoom({
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

}