import 'package:flutter/material.dart';

class LoadingOverlay {
  OverlayEntry? _overlayEntry;

  void show(BuildContext context) {
    if (_overlayEntry != null) return; // 이미 띄워져 있으면 무시

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Container(color: Colors.black54),
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).highlightColor,
                ),
              ),
            ],
          ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
