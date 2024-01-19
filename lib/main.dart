import 'dart:io';

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
            var status = await Permission.photos.status;
            if (status.isDenied) {
              print("Permission denied");
            } else {
              print("Permission granted");
              _pickAndSaveImage();
            }
          },
          child: const Text('Pick and Save Image'),
        ),
      ),
    );
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bool permissionGranted = await _requestPermission(Permission.manageExternalStorage);

        final Directory? downloadsDirectory = await getExternalStorageDirectory();
        final File newImage = File('/storage/emulated/0/Android/image.jpg');

        await newImage.writeAsBytes(await pickedFile.readAsBytes());

        print('Image saved to downloads directory: ${newImage.path}');

    } else {
      print('No image picked.');
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
