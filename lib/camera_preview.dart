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

  final Size _scanSize = const Size(320, 200);
  late Rect _currentScanRegion;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() async {
    final camera = (await availableCameras())[0];
    final controller = CameraController(
      camera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
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
    final previewSize = _controller!.value.previewSize!;
    final screenSize = MediaQuery.of(context).size;
    debugPrint(
        "previewSize: $previewSize (${previewSize.aspectRatio}) screenSize: $screenSize  (${screenSize.aspectRatio})");

    final scale = (screenSize.aspectRatio >= 1)
        ? screenSize.width / previewSize.width
        : screenSize.height / previewSize.height;

    final scaledPreviewSize =
        Size(previewSize.width * scale, previewSize.height * scale);
    debugPrint(
        "scale: $scale scaledPreviewSize: $scaledPreviewSize (${scaledPreviewSize.aspectRatio})");

    final scanRegion = Rect.fromCenter(
      center: previewSize.center(Offset.zero),
      width: _scanSize.width / scale,
      height: _scanSize.height / scale,
    );
    _currentScanRegion = Rect.fromLTRB(
        scanRegion.left.floorToDouble(),
        scanRegion.top.floorToDouble(),
        scanRegion.right.ceilToDouble(),
        scanRegion.bottom.ceilToDouble());

    debugPrint("scanRegion: $scanRegion ($_currentScanRegion)");

    return WillPopScope(
      onWillPop: () async {
        await _controller?.stopImageStream();
        Navigator.pop(context, _frameCount.toString());
        return false;
      },
      child: Scaffold(
        body: SizedBox(
          height: screenSize.height,
          width: screenSize.width,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: scaledPreviewSize.height,
                width: scaledPreviewSize.width,
                child: CameraPreview(_controller!),
              ),
              Container(
                width: _scanSize.width,
                height: _scanSize.height,
                decoration: BoxDecoration(
                    border: Border.all(
                  color: Colors.red,
                  width: 2,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
