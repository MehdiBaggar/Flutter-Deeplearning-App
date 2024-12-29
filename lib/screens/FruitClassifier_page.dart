import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FruitClassifierPage extends StatefulWidget {
  @override
  State<FruitClassifierPage> createState() => _FruitClassifierPageState();
}

class _FruitClassifierPageState extends State<FruitClassifierPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _result = "No prediction yet";
  double _confidence = 0.0;

  final List<String> _classNames = [
    'Apple',
    'Banana',
    'Avocado',
    'Cherry',
    'Kiwi',
    'Mango',
    'Orange',
    'Pineapple',
    'Strawberries',
    'Watermelon'
  ];

  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/fruits.tflite');
    } catch (e) {
      setState(() {
        _result = "Error loading model: $e";
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _classifyImage(File(pickedFile.path));
    }
  }

  Future<void> _classifyImage(File image) async {
    if (_interpreter == null) {
      setState(() {
        _result = "Model not loaded";
      });
      return;
    }

    try {
      // Load and preprocess the image
      final img.Image? rawImage = img.decodeImage(image.readAsBytesSync());
      final resizedImage = img.copyResize(rawImage!,
          width: 128, height: 128); // Resize to 128x128

      final input = _imageToByteBuffer(resizedImage);
      final output = List.generate(
          1, (_) => List.filled(10, 0.0)); // Model expects [1, 10]

      _interpreter!.run(input, output);

      // Parse the output
      final confidences = output[0];
      int maxIndex = confidences.indexWhere((confidence) =>
          confidence == confidences.reduce((a, b) => a > b ? a : b));

      setState(() {
        _result = _classNames[maxIndex];
        _confidence = confidences[maxIndex];
      });
    } catch (e) {
      setState(() {
        _result = "Error during classification: $e";
      });
    }
  }

  // Converts the image to a byte buffer without normalization
  List<List<List<List<double>>>> _imageToByteBuffer(img.Image image) {
    final buffer = List<List<List<List<double>>>>.generate(
      1,
      (_) => List.generate(
        128,
        (y) => List.generate(
          128,
          (x) {
            final pixel = image.getPixel(x, y);
            final red = img.getRed(pixel).toDouble(); // No normalization
            final green = img.getGreen(pixel).toDouble();
            final blue = img.getBlue(pixel).toDouble();
            return [red, green, blue];
          },
        ),
      ),
    );
    return buffer;
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Fruit Classifier'),
    ),
    body: Center( // Centre tout le contenu de la page
      child: Column(
        mainAxisSize: MainAxisSize.min, // Réduit la taille de la colonne pour éviter l'étirement
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_imageFile != null)
            Image.file(
              _imageFile!,
              height: 200,
              width: 200,
              fit: BoxFit.cover, // Ajuste l'image dans les dimensions spécifiées
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick an Image'),
          ),
          SizedBox(height: 16),
          Text(
            'Prediction: $_result',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center, // Centre le texte
          ),
          Text(
            'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center, // Centre le texte
          ),
        ],
      ),
    ),
  );
}

}
