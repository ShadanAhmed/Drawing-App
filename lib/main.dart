import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

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
  List<CustomPath> path = [];
  CustomPath? currentPath;
  List<CustomPath> removedPath = [];
  Color color = Colors.black;
  Color backgroundColor = const Color(0xFFFFF7AB);
  double brushSize = 10.0;
  PaintingStyle brushStyle = PaintingStyle.stroke;
  String currentSelectedColor = "drawing";
  PictureRecorder recorder = PictureRecorder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Drawing App"),
        actions: [
          IconButton(
            onPressed: () async {
              if (await Permission.storage.status.isDenied) {
                final status = await Permission.storage.request();
                if (status.isGranted) {
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
                  for (CustomPath path in path) {
                    canvas.drawPath(path.path, path.paint);
                  }

                  Picture picture = pictureRecorder.endRecording();
                  final image = await picture.toImage(
                      MediaQuery.of(context).size.width.toInt(),
                      MediaQuery.of(context).size.height.toInt());

                  final bytes =
                      await image.toByteData(format: ImageByteFormat.png);
                  final result = await ImageGallerySaver.saveImage(
                      Uint8List.fromList(bytes!.buffer.asUint8List()),
                      quality: 60,
                      name: const Uuid().v4());
                  if (result["isSuccess"]) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Successfully saved")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                            Text("Some error occurred please try again!")));
                  }
                }
              } else {
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
                for (CustomPath path in path) {
                  canvas.drawPath(path.path, path.paint);
                }

                Picture picture = pictureRecorder.endRecording();
                final image = await picture.toImage(
                    MediaQuery.of(context).size.width.toInt(),
                    MediaQuery.of(context).size.height.toInt());

                final id = const Uuid().v4();

                final bytes =
                    await image.toByteData(format: ImageByteFormat.png);
                final result = await ImageGallerySaver.saveImage(
                    Uint8List.fromList(bytes!.buffer.asUint8List()),
                    quality: 60,
                    name: id);

                print(result);

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
                      content: Text("Some error occurred please try again!")));
                }
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
              currentPath!.path
                  .lineTo(details.localPosition.dx, details.localPosition.dy);
            }),
            onPanEnd: (details) => setState(() {
              if (brushStyle == PaintingStyle.fill) {
                final newPath = currentPath!;
                newPath.path.close();
                newPath.paint.style = PaintingStyle.fill;
                path.add(newPath);
              }
              path.add(currentPath!);
              currentPath = null;
            }),
            child: LayoutBuilder(
                builder: (_, constraints) => InkWell(
                      child: Container(
                        height: constraints.heightConstraints().maxHeight,
                        width: constraints.widthConstraints().maxWidth,
                        child: Stack(
                          children: [
                            Container(
                              width: constraints.widthConstraints().maxWidth,
                              height: constraints.heightConstraints().maxHeight,
                              child: CustomPaint(
                                  painter: DrawingPainter(
                                      currentPath, path, backgroundColor)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        buildColorItem(backgroundColor, () {
                                          setState(() {
                                            currentSelectedColor = "background";
                                          });
                                        },
                                            currentSelectedColor ==
                                                "background"),
                                        buildColorItem(color, () {
                                          setState(() {
                                            currentSelectedColor = "drawing";
                                          });
                                        }, currentSelectedColor == "drawing"),
                                      ],
                                    ),
                                    buildOptionMenuItem(() {
                                      setState(() {
                                        if (path.isNotEmpty) {
                                          removedPath.add(path.removeLast());
                                        }
                                      });
                                    }, const Icon(Icons.undo_rounded)),
                                    buildOptionMenuItem(() {
                                      setState(() {
                                        if (removedPath.isNotEmpty) {
                                          final lastPath =
                                              removedPath.removeLast();
                                          path.add(lastPath);
                                        }
                                      });
                                    }, const Icon(Icons.redo_rounded)),
                                    Tooltip(
                                      message: "Clear canvas",
                                      child: buildOptionMenuItem(() {
                                        setState(() {
                                          path = [];
                                        });
                                      }, const Icon(Icons.cleaning_services)),
                                    ),
                                    buildOptionMenuItem(() {
                                      showColorPicker();
                                    }, const Icon(Icons.colorize_rounded)),
                                    buildOptionMenuItem(() {
                                      showModalBottomSheet(
                                          context: context,
                                          builder: (context) {
                                            return showBrushSizeBottomSheet(
                                                context);
                                          });
                                    }, const Icon(Icons.brush_sharp))
                                  ],
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

  InkWell buildColorItem(Color color, VoidCallback onPressed, bool selected) {
    return InkWell(
      onTap: () {
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 50,
        width: 50,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
            border:
                selected ? Border.all(color: Colors.black, width: 3) : null),
        child: Center(
          child: Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  Wrap showBrushSizeBottomSheet(BuildContext context) {
    return Wrap(children: [
      Container(
        color: const Color(0xFF737373),
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).canvasColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Brush Size",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 18.0),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        brushSize = 10.0;
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        brushSize = 20.0;
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 20),
                    InkWell(
                      onTap: () {
                        brushSize = 30.0;
                        Navigator.pop(context);
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(28)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  InkWell buildOptionMenuItem(VoidCallback onPressed, Icon icon) {
    return InkWell(
      onTap: () {
        onPressed();
      },
      child: Container(
        height: 50,
        width: 50,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Center(
          child: icon,
        ),
      ),
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
              // Use Material color picker:
              //
              // child: MaterialPicker(
              //   pickerColor: color,
              //   onColorChanged: (Color newColor) {
              //     setState(() {
              //       color = newColor;
              //     });
              //   }, // only on portrait mode
              // ),
              //
              // Use Block color picker:
              //
              // child: BlockPicker(
              //     pickerColor: color,
              //     onColorChanged: (Color newColor) {
              //       setState(() {
              //         color = newColor;
              //       });
              //     }),

              // child: MultipleChoiceBlockPicker(
              //   pickerColors: [color],
              //   onColorsChanged: (List<Color> colors) {
              //     setState(() {
              //       color = colors[0];
              //     });
              //   },
              // ),
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
}

class CustomPath {
  final Path path;
  final Paint paint;

  CustomPath(this.path, this.paint);
}

class DrawingPainter extends CustomPainter {
  final CustomPath? currentPath;
  final List<CustomPath> pathList;
  final Color backgroundColor;

  DrawingPainter(this.currentPath, this.pathList, this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    for (CustomPath path in pathList) {
      canvas.drawPath(path.path, path.paint);
    }
    if (currentPath != null) {
      canvas.drawPath(currentPath!.path, currentPath!.paint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
