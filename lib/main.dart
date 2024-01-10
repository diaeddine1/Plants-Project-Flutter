import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plants/HomePage.dart';
import 'package:flutter_plants/add_plants.dart';
import 'package:flutter_plants/firebase_options.dart';
import 'package:flutter_plants/login.dart';
import 'package:flutter_plants/profil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options:DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasData) {
    
            return MainPage();
          } else {
 
            return LoginPage();
          }
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.grass),
            label: 'Plants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Ajout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue, 
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return PlantsPage();
       case 1:
        return AddPlant();
      case 2:
        return ProfilePage();
      default:
        return Container();
    }
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LoginEcran(),
    );
  }
}
