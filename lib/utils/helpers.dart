import 'package:flutter/material.dart';

class AppHelpers {
  static String formatFileSize(double sizeInMB) {
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(0)} KB';
    } else if (sizeInMB < 1024) {
      return '${sizeInMB.toStringAsFixed(0)} MB';
    } else {
      return '${(sizeInMB / 1024).toStringAsFixed(1)} GB';
    }
  }

  static String formatDuration(String duration) {
    return duration;
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'downloaded':
        return const Color(0xFF84A98C);
      case 'downloading':
        return const Color(0xFF2F3E46);
      case 'available':
        return const Color(0xFF9AA5B1);
      default:
        return const Color(0xFF9AA5B1);
    }
  }
}
