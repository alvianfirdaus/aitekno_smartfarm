import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DeteksiScreen extends StatefulWidget {
  @override
  _DeteksiScreenState createState() => _DeteksiScreenState();
}

class _DeteksiScreenState extends State<DeteksiScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;

  final String backendUrl = "http://192.168.1.107:5000/predict"; // Ganti dengan IP backend Anda

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
    );

    try {
      await _cameraController.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _captureImage() async {
    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _capturedImage = image;
      });

      if (_capturedImage != null) {
        final processedImage = await _preprocessImage(_capturedImage!);
        await _sendImageToBackend(processedImage);
      }
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Future<XFile> _preprocessImage(XFile imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);

    // Crop ke area kotak tengah (contoh: kotak 200x200 di tengah gambar)
    int boxWidth = 200;
    int boxHeight = 200;
    int centerX = originalImage!.width ~/ 2;
    int centerY = originalImage.height ~/ 2;

    img.Image croppedImage = img.copyCrop(
      originalImage,
      x: centerX - boxWidth ~/ 2,
      y: centerY - boxHeight ~/ 2,
      width: boxWidth,
      height: boxHeight,
    );

    // Resize ke ukuran yang diperlukan oleh model (misal 224x224)
    img.Image resizedImage = img.copyResize(croppedImage, width: 224, height: 224);

    // Konversi ke format JPEG
    final processedBytes = img.encodeJpg(resizedImage);

    // Simpan ke file sementara
    final tempDir = await getTemporaryDirectory();
    final processedImagePath = '${tempDir.path}/processed_image.jpg';
    File(processedImagePath).writeAsBytesSync(processedBytes);

    return XFile(processedImagePath);
  }

  Future<void> _sendImageToBackend(XFile imageFile) async {
    try {
      // Tampilkan indikator loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();

      // Cek status code
      print("Status Code: ${response.statusCode}");

      Navigator.of(context).pop(); // Tutup dialog loading

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final decodedData = jsonDecode(responseData);

        print("Response Data: $decodedData"); // Debug respons backend

        final predictions = decodedData['predictions'] as List;
        if (predictions.isNotEmpty) {
          final prediction = predictions[0];
          final soilType = prediction['soil_type'] ?? "Tidak diketahui";
          final probability = prediction['probability'] ?? "0.00";

          _showResultDialog(soilType, probability);
        } else {
          _showErrorDialog("Tidak ada prediksi yang tersedia.");
        }
      } else {
        _showErrorDialog("Gagal: ${response.reasonPhrase}");
      }
    } catch (e) {
      Navigator.of(context).pop(); // Tutup dialog loading jika terjadi error
      _showErrorDialog("Error: $e");
    }
  }

  void _showResultDialog(String soilType, String probability) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Hasil Deteksi"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Jenis Tanah: $soilType"),
              Text("Probabilitas: $probability%"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Deteksi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 101, 31),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_cameraController),
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2.0),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: FloatingActionButton(
                      onPressed: _captureImage,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.camera_alt),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
