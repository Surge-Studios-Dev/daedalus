import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Render [card] offscreen and capture it as base64 PNG bytes.
///
/// The card is mounted in the root overlay far offstage inside a
/// [RepaintBoundary], pumped for a few frames so images resolve (callers
/// should [precacheShareImage] every image the card draws — INCLUDING
/// bundled assets — so the first frame already has pixels), captured at
/// [pixelRatio], then removed.
///
/// [exportTheme] is forced on the subtree: pass the app's light-token
/// theme — an exported card must not vary with the sender's theme.
///
/// Capture BEFORE the share sheet opens: the Android activity pauses under
/// the system sheet and frame-driven capture stalls there.
///
/// Returns null on any failure — the share flow degrades to link-only
/// rather than blocking the user on a rendering hiccup.
Future<String?> captureShareCardPng(
  BuildContext context,
  Widget card, {
  Size logicalSize = const Size(360, 360),
  double pixelRatio = 3,
  ThemeData? exportTheme,
}) async {
  final overlayState = Overlay.maybeOf(context, rootOverlay: true);
  if (overlayState == null) return null;
  final theme = exportTheme ?? Theme.of(context);
  final boundaryKey = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -logicalSize.width * 4,
      top: 0,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: theme,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox.fromSize(size: logicalSize, child: card),
            ),
          ),
        ),
      ),
    ),
  );
  overlayState.insert(entry);
  try {
    // Three frames: mount, image paint, settle. Precached images resolve
    // synchronously from the cache on the first paint.
    for (var i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      // Encoding ~1-2MB of PNG to base64 on the UI isolate would land a
      // visible stutter exactly while the share sheet animates open.
      return await compute(
        base64Encode,
        bytes.buffer.asUint8List(0, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    entry.remove();
  }
}

/// One provider instance per image string, shared between the precache and
/// the card's Image widget. Identity matters twice over:
///  * NetworkImage compares by url, but MemoryImage compares by BYTES
///    IDENTITY — two decodes of the same data: URI are different cache
///    keys, so without the memo a precached data-URI image would still
///    decode from scratch inside the offscreen card and the capture would
///    fire first (the recurring white-panel bug).
///  * data: URIs get decoded exactly once instead of per card render.
final _providerMemo = <String, ImageProvider>{};

ImageProvider? shareImageProvider(String image) {
  if (image.isEmpty) return null;
  final memoized = _providerMemo[image];
  if (memoized != null) return memoized;
  ImageProvider? provider;
  if (image.startsWith('data:image')) {
    final comma = image.indexOf(',');
    if (comma != -1) {
      try {
        provider = MemoryImage(base64Decode(image.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
  } else if (image.startsWith('http')) {
    provider = NetworkImage(image);
  }
  if (provider != null) {
    // Bounded memo: a share flow touches at most a few images; this only
    // needs to survive one precache->capture round trip.
    if (_providerMemo.length > 16) _providerMemo.clear();
    _providerMemo[image] = provider;
  }
  return provider;
}

/// Warm a card image (any source type) before capture, so the offscreen
/// card's first frame reads pixels straight from the image cache. Bounded
/// so a dead CDN can't stall the share sheet — on timeout the card falls
/// back to its placeholder.
Future<void> precacheShareImage(
  BuildContext context,
  String image, {
  Duration timeout = const Duration(seconds: 4),
}) async {
  final provider = shareImageProvider(image);
  if (provider == null) return;
  try {
    await precacheImage(provider, context).timeout(timeout);
  } catch (e) {
    debugPrint('share card image warm-up failed (placeholder card): $e');
  }
}
