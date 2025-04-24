import 'package:flutter/material.dart';

class ChatCreatePage extends StatelessWidget {
  const ChatCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: Text('title')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: 1000),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [
                      InputElement('채팅방 이름', true, 1),
                      InputElement('일정', true, 1),
                      InputElement('설명', false, 5),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, 
                  child: Text('참가하기'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget InputElement(String name, bool isRequierd, int maxLines) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requiredInput(name, isRequierd), ),
          SizedBox(height: 8),
          TextFormField(
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String requiredInput(String name, bool isRequierd){
    return isRequierd ? '* $name' : name;
  }
}
