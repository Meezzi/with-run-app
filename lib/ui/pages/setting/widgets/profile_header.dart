import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(color: Colors.pink[100]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 100),
          CircleAvatar(
            backgroundImage: NetworkImage('https://picsum.photos/200'),
            radius: 48,
            backgroundColor: Colors.blue[100],
          ),
          SizedBox(height: 8),
          Text("김닉네임", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("아이디", style: TextStyle(fontSize: 16, color: Colors.grey[800])),
          Text("asdf@gmail.com", style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
