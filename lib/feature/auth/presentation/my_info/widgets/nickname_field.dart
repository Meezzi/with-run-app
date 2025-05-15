import 'package:flutter/material.dart';

class NicknameField extends StatelessWidget {
  TextEditingController nicknameController;

  NicknameField(this.nicknameController, {super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: nicknameController,
      decoration: InputDecoration(
        hintText: '닉네임을 입력해 주세요',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).highlightColor),
          borderRadius: BorderRadius.circular(10),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return '닉네임을 입력해주세요';
        }

        return null;
      },
    );
  }
}
