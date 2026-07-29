// 端末のファイル・サーバーのURL・Web の blob URL を同じように表示する。
import 'package:flutter/material.dart';

import '../data/file_io.dart' as io;
import 'placeholder_box.dart';

class MediaImage extends StatelessWidget {
  const MediaImage({
    super.key,
    required this.uri,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.fallbackLabel,
    this.fit = BoxFit.cover,
  });

  /// null なら縞のプレースホルダを出す
  final String? uri;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final String? fallbackLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (uri == null) {
      return PlaceholderBox(
        label: fallbackLabel,
        fontSize: 8,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image(
        image: io.imageProviderFor(uri!),
        width: width,
        height: height,
        fit: fit,
        // 読めなくなったメディア（削除された・オフライン）はプレースホルダに落とす
        errorBuilder: (_, _, _) =>
            PlaceholderBox(label: fallbackLabel, fontSize: 8, width: width, height: height),
      ),
    );
  }
}
