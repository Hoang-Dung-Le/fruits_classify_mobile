import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fruits_classify/api.dart';
import 'package:http/http.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhận diện trái cây',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(title: 'Image Classification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var logger = Logger();

  File? _image;
  final picker = ImagePicker();

  Image? _imageWidget;

  img.Image? fox;

  String conf = '';
  String fruits_name = '';

  Category? category;

  Future<void> sendImageToServer(MultipartFile imageFile) async {
    var uri = Uri.parse(API.predict);
    print(uri);
    var request = http.MultipartRequest('POST', uri);
    // request.fields['other_data'] =
    //     'optional_data'; // Add other form data if needed
    request.files.add(imageFile);

    var response = await request.send();
    if (response.statusCode == 200) {
      print(response);
      print('Image uploaded successfully!');
      // var data = jsonDecode();
      final respStr = await response.stream.bytesToString();
      var data = jsonDecode(respStr);
      setState(() {
        conf = data['conf'].toString();
        fruits_name = data['class'];
      });
      return;
      // Handle successful response (e.g., show success message)
    } else {
      print('Error uploading image: ${response.reasonPhrase}');
      // Handle error (e.g., show error message)
      return;
    }
  }

  Future<void> submitImage() async {
    if (_image == null) {
      // Handle case where no image is selected
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Chọn hình ảnh trước khi gửi"),
      ));
      return;
    }

    MultipartFile imageFile = MultipartFile.fromBytes(
      'file',
      _image!.readAsBytesSync(), // Assuming _image holds image data
      filename: 'image.jpg', // Set a descriptive filename
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing while loading
      builder: (BuildContext context) {
        return Center(
          child:
              CircularProgressIndicator(), // Or any other loading indicator widget
        );
      },
    );

    try {
      await sendImageToServer(imageFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Không thể kết nối đến server"),
      ));
    }

    // Send the image data

    // Hide loading indicator after sending
    Navigator.pop(context); // Close the dialog
  }

  @override
  void initState() {
    super.initState();
  }

  Future pickAnImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      try {
        _image = File(pickedFile!.path);
        _imageWidget = Image.file(_image!);
        conf = '';
        fruits_name = '';
      } catch (e) {
        _image = null;
        conf = '';
        fruits_name = '';
      }

      // _predict();
    });
  }

  Future shotAnImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      _image = File(pickedFile!.path);
      _imageWidget = Image.file(_image!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Nhận diện trái cây', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: _image == null
                //? Text('Please take/pick an image to continue.')
                ? Container(
                    margin: const EdgeInsets.all(32.0),
                    padding: const EdgeInsets.all(4.0),
                    child: Text('Please take or pick an image to continue.'))
                : Container(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 2 / 5),
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: _imageWidget,
                  ),
          ),
          SizedBox(
            height: 36,
          ),
          ElevatedButton(onPressed: submitImage, child: Text("Submit")),
          Text("Kết quả dự đoán: " + fruits_name),
          Text("Conf: " + conf),
          SizedBox(
            height: 8,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(64, 0, 32, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              onPressed: shotAnImage,
              tooltip: 'Take a picture',
              child: Icon(Icons.camera),
            ),
            FloatingActionButton(
              onPressed: pickAnImage,
              tooltip: 'Pick an image',
              child: Icon(Icons.image),
            )
          ],
        ),
      ),
    );
  }
}
