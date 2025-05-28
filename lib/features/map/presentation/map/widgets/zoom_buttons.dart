import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class ZoomButtons extends StatelessWidget {
  final NaverMapController? mapController;

  const ZoomButtons({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        children: [
          _zoomButton(
            icon: Icons.add,
            onPressed: () async {
              final cameraUpdate = NCameraUpdate.zoomIn();
              await mapController?.updateCamera(cameraUpdate);
            },
          ),
          SizedBox(height: 10),
          _zoomButton(
            icon: Icons.remove,
            onPressed: () async {
              final cameraUpdate = NCameraUpdate.zoomOut();
              await mapController?.updateCamera(cameraUpdate);
            },
          ),
        ],
      ),
    );
  }

  Widget _zoomButton({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox.square(
      dimension: 34,
      child: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        foregroundColor: Color(0xff636363),
        backgroundColor: Colors.white,
        onPressed: onPressed,
        child: Icon(icon),
      ),
    );
  }
}
