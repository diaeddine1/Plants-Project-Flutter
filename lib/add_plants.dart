import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPlant extends StatefulWidget {
  const AddPlant({Key? key}) : super(key: key);

  @override
  State<AddPlant> createState() => _AddPlantState();
}

class _AddPlantState extends State<AddPlant> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  File? file;

  TextEditingController nameController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController propertiesController = TextEditingController();
  TextEditingController usesController = TextEditingController();
  TextEditingController precautionsController = TextEditingController();
  TextEditingController interactionsController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _image = image;
        file = File(image!.path);
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void clearFields() {
    nameController.clear();
    categoryController.clear();
    propertiesController.clear();
    usesController.clear();
    precautionsController.clear();
    interactionsController.clear();

    setState(() {
      _image = null;
      file = null;
    });
  }

  Future<void> _uploadFile() async {
    try {
      if (_image == null) {
        print("No image selected");
        return;
      }

   
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child("images/${DateTime.now().millisecondsSinceEpoch}.jpg");

      TaskSnapshot taskSnapshot = await storageReference.putFile(File(_image!.path));

   
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

    
      Map<String, dynamic> data = {
        "imageUrl": imageUrl,
        "name": nameController.text,
        "category": categoryController.text,
        "properties": propertiesController.text,
        "uses": usesController.text,
        "precautions": precautionsController.text,
        "interactions": interactionsController.text,
      };

   
      await FirebaseFirestore.instance.collection("plants").add(data);


      clearFields();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Successfully Added The Plant'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print("Failed To Add The Plant Due To: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add The Plant"),
        backgroundColor: Color.fromRGBO(85, 105, 254, 1.0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePreview(),
              _buildPickImageButton(),
              _buildInputField("Name", nameController),
              _buildInputField("Category", categoryController),
              _buildInputField("Properties", propertiesController),
              _buildInputField("Uses", usesController),
              _buildInputField("Precautions", precautionsController),
              _buildInputField("Interactions", interactionsController),
              _buildAddPlantButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: _imagePreviewContent(),
    );
  }

  Widget _imagePreviewContent() {
    return _image != null
        ? Image.file(
            File(_image!.path),
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image,
                  size: 48.0,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.0),
                Text(
                  'No Image Selected',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPickImageButton() {
    return ElevatedButton(
      onPressed: _pickImage,
      child: Text('Choose an image from the gallery'),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.black, fontSize: 18.0),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPlantButton() {
    return ElevatedButton(
      onPressed: _uploadFile,
      child: Text("Add Your Plant"),
    );
  }
}
