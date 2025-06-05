import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:with_run_app/features/auth/data/user.dart';

class ChatRoom {
  final String id;
  // final List<User> participants;
  // final User creator;
  final String title;
  final String description;
  final DateTime createdAt;
  final GeoPoint location;

  ChatRoom({
    required this.id,
    // required this.participants,
    // required this.creator,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.location,
  });

}