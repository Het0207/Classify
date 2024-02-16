import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const PermissionPage(),
    );
  }
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({Key? key}) : super(key: key);

  @override
  _PermissionPageState createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  List<XFile> selectedImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Storage Permission ',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            var status = await Permission.manageExternalStorage.status;
            if (status.isDenied) {
              print("Permission denied");
              _requestPermission(Permission.manageExternalStorage);
            } else {
              print("Permission granted");
              _pickAndSaveImage();
              // _pickAndSaveImages();
            }
          },
          child: const Text('Pick and Save Images'),
        ),
      ),
    );
  }

  Future<void> _pickAndSaveImages() async {
    final picker = ImagePicker();
    List<XFile>? pickedFiles = await picker.pickMultiImage();
    var directory = await Directory('/storage/emulated/0/Classifier').create(recursive: true);
    // print(directory.path);
    var directoryPath = directory.path;
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      final bool permissionGranted = await _requestPermission(Permission.manageExternalStorage);

      if (permissionGranted) {
        final Directory? downloadsDirectory = await getExternalStorageDirectory();
        final date = DateTime.now().microsecondsSinceEpoch;

        for (int i = 0; i < pickedFiles.length; i++) {
          final File newImage = File('$directoryPath/$date$i.jpg');
          await newImage.writeAsBytes(await pickedFiles[i].readAsBytes());
          print('Image saved to downloads directory: ${newImage.path}');

        }
        _showSnackBar('Images saved successfully');
      }
    } else {
      print('No images picked.');
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
  void doUpload(List<XFile> images) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://10.0.2.2:5000/upload"),
    );

    for (var image in images) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'images',
          image.path,
          filename: "filename",
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    print("request: " + request.toString());

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print(response.body);
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      doUpload(images);
    } else {
      print('No images selected.');
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 30) {
      var re = await Permission.manageExternalStorage.request();
      return re.isGranted;
    } else {
      if (await permission.isGranted) {
        return true;
      } else {
        var result = await permission.request();
        return result.isGranted;
      }
    }
  }
}