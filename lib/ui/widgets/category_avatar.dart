import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.iconKey,
    required this.colorValue,
    this.size = 44,
  });

  final String iconKey;
  final int colorValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            color.withOpacity(0.9),
            color.withOpacity(0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        AppIcons.forKey(iconKey),
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
