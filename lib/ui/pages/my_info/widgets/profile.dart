import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/my_info/my_info_view_model.dart';

class Profile extends StatelessWidget {
  String? imageUrl;
  bool isImageValid;

  Profile(this.imageUrl, this.isImageValid);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(74),
              child: Container(
                width: 74,
                height: 74,
                color: Colors.grey[300],
                child:
                    imageUrl != null
                        ? Image.network(imageUrl as String, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 36),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                ),
                child: Icon(Icons.add_circle),
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '프로필 사진을 업로드 해주세요',
          style: TextStyle(
            fontSize: 13,
            color: isImageValid ? Color(0xffB3261E) : Colors.transparent,
          ),
        ),
      ],
    );
  }
}
