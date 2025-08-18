import 'package:flutter/material.dart';
import 'soil_moisture_widget.dart';  // Import the SoilMoistureWidget
import 'temperature_widget.dart'; 
import 'package:aitekno_smartfarm/Routes/routes.dart'; // Import the Routes

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.pushNamed(context, Routes.settings); // Navigate to settings page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove the back arrow icon
        title: Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 0, 128, 55),
        elevation: 4,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg3.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: _selectedIndex == 0 ? Colors.green : Colors.grey),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: _selectedIndex == 1 ? Colors.green : Colors.grey),
            label: '',
          ),
        ],
      ),
    );
  }
}
