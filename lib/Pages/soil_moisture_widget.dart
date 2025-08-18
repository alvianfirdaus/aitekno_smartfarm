import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SoilMoistureWidget extends StatefulWidget {
  @override
  _SoilMoistureWidgetState createState() => _SoilMoistureWidgetState();
}

class _SoilMoistureWidgetState extends State<SoilMoistureWidget> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('soilMoisture/value');
  int _soilMoisture = 0;

  @override
  void initState() {
    super.initState();
    _databaseReference.onValue.listen((event) {
      final value = event.snapshot.value;
      setState(() {
        _soilMoisture = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }, onError: (error) {
      // Add error handling here
      print('Error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the status based on soil moisture value
    String status;
    if (_soilMoisture >= 0 && _soilMoisture <= 30) {
      status = 'Kering';
    } else if (_soilMoisture > 30 && _soilMoisture <= 60) {
      status = 'Normal';
    } else if (_soilMoisture > 60 && _soilMoisture <= 100) {
      status = 'Basah';
    } else {
      status = 'Data Tidak Valid'; // Handle invalid data
    }

    return Container(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          elevation: 8, // Add elevation for shadow
          color: Color.fromARGB(255, 77, 187, 81),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.opacity, size: 40),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelembapan Tanah',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Kelembapan: $_soilMoisture%'),
                    Text('Status: $status'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
