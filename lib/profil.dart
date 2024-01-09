import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plants/login.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? _user;
  TextEditingController _fullnameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _birthdayController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  TextEditingController _postalCodeController = TextEditingController();
  TextEditingController _cityController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(_user!.uid).get();

      if (userSnapshot.exists) {
        setState(() {
          _fullnameController.text = userSnapshot['fullname'] ?? '';
          _emailController.text = _user?.email ?? '';
          _passwordController.text = userSnapshot['password'] ?? '';
          _birthdayController.text = userSnapshot['birthday']?.toString() ?? '';
          _addressController.text = userSnapshot['address'] ?? '';
          _postalCodeController.text = userSnapshot['postalCode'] ?? '';
          _cityController.text = userSnapshot['city'] ?? '';
        });
      }
    }
  }

  Future<void> _updateUserData() async {
    if (_user != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'fullname': _fullnameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'birthday': _birthdayController.text,
        'address': _addressController.text,
        'postalCode': _postalCodeController.text,
        'city': _cityController.text,
      });
      print('User data updated successfully!');
      _toggleEditing(); 
    }
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.blue,
        actions: [
          InkWell(
            onTap: _signOut,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserDataField(
                'Full Name',
                _fullnameController.text,
                controller: _fullnameController,
                readOnly: !_isEditing,
              ),
              _buildUserDataField(
                'Email',
                _emailController.text,
                controller: _emailController,
                readOnly: true,
              ),
              _buildUserDataField(
                'Password',
                _passwordController.text,
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                readOnly: true,
                suffixIcon: _isEditing
                    ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      )
                    : null,
              ),
              _buildUserDataField(
                'Anniversaire',
                _birthdayController.text,
                controller: _birthdayController,
                readOnly: !_isEditing,
              ),
              _buildUserDataField(
                'Adresse',
                _addressController.text,
                controller: _addressController,
                readOnly: !_isEditing,
              ),
              _buildUserDataField(
                'Code postal',
                _postalCodeController.text,
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                readOnly: !_isEditing,
              ),
              _buildUserDataField(
                'Ville',
                _cityController.text,
                controller: _cityController,
                readOnly: !_isEditing,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isEditing ? _updateUserData : _toggleEditing,
                child: Text(_isEditing ? 'Update' : 'Modify'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserDataField(
    String label,
    String value, {
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    IconButton? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isEditing)
          Text(
            label,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        if (_isEditing)
          TextFormField(
            readOnly: readOnly,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.blue,
              ),
              suffixIcon: suffixIcon,
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  obscureText
                      ? '*' * value.length
                      : value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
              ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
        SizedBox(height: 16.0),
      ],
    );
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginEcran()));
  }
}
