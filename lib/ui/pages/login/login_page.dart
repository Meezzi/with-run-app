import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/my_info/my_info_page.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).highlightColor,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
              Text(
                '위드런에 오신 것을 환영합니다',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  try {
                    final credential = await signInWithGoogle();
                    
                    // 로그인 성공 후 이메일 인증 확인
                    if (credential != null && (credential.user?.emailVerified ?? false)) {
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return MyInfoPage(uid: credential.user!.uid);
                            },
                          ),
                          (route) {
                            return route.isCurrent;
                          },
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
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
