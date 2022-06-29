import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewPage extends StatefulWidget {
  /// Default Constructor
  const CameraPreviewPage({Key? key}) : super(key: key);

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  CameraController? _controller;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    final controller = CameraController(
      (await availableCameras())[0],
      ResolutionPreset.low,
    );

    try {
      await controller.initialize();
    } catch (e) {
      debugPrint('exception $e');
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            debugPrint('User denied camera access.');
            break;
          default:
            debugPrint('Handle other errors.');
            break;
        }
      }
    }
    await controller.startImageStream((image) {
      _frameCount++;
    });

    if (!mounted) {
      return;
    }

    setState(() {
      _controller = controller;
    });
  }

  @override
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }
    return WillPopScope(
      onWillPop: () async {
        await _controller?.stopImageStream();
        Navigator.pop(context, _frameCount.toString());
        return false;
      },
      child: MaterialApp(
        home: CameraPreview(_controller!),
      ),
    );
  }
}
