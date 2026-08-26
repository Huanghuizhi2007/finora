import 'dart:convert';

import 'package:http/http.dart' as http;

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.notes = '',
  });

  final String version;
  final String downloadUrl;
  final String notes;
}

class UpdateService {
  UpdateService._();

  static const String _latestUrl =
      'https://api.github.com/repos/Huanghuizhi2007/finora/releases/latest';

  static Future<UpdateInfo?> checkLatest() async {
    try {
      final response = await http
          .get(
            Uri.parse(_latestUrl),
            headers: const <String, String>{
              'User-Agent': 'Finora',
              'Accept': 'application/vnd.github+json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
      final assets = json['assets'] as List<dynamic>? ?? <dynamic>[];
      String? downloadUrl;
      for (final asset in assets) {
        final map = asset as Map<String, dynamic>;
        final name = map['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          downloadUrl = map['browser_download_url'] as String?;
          break;
        }
      }
      if (tag.isEmpty || downloadUrl == null) return null;
      return UpdateInfo(
        version: tag,
        downloadUrl: downloadUrl,
        notes: json['body'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static bool isNewer(String latest, String current) {
    final latestParts = _parts(latest);
    final currentParts = _parts(current);
    final length =
        latestParts.length > currentParts.length
            ? latestParts.length
            : currentParts.length;
    for (var i = 0; i < length; i++) {
      final latestValue = i < latestParts.length ? latestParts[i] : 0;
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      if (latestValue > currentValue) return true;
      if (latestValue < currentValue) return false;
    }
    return false;
  }

  static List<int> _parts(String version) {
    return version
        .trim()
        .split('.')
        .map((part) => int.tryParse(part.replaceAll(RegExp('[^0-9]'), '')) ?? 0)
        .toList();
  }
}
