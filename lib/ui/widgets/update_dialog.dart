import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../data/update_service.dart';

Future<bool?> showUpdateDialog(
  BuildContext context,
  UpdateInfo update,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('发现新版本'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Finora ${update.version} 已经发布',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          if (update.notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              update.notes,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('稍后'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('去下载'),
        ),
      ],
    ),
  );
}

Future<void> openUpdate(BuildContext context, UpdateInfo update) async {
  await launchUrl(
    Uri.parse(update.downloadUrl),
    mode: LaunchMode.externalApplication,
  );
}
