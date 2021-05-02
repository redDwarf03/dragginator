// @dart=2.9
import 'package:flutter/material.dart';

class Avatar {
  List<Color> avatarBackground = [
    Color(0xFFbeb4d3),
    Color(0xFFfa8800),
    Color(0xFF034e5e),
    Color(0xFF000000),
    Color(0xFF889c94),
    Color(0xFF5ac18e),
    Color(0xFFd1a343),
    Color(0xFF366f6b),
    Color(0xFFdf7696),
    Color(0xFF831919),
    Color(0xFF8C379F)
  ];

  Color getBackgroundColor(int index) {
    if (index > 10) {
      return Color(0xFF8C379F);
    } else {
      return avatarBackground[index];
    }
  }
}
