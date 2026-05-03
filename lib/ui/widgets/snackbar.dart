// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum SanckBarSize { BIG, MEDIUM, SMALL }

SnackBar snackbar(BuildContext context, String text,
    {SanckBarSize size = SanckBarSize.MEDIUM,
    Duration duration = const Duration(seconds: 1),
    bool top = false}) {
  final scrWidth = MediaQuery.of(context).size.width;
  final hrMargin = size == SanckBarSize.BIG
      ? (scrWidth - 300) / 2
      : size == SanckBarSize.MEDIUM
          ? (scrWidth - 200) / 2
          : (scrWidth - 100) / 2;
  return SnackBar(
    backgroundColor: Theme.of(context).colorScheme.secondary,
    content: Center(
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white),
      ),
    ),
    //width: width,

    margin: EdgeInsets.only(
        bottom: top ? MediaQuery.of(context).size.height * 0.8 : 100,
        left: hrMargin,
        right: hrMargin),
    behavior: SnackBarBehavior.floating,
    duration: duration,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
}

void showCustomSnackbar({
  required String title,
  required String message,
  bool isError = false,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: isError ? Colors.red.withValues(alpha: 0.9) : Colors.green.withValues(alpha: 0.9),
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    duration: const Duration(seconds: 3),
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.white,
    ),
  );
}
