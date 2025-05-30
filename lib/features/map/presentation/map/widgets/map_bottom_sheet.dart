import 'package:flutter/material.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';

class MapBottomSheet extends StatelessWidget {
  final ChatRoom chatroom;

  const MapBottomSheet(this.chatroom, {super.key});
  @override
  Widget build(Object context) {
    return Container(
      height: 300,
      width: double.infinity,
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 50),
      child: Row(
        children: [
          // Image.network(book.image, fit: BoxFit.fitHeight),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatroom.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  chatroom.description!,
                  style: TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
