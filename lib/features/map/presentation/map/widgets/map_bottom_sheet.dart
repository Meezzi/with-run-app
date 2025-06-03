import 'package:flutter/material.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/chat_room_description.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/chat_room_detail.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/chat_room_header.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/chat_room_join_button.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/map_bottom_sheet_header.dart';

class MapBottomSheet extends StatelessWidget {
  const MapBottomSheet(this.chatroom, {super.key});

  final ChatRoom chatroom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Column(
        children: [
          const MapBottomSheetHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChatRoomHeader(chatroom),
                  const SizedBox(height: 20),
                  ChatRoomDescription(chatroom.description),
                  const Spacer(),
                  ChatRoomDetail(chatroom),
                  const SizedBox(height: 20),
                  const ChatRoomJoinButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
