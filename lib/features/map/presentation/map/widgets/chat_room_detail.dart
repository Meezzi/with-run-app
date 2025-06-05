import 'package:flutter/material.dart';
import 'package:with_run_app/core/utils/date_formatter.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';

class ChatRoomDetail extends StatelessWidget {
  const ChatRoomDetail(this.chatroom, {super.key});

  final ChatRoom chatroom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (chatroom.address != null) ...[
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  chatroom.address!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${formatRelativeDate(chatroom.createdAt)} 생성됨',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
