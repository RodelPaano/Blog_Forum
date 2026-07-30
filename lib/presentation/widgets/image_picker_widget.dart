import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config.dart';

class ImagePickerWidget extends StatelessWidget {
  const ImagePickerWidget({
    super.key,
    required this.files,
    this.existingUrls = const [],
    required this.onPick,
    this.onRemoveExisting,
    required this.onRemoveNew,
    this.maxImages = AppConfig.maxImagesPerPost,
  });

  final List<File> files;
  final List<String> existingUrls;
  final VoidCallback onPick;
  final void Function(int index)? onRemoveExisting;
  final void Function(int index) onRemoveNew;
  final int maxImages;

  int get _total => existingUrls.length + files.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images (${_total.clamp(0, maxImages)}/$maxImages)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < existingUrls.length; i++)
                _Thumb(
                  imageProvider: NetworkImage(existingUrls[i]),
                  onRemove: () => onRemoveExisting?.call(i),
                ),
              for (var i = 0; i < files.length; i++)
                _Thumb(
                  imageProvider: kIsWeb 
                      ? NetworkImage(files[i].path) as ImageProvider
                      : FileImage(files[i]),
                  onRemove: () => onRemoveNew(i),
                ),
              if (_total < maxImages)
                GestureDetector(
                  onTap: onPick,
                  child: Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: cs.primary,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageProvider, required this.onRemove});
  final ImageProvider imageProvider;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 12,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
