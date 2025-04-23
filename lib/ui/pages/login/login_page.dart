import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final deviceHeight = mq.size.height;
    final devicePaddingTop = mq.padding.top;
    final devicePaddingBottom = mq.padding.bottom;

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
                onTap: () {
                  print('구글 로그인');
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
