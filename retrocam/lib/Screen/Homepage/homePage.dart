import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:path/path.dart' as path;
import 'package:ionicons/ionicons.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:async';

class homePage extends StatefulWidget {
  final List<String> items;
  const homePage({required this.items, super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  TextEditingController _textEditingController = TextEditingController();
  double brightnessValue = 0.0;
  double contrast = 1.0;
  bool isfilter = true;
  Color _selectedColor = Colors.blue;
  double _fontSize = 20;
  String displayText = '';
  bool _isloading = true;
  String selectedItem = '';
  double grayscale = 0.0;
  File? _image;
  File? pngFile;
  File? filteriamge;
  GlobalKey _imageKey = GlobalKey();
  Uint8List? _filteredImageData;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  GlobalKey containerKey = GlobalKey();
  FocusNode _focusNode = FocusNode();

  // intialize camera
  List<CameraDescription>? cameras;
  CameraController? controller;
  Future<void> initCamera() async {
    cameras = await availableCameras();

    CameraDescription? selectedCamera;

    if (cameras!.isNotEmpty) {
      // Select the desired camera (e.g., front or back camera)
      selectedCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras![0],
      );
    }

    if (selectedCamera != null) {
      controller = CameraController(selectedCamera, ResolutionPreset.medium);
      await controller?.initialize();
    }
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
      final directory = await getTemporaryDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      pngFile = File.fromUri(Uri.file(path.join(directory.path, fileName)));

      await _image!.copy(pngFile!.path);
    } catch (e) {
      print("please capture iamge");
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
    double _imageWidth = 400.0; // Initial width of the filtered image
    double _imageHeight = 400.0; // Initial height of the filtered image

    print("${widget.items}");
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      backgroundColor: Color.fromRGBO(51, 51, 51, 1),
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          children: [
            isfilter
                ? Column(
                    children: [
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            margin:
                                EdgeInsets.only(top: 75, right: 14, bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  isfilter = false;
                                });
                              },
                              child: Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 23,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            right: height * 0.03,
                            left: height * 0.03,
                            bottom: height * 0.03),
                        child: RepaintBoundary(
                          key: containerKey,
                          child: Container(
                            height: 300,
                            width: 300,
                            color: Colors.white,
                            child: Stack(
                              children: [
                                Container(
                                  height: height * 0.24,
                                  margin: EdgeInsets.only(
                                      left: width * 0.06,
                                      top: height * 0.06,
                                      right: width * 0.06),
                                  child: filteriamge != null
                                      ? Image.file(
                                          filteriamge!,
                                          width: _imageWidth,
                                          height: _imageHeight,
                                        )
                                      : AspectRatio(
                                          aspectRatio:
                                              controller!.value.aspectRatio,
                                          child: CameraPreview(controller!),
                                        ),
                                ),
                                Positioned(
                                  top: height * 0.3,
                                  child: Container(
                                    margin: EdgeInsets.only(left: width * 0.09),
                                    height: height * 0.05,
                                    child: Row(
                                      children: [
                                        Text(
                                          "${_textEditingController.text}",
                                          style: TextStyle(
                                              color: _selectedColor,
                                              fontSize: ScreenUtil()
                                                  .setSp(_fontSize)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
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
                                    margin:
                                        EdgeInsets.only(left: width * 0.160),
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
                                    borderSide: BorderSide(
                                        width: 1, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
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
                                SizedBox(
                                  width: 15,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
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
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 10),
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
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 9),
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
                          height: height * 0.07,
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
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0.0),
                                  ),
                                ),
                                minimumSize:
                                    MaterialStateProperty.all(Size(50, 50)),
                                backgroundColor: MaterialStateProperty.all(
                                    Color.fromRGBO(217, 217, 217, 1))),
                          ),
                        ),
                      )
                    ],
                  )
                : Column(
                    children: [
                      SizedBox(
                        height: 60,
                      ),
                      Text('Contrast: ${contrast.toStringAsFixed(2)}'),
                      Slider(
                        value: contrast,
                        min: 0.0,
                        max: 2.0,
                        onChanged: (value) {
                          setState(() {
                            contrast = value;
                            updateFilteredImage();
                            applyFilteredImage();
                          });
                        },
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text('Brightness: ${brightnessValue.toStringAsFixed(2)}'),
                      Slider(
                        value: brightnessValue,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (newValue) {
                          setState(() {
                            brightnessValue = newValue;
                            updateFilteredImage();
                            applyFilteredImage();
                          });
                        },
                      ),
                      Text(
                        'Grayscale: ${grayscale.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 20.0),
                      Slider(
                        value: grayscale,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            grayscale = value;
                            updateFilteredImage();

                            applyFilteredImage();
                          });
                        },
                      ),
                      RepaintBoundary(
                        key: _imageKey,
                        child: SizedBox(
                          height: 200,
                          width: 200,
                          child: applyFilteredImage(),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: height * 0.3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                height: height * 0.05,
                                width: width * 0.2,
                                decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.3), // Shadow color
                                        blurRadius: 5, // Spread radius
                                        offset: Offset(0,
                                            3), // Offset in (x,y) coordinates
                                      ),
                                    ],
                                    color: Color.fromRGBO(236, 240, 243, 1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Color.fromRGBO(255, 255, 255,
                                          1), // Set the border color
                                      width: 2.5,
                                    )),
                                child: Center(
                                    child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            isfilter = true;
                                            if (_filteredImageData == null) {
                                              saveFilteredImage();
                                            }

                                            print(_filteredImageData);
                                          });
                                        },
                                        child: Text("Save")))),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                                height: height * 0.05,
                                width: width * 0.2,
                                decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.3), // Shadow color
                                        blurRadius: 5, // Spread radius
                                        offset: Offset(0,
                                            3), // Offset in (x,y) coordinates
                                      ),
                                    ],
                                    color: Color.fromRGBO(236, 240, 243, 1),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Color.fromRGBO(255, 255, 255,
                                          1), // Set the border color
                                      width: 2.5,
                                    )),
                                child: Center(child: Text("Cancel")))
                          ],
                        ),
                      )
                    ],
                  )
          ],
        ),
      ),
    );
  }

  Widget applyFilteredImage() {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(getFilterMatrix()),
      child: Image.file(pngFile!),
    );
  }

  List<double> getFilterMatrix() {
    return <double>[
      contrast,
      0,
      0,
      0,
      brightnessValue,
      0,
      contrast,
      0,
      0,
      brightnessValue,
      0,
      0,
      contrast,
      0,
      brightnessValue,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  void updateFilteredImage() {
    setState(() {
      _filteredImageData = null; // Reset the filtered image data
    });
  }

// save filter data
  Future<void> saveFilteredImage() async {
    RenderRepaintBoundary? boundary =
        _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/filtered_image.png';
        final File file = File(filePath);
        await File(filePath).writeAsBytes(pngBytes);
        setState(() {
          filteriamge = file;
        });
        print(filteriamge);

        // Show a success message or perform any other operations with the saved image file
        print('Filtered image saved at: $filePath');
      }
    }
  }
  // large image size
}
