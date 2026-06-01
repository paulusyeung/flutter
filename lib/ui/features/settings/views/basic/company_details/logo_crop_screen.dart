import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import 'package:admin/l10n/localization.dart';

/// Full-screen logo crop step shown between picking an image and uploading
/// it as the company logo (React parity: `LogoCropModal`; admin-portal used
/// the `image_cropper` package). `crop_your_image` is pure-Dart so it works
/// on every target incl. macOS desktop. Returns the cropped PNG bytes, or
/// null if the user cancelled.
Future<Uint8List?> showLogoCropScreen(BuildContext context, Uint8List source) {
  return Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _LogoCropScreen(source: source),
    ),
  );
}

class _LogoCropScreen extends StatefulWidget {
  const _LogoCropScreen({required this.source});

  final Uint8List source;

  @override
  State<_LogoCropScreen> createState() => _LogoCropScreenState();
}

class _LogoCropScreenState extends State<_LogoCropScreen> {
  final _controller = CropController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('crop')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.tr('cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _busy = true);
                    _controller.crop();
                  },
            child: Text(context.tr('done')),
          ),
        ],
      ),
      body: Crop(
        image: widget.source,
        controller: _controller,
        onCropped: (result) {
          if (!mounted) return;
          switch (result) {
            case CropSuccess(:final croppedImage):
              Navigator.of(context).pop(croppedImage);
            case CropFailure():
              setState(() => _busy = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('an_error_occurred'))),
              );
          }
        },
      ),
    );
  }
}
