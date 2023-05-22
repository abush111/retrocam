import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import '../../Controller/video_controller.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  TextEditingController _textEditingController = TextEditingController();
  Color _selectedColor = Colors.blue;
  double _fontSize = 20;
  String displayText = '';
  bool _isloading = true;
  File? _image;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey containerKey = GlobalKey();
  FocusNode _focusNode = FocusNode();

  // intialize camera
  List<CameraDescription>? cameras;
  CameraController? controller;
  Future<void> initCamera() async {
    cameras = await availableCameras();
    final CameraController controller = CameraController(
      cameras![0], // Use the first camera in the list
      ResolutionPreset.high, // Adjust the resolution as needed
    );
    await controller.initialize();
  }

  // increase font size
  void _increaseFontSize() {
    setState(() {
      _fontSize += 2.0;
    });
  }

// decrease font size
  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 2.0) {
        _fontSize -= 2.0;
      }
    });
  }

// color picker funcation
  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            InkWell(
              child: Text('OK'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

// capture image
  void capturePhoto() async {
    if (!controller!.value.isInitialized) {
      return;
    }

    try {
      final XFile capturedImage = await controller!.takePicture();
      setState(() {
        _image = File(capturedImage.path);
      });
      // _image = File(capturedImage.path);
      // Handle the captured image file (e.g., save it, display it, etc.)
      // setState(() {
      //
      // });
    } catch (e) {
      // Handle the error
    }
  }

  Future<void> _captureScreenshotAndShare() async {
    RenderRepaintBoundary boundary = containerKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final imagePath = '${tempDir.path}/screenshot.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(pngBytes);
    print(imagePath);
    try {
      await FlutterShare.shareFile(
        title: 'Share Image',
        text: 'Sharing an image',
        filePath: imagePath,
      );
    } catch (e) {
      print('Error sharing image: $e');
    }

    // await FlutterShare.shareFile(
    //   title: 'Share Screenshot',
    //   text: 'Share the screenshot via...',
    //   filePath: imagePath,
    // );
  }

  Offset _getSharePosition() {
    final RenderBox containerBox =
        _scaffoldKey.currentContext!.findRenderObject() as RenderBox;
    final containerPosition = containerBox.localToGlobal(Offset.zero);
    return containerPosition;
  }

  @override
  void initState() {
    super.initState();

    initCamera().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        controller = CameraController(
          cameras![0],
          ResolutionPreset.high,
        );
        controller!.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
      });
    });
    // Initialize camera
  }

  // final VideoController _videocontroller = Get.put(VideoController());
  void dispose() {
    _textEditingController.dispose();
    controller!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.height;
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      backgroundColor: Color.fromRGBO(51, 51, 51, 1),
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(
                  top: height * 0.03,
                  right: height * 0.03,
                  left: height * 0.03,
                  bottom: height * 0.03),
              child: RepaintBoundary(
                key: containerKey,
                child: Container(
                  margin: EdgeInsets.only(top: height * 0.05),
                  height: height * 0.5,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Container(
                        height: height * 0.24,
                        margin: EdgeInsets.only(
                            left: width * 0.06,
                            top: height * 0.06,
                            right: width * 0.06),
                        child: _image != null
                            ? Image.file(_image!)
                            : AspectRatio(
                                aspectRatio: controller!.value.aspectRatio,
                                child: CameraPreview(controller!),
                              ),
                      ),
                      Positioned(
                        top: height * 0.34,
                        child: Container(
                          margin: EdgeInsets.only(left: width * 0.06),
                          height: height * 0.05,
                          child: Row(
                            children: [
                              Text(
                                "${_textEditingController.text}",
                                style: TextStyle(
                                    color: _selectedColor,
                                    fontSize: ScreenUtil().setSp(_fontSize)),
                              ),
                              // Align(
                              //   alignment: Alignment.topCenter,
                              //   child: AdmobBanner(
                              //     adUnitId:
                              //         'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx',
                              //     adSize: AdmobBannerSize.BANNER,
                              //   ),
                              // )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Container(
            //   width: width * 0.04,
            //   child: Visibility(
            //     visible: _videocontroller!.isRecording.value,
            //     child: IconButton(
            //       onPressed: () {
            //         // Handle stop functionality
            //       },
            //       icon: Icon(Ionicons.stop),
            //     ),
            //   ),
            // ),
            Container(
              height: height * 0.32,
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: width * 0.03),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          child: Icon(
                            Icons.video_library,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Container(
                          margin: EdgeInsets.only(left: width * 0.160),
                          child: IconButton(
                            onPressed: () {
                              WidgetsBinding.instance
                                  ?.addPostFrameCallback((_) {
                                _captureScreenshotAndShare();
                              });
                            },
                            icon: Icon(
                              Ionicons.share,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          Ionicons.download,
                          color: Colors.white,
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                        top: height * 0.03,
                        right: height * 0.03,
                        left: height * 0.03,
                        bottom: height * 0.03),
                    width: width - 50,
                    height: height * 0.12,
                    child: TextField(
                      controller: _textEditingController,
                      maxLines: 1,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        filled: true,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromRGBO(71, 71, 71, 1),
                          ),
                        ),
                        fillColor: Color.fromRGBO(71, 71, 71, 1),
                        border: OutlineInputBorder(
                            // borderSide: BorderSide(
                            //   color: Colors.white,
                            //   width: 0.3,
                            // ),
                            ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(width: 1, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: width * 0.08,
                        height: height * 0.08,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                          shape: BoxShape.circle,
                          color: Colors.grey.shade700,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipOval(
                            child: Container(
                              width: width * 0.06,
                              height: height * 0.06,
                              color: Colors.white,
                              child: IconButton(
                                icon: Icon(
                                  Ionicons.videocam,
                                  color: Colors.grey,
                                ),
                                onPressed: () async {
                                  // if (!_videocontroller
                                  //     .cameraController!.value.isInitialized) {
                                  //   await _videocontroller.initializeCamera();
                                  // } else {
                                  //   final filePath =
                                  //       '/path/to/your/video.mp4'; // Set the desired file path for the recorded video
                                  //   await _videocontroller.startRecording();
                                  // }
                                  setState(() {
                                    _isloading = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Container(
                        width: width * 0.08,
                        height: height * 0.08,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                          shape: BoxShape.circle,
                          color: Colors.grey.shade700,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SizedBox(
                            width: width * 0.06,
                            height: height * 0.06,
                            child: Tooltip(
                                message: 'Take photo,',
                                child: ClipOval(
                                  child: Container(
                                    width: width * 0.04,
                                    height: height * 0.04,
                                    color: Colors.white,
                                    child: IconButton(
                                      onPressed: () {
                                        capturePhoto();
                                      },
                                      icon: Icon(
                                        Ionicons.camera,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                )),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      SizedBox(
                        width: width * 0.065,
                        child: MaterialButton(
                          color: Color.fromRGBO(71, 71, 71, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          onPressed: _increaseFontSize,
                          child: Text(
                            'A+',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Container(
                        width: width * 0.06,
                        child: MaterialButton(
                          color: Color.fromRGBO(71, 71, 71, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          onPressed: _decreaseFontSize,
                          child: Text(
                            'A-',
                            style: TextStyle(color: Colors.white, fontSize: 9),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Container(
                        width: width * 0.09,
                        child: MaterialButton(
                          color: Color.fromRGBO(0, 87, 255, 1),
                          shape: CircleBorder(
                              // borderRadius: BorderRadius.circular(10.0),
                              ),
                          onPressed: _openColorPicker,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: height * 0.08,
                // margin: EdgeInsets.only(top: height * 0.04),
                width: width,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      displayText = _textEditingController
                          .text; // Update the display text here
                    });
                  },
                  child: Text(
                    "Banner Add",
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all(Size(50, 50)),
                      backgroundColor: MaterialStateProperty.all(
                          Color.fromRGBO(217, 217, 217, 1))),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
