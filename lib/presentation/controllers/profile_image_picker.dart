import 'dart:io';

import 'package:image_picker/image_picker.dart';

abstract class ProfileImagePicker {
  Future<File?> pickAvatar();
}

class ImagePickerProfileImagePicker implements ProfileImagePicker {
  ImagePickerProfileImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<File?> pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );

    return picked == null ? null : File(picked.path);
  }
}
