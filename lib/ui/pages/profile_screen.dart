import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _picker = ImagePicker();
  File? _avatar;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    // optional: mark dirty if needed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = context.read<AuthProvider>().profile;
    if (p != null && _name.text != p.fullName) {
      _name.text = p.fullName;
    }
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (x != null) setState(() => _avatar = File(x.path));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().updateProfile(
      fullName: _name.text.trim(),
      avatarFile: _avatar,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _avatar = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      final err = context.read<AuthProvider>().error ?? 'Update failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _removeAvatar() async {
    final ok = await showDialog<bool>(
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
    if (ok != true) return;
    if (!mounted) return;
    final removed = await context.read<AuthProvider>().removeAvatar();
    if (!mounted) return;
    if (removed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final cs = Theme.of(context).colorScheme;
    final ImageProvider? preview = _avatar != null
        ? FileImage(_avatar!)
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
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
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
                        onPressed: _pickAvatar,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_avatar != null)
                TextButton.icon(
                  onPressed: () => setState(() => _avatar = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Discard new photo'),
                )
              else if (profile?.avatarUrl != null)
                TextButton.icon(
                  onPressed: _removeAvatar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove photo'),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
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
              FilledButton(
                onPressed: auth.isBusy ? null : _save,
                child: auth.isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}