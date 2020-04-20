import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;
String res;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  res = await Tflite.loadModel(
    model: "assets/mobilenet.tflite",
    labels: "assets/mobilenet.txt",
  );
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  CameraController controller;
  bool isDetecting = false;
  List<dynamic> preds = ['cat', 'dog', 'chicken'];

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.ultraHigh);

    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      controller.startImageStream((CameraImage img) {
        if (!isDetecting) {
          isDetecting = true;
          Tflite.runModelOnFrame(
            bytesList: img.planes.map((plane) {
              return plane.bytes;
            }).toList(), // required
            imageHeight: img.height,
            imageWidth: img.width,
          ).then((recognitions) {
            setState(() {
              preds = recognitions;
            });
            // setRecognitions(recognitions, img.height, img.width);
            print(recognitions);
            isDetecting = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Mobilenet Realtime Demo"),
        ),
        body: controller.value.isInitialized
            ? MainScreen(controller: controller, preds: preds)
            : Container(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key key,
    @required this.controller,
    @required this.preds,
  }) : super(key: key);

  final CameraController controller;
  final List preds;

  @override
  Widget build(BuildContext context) {
    var deviceData = MediaQuery.of(context);
    return SafeArea(
        child: Column(
      children: <Widget>[
        SizedBox(
          height: deviceData.size.height * 0.7,
          child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller)),
        ),
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: preds.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    height: 50,
                    color: Colors.amber,
                    child: Center(
                        child: Text(
                            '${preds[index]['label']} ${preds[index]['confidence']}')),
                  );
                }))
      ],
    ));
  }
}
