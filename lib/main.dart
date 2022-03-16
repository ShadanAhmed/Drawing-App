import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:drawing_app/custom_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_html/html.dart' as html;

import 'components/color_item.dart';
import 'components/option_menu_item.dart';
import 'drawing_painter.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(const MyApp());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  List<CustomPath> drawingPaths = [];
  CustomPath? currentPath;
  List<CustomPath> removedPath = [];
  Color color = Colors.black;
  Color backgroundColor = const Color(0xFFFFF7AB);
  double brushSize = 10.0;
  PaintingStyle brushStyle = PaintingStyle.stroke;
  String currentSelectedColor = "drawing";
  PictureRecorder recorder = PictureRecorder();
  bool isCleared = false;
  double prevX = 0;
  double prevY = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Drawing App"),
        actions: [
          IconButton(
            onPressed: () async {
              if (!kIsWeb) {
                if (await Permission.storage.status.isDenied) {
                  final status = await Permission.storage.request();
                  if (status.isGranted) {
                    final id = const Uuid().v4();
                    final bytes = await convertCanvasToImage();
                    final result = await ImageGallerySaver.saveImage(
                        Uint8List.fromList(bytes!.buffer.asUint8List()),
                        quality: 60,
                        name: id);

                    if (result["isSuccess"]) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Successfully saved"),
                        action: SnackBarAction(
                            label: "Share",
                            onPressed: () {
                              Share.shareFiles(
                                  ['/storage/emulated/0/Pictures/$id.jpg']);
                            }),
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text("Some error occurred please try again!")));
                    }
                  }
                } else {
                  final id = const Uuid().v4();
                  final bytes = await convertCanvasToImage();
                  final result = await ImageGallerySaver.saveImage(
                      Uint8List.fromList(bytes!.buffer.asUint8List()),
                      quality: 60,
                      name: id);

                  if (result["isSuccess"]) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text("Successfully saved"),
                      action: SnackBarAction(
                          label: "Share",
                          onPressed: () {
                            Share.shareFiles(
                                ['/storage/emulated/0/Pictures/$id.jpg']);
                          }),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Some error occurred please try again!")));
                  }
                }
              } else {
                final id = const Uuid().v4();

                final bytes = await convertCanvasToImage();
                final list = Uint8List.fromList(bytes!.buffer.asUint8List());

                final a = html.AnchorElement(
                    href: 'data:image/jpeg;base64,${base64Encode(list)}');

                // set the name of the file we want the image to get
                // downloaded to
                a.download = '$id.png';

                // and we click the AnchorElement which downloads the image
                a.click();
                // finally we remove the AnchorElement
                a.remove();
              }
            },
            icon: const Icon(Icons.save),
            tooltip: "Save",
          )
        ],
      ),
      body: Center(
          child: ClipRRect(
        child: SizedBox(
          child: GestureDetector(
            onPanStart: (details) => setState(() {
              prevX = details.localPosition.dx;
              prevY = details.localPosition.dy;
              currentPath = CustomPath(
                  Path()
                    ..moveTo(
                        details.localPosition.dx, details.localPosition.dy),
                  Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = brushSize
                    ..strokeCap = StrokeCap.round
                    ..color = color);
            }),
            onPanUpdate: (details) => setState(() {
              prevX = details.localPosition.dx;
              prevY = details.localPosition.dy;
              currentPath!.path.quadraticBezierTo(prevX, prevY,
                  details.localPosition.dx, details.localPosition.dy);
            }),
            onPanEnd: (details) => setState(() {
              if (brushStyle == PaintingStyle.fill) {
                final newPath = currentPath!;
                newPath.path.close();
                newPath.paint.style = PaintingStyle.fill;
                drawingPaths.add(newPath);
              }
              drawingPaths.add(currentPath!);
              currentPath = null;
              isCleared = false;
              removedPath = [];
            }),
            child: LayoutBuilder(
                builder: (_, constraints) => InkWell(
                      child: SizedBox(
                        height: constraints.heightConstraints().maxHeight,
                        width: constraints.widthConstraints().maxWidth,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: constraints.widthConstraints().maxWidth,
                              height: constraints.heightConstraints().maxHeight,
                              child: CustomPaint(
                                  painter: DrawingPainter(currentPath,
                                      drawingPaths, backgroundColor)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ColorItem(
                                              color: backgroundColor,
                                              onPressed: () {
                                                setState(() {
                                                  if (currentSelectedColor ==
                                                      "background") {
                                                    showColorPicker();
                                                  }
                                                  currentSelectedColor =
                                                      "background";
                                                });
                                              },
                                              selected: currentSelectedColor ==
                                                  "background",
                                              tooltip: "background color"),
                                          ColorItem(
                                              color: color,
                                              onPressed: () {
                                                setState(() {
                                                  if (currentSelectedColor ==
                                                      "drawing") {
                                                    showColorPicker();
                                                  }
                                                  currentSelectedColor =
                                                      "drawing";
                                                });
                                              },
                                              selected: currentSelectedColor ==
                                                  "drawing",
                                              tooltip: "paint color"),
                                        ],
                                      ),
                                      OptionMenuItem(
                                          onPressed: () {
                                            setState(() {
                                              if (drawingPaths.isNotEmpty) {
                                                removedPath.add(
                                                    drawingPaths.removeLast());
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.undo_rounded),
                                          tooltip: "Undo"),
                                      OptionMenuItem(
                                          onPressed: () {
                                            setState(() {
                                              if (removedPath.isNotEmpty) {
                                                if (isCleared) {
                                                  drawingPaths = removedPath;
                                                  removedPath = [];
                                                  return;
                                                }
                                                final lastPath =
                                                    removedPath.removeLast();
                                                drawingPaths.add(lastPath);
                                              }
                                            });
                                          },
                                          icon: const Icon(Icons.redo_rounded),
                                          tooltip: "Redo"),
                                      OptionMenuItem(
                                          onPressed: () {
                                            setState(() {
                                              removedPath = drawingPaths;
                                              isCleared = true;
                                              drawingPaths = [];
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.cleaning_services),
                                          tooltip: "Clear canvas"),
                                      OptionMenuItem(
                                          onPressed: () {
                                            showColorPicker();
                                          },
                                          icon: const Icon(
                                              Icons.colorize_rounded),
                                          tooltip: "Color picker"),
                                      OptionMenuItem(
                                          onPressed: () {
                                            showModalBottomSheet(
                                                context: context,
                                                builder: (context) {
                                                  return StatefulBuilder(
                                                      builder:
                                                          (context, setState) {
                                                    return Wrap(children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Slider(
                                                            value: brushSize,
                                                            onChanged:
                                                                (value) =>
                                                                    setState(
                                                                        () {
                                                                      brushSize =
                                                                          value;
                                                                    }),
                                                            min: 5,
                                                            max: 20),
                                                      ),
                                                    ]);
                                                  });
                                                });
                                          },
                                          icon: const Icon(Icons.brush_sharp),
                                          tooltip: "Brush size")
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
          ),
        ),
      )),
    );
  }

  void showColorPicker() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pick a color!'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor:
                    currentSelectedColor == "drawing" ? color : backgroundColor,
                onColorChanged: (Color newColor) {
                  setState(() {
                    if (currentSelectedColor == "drawing") {
                      color = newColor;
                    } else {
                      backgroundColor = newColor;
                    }
                  });
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Select'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Future<ByteData?> convertCanvasToImage() async {
    PictureRecorder pictureRecorder = PictureRecorder();
    Canvas canvas = Canvas(pictureRecorder);

    // Paint your canvas as you want

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height),
        backgroundPaint);
    for (CustomPath path in drawingPaths) {
      canvas.drawPath(path.path, path.paint);
    }

    Picture picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
        MediaQuery.of(context).size.width.toInt(),
        MediaQuery.of(context).size.height.toInt());
    return await image.toByteData(format: ImageByteFormat.png);
  }
}
