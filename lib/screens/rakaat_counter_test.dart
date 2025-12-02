// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
// import 'package:permission_handler/permission_handler.dart';

// class RakaatCounterTest extends StatefulWidget {
//   const RakaatCounterTest({super.key});

//   @override
//   State<RakaatCounterTest> createState() => _RakaatCounterTestState();
// }

// class _RakaatCounterTestState extends State<RakaatCounterTest> {
//   CameraController? _camera;
//   late ImageLabeler _labeler;
//   bool _isProcessing = false;
//   String _labels = "Waiting for detection...";
//   late List<CameraDescription> _cameras;
//   int _cameraIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _labeler = ImageLabeler(
//       options: ImageLabelerOptions(confidenceThreshold: 0.5),
//     );
//     _initCamera();
//   }

//   Future<void> _initCamera() async {
//     if (!await Permission.camera.request().isGranted) return;

//     _cameras = await availableCameras();
//     _startCamera();
//   }

//   Future<void> _startCamera() async {
//     _camera = CameraController(_cameras[_cameraIndex], ResolutionPreset.medium);
//     await _camera!.initialize();
//     setState(() {});
//     _camera!.startImageStream(_processCameraImage);
//   }

//   Future<void> _switchCamera() async {
//     if (_cameras.length < 2) return;

//     _cameraIndex = (_cameraIndex + 1) % _cameras.length;
//     await _camera?.stopImageStream();
//     await _camera?.dispose();
//     _startCamera();
//   }

//   Future<void> _processCameraImage(CameraImage image) async {
//     if (_isProcessing) return;
//     _isProcessing = true;

//     try {
//       // Convert to Uint8List
//       final bytes = image.planes.fold<Uint8List>(
//         Uint8List(0),
//         (previous, plane) => Uint8List.fromList([...previous, ...plane.bytes]),
//       );

//       final inputImage = InputImage.fromBytes(
//         bytes: bytes,
//         metadata: InputImageMetadata(
//           size: Size(image.width.toDouble(), image.height.toDouble()),
//           rotation: InputImageRotation.rotation0deg,
//           format: InputImageFormat.nv21,
//           bytesPerRow: image.planes.first.bytesPerRow,
//         ),
//       );

//       final labels = await _labeler.processImage(inputImage);

//       setState(() {
//         _labels = labels
//             .map(
//               (e) => "${e.label} (${(e.confidence * 100).toStringAsFixed(0)}%)",
//             )
//             .join("\n");
//       });
//     } catch (e) {
//       setState(() => _labels = "Error: $e");
//     }

//     _isProcessing = false;
//   }

//   @override
//   void dispose() {
//     _camera?.dispose();
//     _labeler.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("ML Kit Image Labeling"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.cameraswitch),
//             onPressed: _switchCamera,
//           ),
//         ],
//       ),
//       body: _camera?.value.isInitialized ?? false
//           ? Stack(
//               children: [
//                 CameraPreview(_camera!),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Container(
//                     color: Colors.black54,
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(12),
//                     child: Text(
//                       _labels,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontFamily: 'monospace',
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             )
//           : const Center(child: CircularProgressIndicator()),
//     );
//   }
// }
