import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
import 'package:with_run_app/ui/pages/my_info/my_info_page.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).highlightColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
              const Text(
                '위드런에 오신 것을 환영합니다',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  try {
                    // 현재 로그인된 사용자 확인
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null && currentUser.emailVerified) {
                      // 이미 로그인 상태이므로 사용자 정보 확인
                      final userDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser.uid)
                          .get();
                          
                      if (!context.mounted) return;
                          
                      if (userDoc.exists) {
                        // 이미 프로필 정보가 있는 경우 맵 페이지로 바로 이동
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MapPage()),
                        );
                        return;
                      } else {
                        // 프로필 정보가 없는 경우 프로필 설정 페이지로 이동
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyInfoPage(uid: currentUser.uid),
                          ),
                        );
                        return;
                      }
                    }
                
                    // 로그인되어 있지 않은 경우 로그인 진행
                    final credential = await signInWithGoogle();

                    // 로그인 성공 여부 확인
                    if (credential != null && credential.user != null) {
                      final user = credential.user!;
                      
                      // 이메일 인증 확인 
                      if (user.emailVerified) {
                        // 사용자 정보가 이미 있는지 확인
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();
                            
                        if (!context.mounted) return;
                            
                        if (userDoc.exists) {
                          // 이미 프로필 정보가 있는 경우 맵 페이지로 바로 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MapPage()),
                          );
                        } else {
                          // 프로필 정보가 없는 경우 프로필 설정 페이지로 이동
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyInfoPage(uid: user.uid),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이메일 인증이 필요합니다.')),
                          );
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint('로그인 과정 오류: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')),
                      );
                    }
                  }
                },
                child: SvgPicture.asset('assets/login_light.svg', height: 50),
              ),
            ],
          ),
        ),
      ),
    );
  }
}