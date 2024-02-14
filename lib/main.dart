import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:myporj/api.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  var Data;
  String QueryText = 'Query';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                var status = await Permission.photos.status;
                if (status.isDenied) {
                  print("Permission denied");
                } else {
                  print("Permission granted");
                  var newData = await Getdata(Uri.parse("http://127.0.0.1:5000/api?Query=Hello"));
                  var decodeData = jsonDecode(newData);
                  setState(() {
                    QueryText = decodeData['Query'];
                    // print(decodeData);
                  });
                }
              },
              child: const Text('Pick and Save Images'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: TextEditingController(text: QueryText),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Data',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
