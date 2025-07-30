import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Widget qui affiche un indicateur de progression adapté à la plateforme
/// - CircularProgressIndicator sur Android
/// - CupertinoActivityIndicator sur iOS
class PlatformProgressIndicator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;

  const PlatformProgressIndicator({
    super.key,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        color: color ?? CupertinoColors.systemBlue,
      );
    } else {
      return CircularProgressIndicator(
        color: color,
        strokeWidth: strokeWidth ?? 4.0,
      );
    }
  }
}
