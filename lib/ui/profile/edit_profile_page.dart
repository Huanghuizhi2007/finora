import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/supabase_service.dart';
import '../../state/session_controller.dart';
import '../widgets/gradient_button.dart';
import '../widgets/user_avatar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nicknameController;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final session = context.read<SessionController>();
    final userId = session.user?.id;
    if (userId == null) return;

    String? uploaded;
    if (AppConfig.isSupabaseConfigured) {
      final bytes = await file.readAsBytes();
      final path =
          'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await SupabaseService.client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true),
          );
      uploaded =
          SupabaseService.client.storage.from('avatars').getPublicUrl(path);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final savedFile = File(
        '${directory.path}/avatar_${userId}_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await savedFile.writeAsBytes(await file.readAsBytes());
      uploaded = savedFile.path;
    }
    setState(() => _avatarUrl = uploaded);
  }

  Future<void> _save() async {
    final session = context.read<SessionController>();
    final error = await session.updateProfile(
      nickname: _nicknameController.text,
      avatarUrl: _avatarUrl,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: const Text('编辑资料')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: <Widget>[
          Center(
            child: InkWell(
              onTap: _pickAvatar,
              borderRadius: BorderRadius.circular(36),
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: UserAvatar(
                      nickname: _nicknameController.text,
                      avatarUrl: _avatarUrl,
                      size: 96,
                      fontSize: 34,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: const Icon(
                        Icons.photo_camera_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _nicknameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: '昵称',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: session.isLoading ? '保存中...' : '保存',
            icon: Icons.check_rounded,
            onPressed: session.isLoading ? null : _save,
          ),
        ],
      ),
    );
  }
}
