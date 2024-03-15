import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
// import 'dart:js_util';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';


// import 'package:intl/';


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
   var request =await http.MultipartRequest(
     'POST',
     Uri.parse("http://10.0.2.2:5000/upload"),
   );


   for (int i = 0; i < images.length; i++) {
     XFile image = images[i];
     request.files.add(
       http.MultipartFile(
         'images',
         File(image.path).readAsBytes().asStream(),
         File(image.path).lengthSync(),
         filename: "image_$i.jpg", // Set a unique filename for each image
         contentType: MediaType('image', 'jpeg'),
       ),
     );
   }
   print("request: " + request.toString());


   var streamedResponse = await request.send();
   print("hii");
   // print(streamedResponse.statusCode);
   // var response = await http.Response.fromStream(streamedResponse);


   final completer = Completer<List<int>>();
   final chunks = <List<int>>[];


   streamedResponse.stream.listen(
         (chunk) => chunks.add(chunk),
     onDone: () {
       if (!completer.isCompleted) {
         completer.complete(chunks.expand((x) => x).toList());
       }
     },
     onError: (e) {
       if (!completer.isCompleted) {
         completer.completeError(e);
       }
     },
   );


   print("hii");


   final bytes = await completer.future;
   final response;
         response =await http.Response.bytes(bytes, streamedResponse.statusCode, headers: streamedResponse.headers, request: request);




   if (response.statusCode == 200) {
     List<dynamic> resultAsList = jsonDecode(response.body);


     List<List<int>> listoflistimage = [];




     var count = 1;
     for (var sublist in resultAsList) {
       print("start :- ");
       print(count);
       count++;


       List<int> current = [];


       for (int i = 0; i < sublist.length; i++) {


         if(sublist[i].runtimeType == int && !current.contains(sublist[i]-1))
           {
             print("Image index: ${sublist[i]}");
             current.add(sublist[i] - 1);
           }
       }
       listoflistimage.add(current);


     }
     saveImages(listoflistimage , images);
   } else {
     print('Failed to fetch response. Status code: ${response.statusCode}');
   }


 }




 Future<void> saveImages(List<List<int>> listOfListOfImages , List<XFile> images) async {
   // Get the application directory
   Directory? appDir = await getExternalStorageDirectory();


   // Iterate through each sublist of images
   for (int i = 0; i < listOfListOfImages.length; i++) {
     List<int> currentImages = listOfListOfImages[i];


     // Create a directory for each sublist
     DateTime now = new DateTime.now();


     String currentTime = now.day.toString() + ":"+now.month.toString()  + ":"+ now.year.toString()  + ":"+ now.hour.toString() + ":" + now.minute.toString() + ":"+now.second.toString();
     print(currentTime);
     print(appDir?.path);
     Directory directory = Directory('${appDir?.path}/${currentTime}Directory_$i');
     directory.createSync(recursive: true);


     // Save each image into the directory
     for (int j = 0; j < currentImages.length; j++) {
       XFile image = images[currentImages[j]];
       File newFile = File('${directory.path}/image_$j.jpg');
       await newFile.writeAsBytes(await image.readAsBytes());


     }
   }
 }
 Future<void> _pickAndSaveImage() async{
   final picker = ImagePicker();
   final List<XFile>? images = await picker.pickMultiImage();
   if (images != null && images.isNotEmpty) {


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
