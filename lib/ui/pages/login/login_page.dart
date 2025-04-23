import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:with_run_app/core/google_sign_in_helper.dart';
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
                  final credential = await signInWithGoogle();

                  if (credential.user?.emailVerified ?? false) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return MyInfoPage();
                        },
                      ),
                    );
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
