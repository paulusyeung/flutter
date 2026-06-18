// Generates windows/runner/resources/app_icon.ico from the 1024x1024 macOS
// app-icon source, as a multi-size .ico (16..256) so Windows has crisp icons at
// every UI scale (taskbar, Alt-Tab, Explorer, title bar).
//
//   dart run tools/gen_windows_icon.dart
//
// The source is full-bleed square — the correct shape for a Windows icon. Do NOT
// swap in assets/images/icon.png: it's circular (a mask is baked in) and only
// 152px, which would look wrong and soft on Windows.
//
// Uses the `image` package's IcoEncoder.encodeImages, which writes one ICO
// directory entry per supplied image (each keeps its own width/height) — unlike
// the top-level encodeIco() helper, which only emits a single size.

import 'dart:io';

import 'package:image/image.dart';

const _source = 'macos/AppIcon.icon/Assets/Image.png';
const _output = 'windows/runner/resources/app_icon.ico';
const _sizes = [16, 24, 32, 48, 64, 128, 256];

void main() {
  final src = decodePng(File(_source).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode $_source');
    exit(1);
  }
  final frames = [
    for (final size in _sizes)
      copyResize(
        src,
        width: size,
        height: size,
        interpolation: Interpolation.average,
      ),
  ];
  File(_output).writeAsBytesSync(IcoEncoder().encodeImages(frames));
  stdout.writeln('Wrote $_output (${_sizes.length} sizes: $_sizes)');
}
