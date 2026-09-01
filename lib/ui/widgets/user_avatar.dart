import 'dart:io';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.nickname,
    this.avatarUrl,
    this.size = 48,
    this.fontSize = 20,
  });

  final String nickname;
  final String? avatarUrl;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      final image = url.startsWith('http')
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(context),
            )
          : Image.file(
              File(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(context),
            );
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: image,
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          nickname.isEmpty ? 'F' : nickname.substring(0, 1),
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
