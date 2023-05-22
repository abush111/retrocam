import 'package:get/get.dart';
import 'package:camera/camera.dart';

class VideoController extends GetxController {
  CameraController? cameraController;
  RxBool isRecording = false.obs; // Define isRecording as a RxBool

  RxString recordedFilePath = ''.obs;
  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    CameraController? cameraController;

    cameraController = CameraController(firstCamera, ResolutionPreset.high);

    await cameraController!.initialize();
  }

  Future<void> startRecording() async {
    if (cameraController!.value.isRecordingVideo) {
      return; // Recording already in progress
    }

    final filePath =
        '/path/to/your/video.mp4'; // Set the desired file path for the recorded video
    await cameraController!.startVideoRecording();

    isRecording.value = true;
    recordedFilePath.value = filePath;
  }

  Future<void> stopRecording() async {
    if (!cameraController!.value.isRecordingVideo) {
      return; // No recording in progress
    }

    await cameraController!.stopVideoRecording();
    isRecording.value = false; // Update isRecording to false
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
