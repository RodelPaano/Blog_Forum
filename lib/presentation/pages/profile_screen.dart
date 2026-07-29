import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_diallog.dart';
import '../widgets/app_button_type.dart';
import '../widgets/mobile_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _avatarFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<AuthProvider>().profile;
    if (profile != null && _nameController.text != profile.fullName) {
      _nameController.text = profile.fullName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _handlePickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _handleDiscardNewPhoto() async {
    setState(() => _avatarFile = null);
  }

  Future<void> _handleRemoveAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final removed = await authProvider.removeAvatar();
    if (!mounted) return;

    if (removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } else if (authProvider.error != null) {
      AppDialog.showError(context, authProvider.error!);
    }
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      fullName: _nameController.text.trim(),
      avatarFile: _avatarFile,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _avatarFile = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } else {
      final err = authProvider.error ?? 'Update failed';
      AppDialog.showError(context, err);
    }
  }

  Future<void> _handleSignOut() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    context.go('/');
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final cs = Theme.of(context).colorScheme;

    final ImageProvider? preview = _avatarFile != null
        ? FileImage(_avatarFile!)
        : (profile?.avatarUrl != null
              ? CachedNetworkImageProvider(profile!.avatarUrl!)
              : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: MobilePage(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              if (profile != null)
                Text(
                  profile.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.primaryContainer,
                      backgroundImage: preview,
                      child: preview == null
                          ? Text(
                              (profile?.fullName ?? '?').characters.first
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                color: cs.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton.small(
                        heroTag: 'avatar_pick',
                        onPressed: _handlePickAvatar,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_avatarFile != null)
                TextButton.icon(
                  onPressed: _handleDiscardNewPhoto,
                  icon: const Icon(Icons.close),
                  label: const Text('Discard new photo'),
                )
              else if (profile?.avatarUrl != null)
                TextButton.icon(
                  onPressed: _handleRemoveAvatar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined),
                title: Text(profile?.email ?? ''),
                subtitle: const Text('Email cannot be changed'),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Changes',
                isLoading: auth.isBusy,
                onPressed: _handleSaveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
