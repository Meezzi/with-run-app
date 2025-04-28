import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 아이콘 버튼
Widget iconButton(String assetPath, Color color) {
  return IconButton(
    icon: ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: SvgPicture.asset(assetPath),
    ),
    onPressed: () {
      print('$assetPath 클릭됨');
    },
  );
}