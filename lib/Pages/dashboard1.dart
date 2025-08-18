import 'package:flutter/material.dart';
import 'soil_moisture_widget.dart';  // Import the SoilMoistureWidget
import 'temperature_widget.dart'; 
import 'package:aitekno_smartfarm/Routes/routes.dart';
import 'water_pump_widget.dart';

class DashboardPage extends StatelessWidget {
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
          Positioned(
            top: 10.0,
            left: 20.0,
            right: 0,
              child: Text(
                'Selamat Datang',
                style: TextStyle(fontSize: 24, color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.bold), // Set font weight to bold
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 220.0), // Adjust the top padding as needed
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40.0)),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white.withOpacity(0.9),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Text(
                              'Kontrol Sensor IOT',
                              style: TextStyle(fontSize: 20, color: Colors.black),
                            ),
                            SizedBox(height: 0),
                            SoilMoistureWidget(),
                            TemperatureWidget(),  // Include the SoilMoistureWidget here
                            WaterPumpWidget()
                            // Add more SoilMoistureWidget() here if needed
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }
}