import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageRepository {
  /// firestorage에 이미지 업로드
  Future<Map<String, String>?> uploadImage(XFile xFile) async {
    try {
      // firestorage 사용
      // 1. firestorage 객체 가지고 오기
      final storage = FirebaseStorage.instance;

      // 2. 스토리지 참조 만들기
      Reference ref = storage.ref();

      // 3. 파일 이름 만들어 참조하기
      String imageName =
          '${DateTime.now().microsecondsSinceEpoch}_${xFile.name}';
      Reference fileRef = ref.child('user/$imageName');

      // 4. 쓰기
      await fileRef.putFile(File(xFile.path));

      // 5. 파일에 접근할 수 있는 URL 받기
      return {
        'imageUrl': await fileRef.getDownloadURL(),
        'imageName': imageName,
      };
    } catch (e) {
      debugPrint('ImageRepository.uploadImage catch문 - $e');
      return null;
    }
  }

  /// firestorage에 있는 이미지 삭제
  Future<bool?> deleteImage(String imageName) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef = storageRef.child(imageName);

      await fileRef.delete();
      debugPrint('파일 삭제 완료');
      return true;
    } catch (e) {
      debugPrint('파일 삭제 실패');
      debugPrint('ImageRepository.deleteImage catch문 - $e');
      return null;
    }
  }
}