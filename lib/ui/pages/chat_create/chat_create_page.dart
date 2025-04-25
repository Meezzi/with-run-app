import 'package:flutter/material.dart';

class ChatCreatePage extends StatelessWidget {
  const ChatCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(centerTitle: true, title: Text('채팅방 만들기')),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                constraints: BoxConstraints(maxHeight: 1000),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      inputElement(name: '장소', readOnly: true),
                      inputElement(name: '채팅방 이름', isRequired: true),
                      inputElement(name: '일정', isRequired: true),
                      inputElement(name: '설명', maxLines: 5),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {}, 
                  child: Text('채팅방 만들기'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget inputElement({required String name, bool isRequired = false, int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requiredInput(name, isRequired), ),
          SizedBox(height: 8),
          TextFormField(
            readOnly: readOnly,
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

  
  String requiredInput(String name, bool isRequired){
    return isRequired ? '* $name' : name;
  }
}
