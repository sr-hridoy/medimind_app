import 'package:flutter/material.dart';

class MedicineUtils {
  static Widget getMedicineIcon(String? type, {double size = 48}) {
    String assetPath;
    String t = (type ?? 'tablet').toLowerCase();

    if (t == "syrup") {
      assetPath = 'assets/icon/syrup_icon.png';
    } else if (t == "injection" || t == "syringe") {
      assetPath = 'assets/icon/injection_icon.png';
    } else if (t == "tablet" || t == "capsule") {
      assetPath = 'assets/icon/tablet_icon.png';
    } else {
      assetPath = 'assets/icon/default_icon.png';
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2F1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            t == "syrup"
                ? Icons.local_drink
                : t == "injection"
                ? Icons.vaccines
                : Icons.medication,
            size: size * 0.6,
            color: const Color(0xFF26A69A),
          ),
        ),
      ),
    );
  }
}
