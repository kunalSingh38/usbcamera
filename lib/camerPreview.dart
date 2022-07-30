import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CamerPreview extends StatefulWidget {
  final CameraDescription camera;
  CamerPreview({required this.camera});
  @override
  _CamerPreviewState createState() => _CamerPreviewState();
}

class _CamerPreviewState extends State<CamerPreview> {
  late CameraController controller;
  bool isLoading = true;

  List<ResolutionPreset> res = [
    ResolutionPreset.high,
    ResolutionPreset.low,
    ResolutionPreset.max,
    ResolutionPreset.medium,
    ResolutionPreset.ultraHigh,
    ResolutionPreset.veryHigh
  ];
  void cam() async {
    controller = CameraController(widget.camera, ResolutionPreset.high
        // enableAudio: true,
        );
    await controller.initialize();
    print(controller.value.isInitialized);

    // controller.addListener(() {
    //   if (controller.value.hasError) {
    //     print('Camera Error: ${controller.value.errorDescription}');
    //   }
    // });
    setState(() {
      isLoading = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      cam();
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    cam();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(height: 300, width: 300, child: CameraPreview(controller)),
    );
  }
}
