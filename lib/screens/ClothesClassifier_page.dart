import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClothesClassifierPage extends StatefulWidget {
  @override
  _ClothesClassifierPageState createState() => _ClothesClassifierPageState();
}

class _ClothesClassifierPageState extends State<ClothesClassifierPage> {
  File? _image;
  bool _isLoading = false;
  List<double>? _results;
  final picker = ImagePicker();
  Interpreter? _interpreter;

  final List<String> classNames = [
    'T-shirt/top',
    'Trouser',
    'Pullover',
    'Dress',
    'Coat',
    'Sandal',
    'Shirt',
    'Sneaker',
    'Bag',
    'Ankle boot'
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    _interpreter?.close();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_ann.tflite');
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });
      classifyImage(File(pickedFile.path));
    }
  }

  Future<void> classifyImage(File image) async {
    try {
      // Read the image as bytes
      Uint8List imageData = await image.readAsBytes();

      // Preprocess the image
      List<double> processedImage = await preprocessImage(imageData);

      // Prepare input and output tensors
      var input = processedImage.reshape([1, 28, 28, 1]);
      var output = List.filled(10, 0.0).reshape([1, 10]);

      // Run inference
      _interpreter?.run(input, output);

      setState(() {
        _results = output[0];
        _isLoading = false;
      });
    } catch (e) {
      print("Error during classification: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<double>> preprocessImage(Uint8List imageData) async {
    final codec = await ui.instantiateImageCodec(imageData);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final resizedImage = await resizeImage(image, 28, 28);

    final normalizedPixels = <double>[];
    final byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData != null) {
      for (int i = 0; i < byteData.lengthInBytes; i += 4) {
        final red = byteData.getUint8(i);
        final green = byteData.getUint8(i + 1);
        final blue = byteData.getUint8(i + 2);
        final grayValue = (red + green + blue) / 3.0;
        normalizedPixels.add(grayValue / 255.0); // Normalization
      }
    }
    return normalizedPixels;
  }

  Future<ui.Image> resizeImage(
      ui.Image image, int targetWidth, int targetHeight) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst =
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
    canvas.drawImageRect(image, src, dst, paint);

    final resizedImage =
        await recorder.endRecording().toImage(targetWidth, targetHeight);
    return resizedImage;
  }

  Widget buildResults() {
    if (_results == null || _results!.isEmpty) {
      return const Text("No results to display.");
    }

    // Find the index of the class with the highest confidence
    final predictedIndex = _results!.indexWhere(
        (element) => element == _results!.reduce((a, b) => a > b ? a : b));

    return Column(
      children: [
        Text(
          "Predicted Class:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          classNames[predictedIndex],
          style: TextStyle(fontSize: 24, color: Colors.blue),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Clothes Classifier"),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 300,
                    width: 300,
                    fit: BoxFit.cover,
                  )
                else
                  const Text("No image selected.",
                      style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: pickImage,
                  child: const Text("Select an Image"),
                ),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _results == null
                        ? const Text("No results yet.",
                            style: TextStyle(fontSize: 18))
                        : buildResults(),
              ],
            ),
          ),
        ));
  }
}
