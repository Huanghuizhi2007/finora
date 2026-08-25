import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.text = '加载中...'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
