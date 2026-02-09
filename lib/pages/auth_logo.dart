import 'package:flutter/material.dart';

class AuthLogo extends StatelessWidget {
  final double size;

  const AuthLogo({super.key, this.size = 120.0});

  @override
  Widget build(BuildContext context) {
    const Color tealPrimary = Color(0xFF26A69A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: tealPrimary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.medical_services_rounded,
              size: 60,
              color: tealPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
