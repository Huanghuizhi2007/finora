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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        AppIcons.forKey(iconKey),
        color: color,
        size: size * 0.5,
      ),
    );
  }
}
