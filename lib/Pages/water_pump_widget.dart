import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_switch/flutter_switch.dart';

class WaterPumpWidget extends StatefulWidget {
  @override
  _WaterPumpWidgetState createState() => _WaterPumpWidgetState();
}

class _WaterPumpWidgetState extends State<WaterPumpWidget> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('soilMoisture/value');
  int _soilMoisture = 0;
  bool _isPumpOn = false;

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

  void _togglePump(bool value) {
    setState(() {
      _isPumpOn = value;
      // Add code here to update the pump status in the Firebase database if necessary
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the status based on soil moisture value
    String moistureStatus;
    if (_soilMoisture >= 0 && _soilMoisture <= 30) {
      moistureStatus = 'Kering';
    } else if (_soilMoisture > 30 && _soilMoisture <= 60) {
      moistureStatus = 'Normal';
    } else if (_soilMoisture > 60 && _soilMoisture <= 100) {
      moistureStatus = 'Basah';
    } else {
      moistureStatus = 'Data Tidak Valid'; // Handle invalid data
    }

    String pumpStatus = _isPumpOn ? 'Pompa Aktif' : 'Pompa Mati';

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
                Icon(Icons.water_damage, size: 40),
                SizedBox(width: 16, height: 75,),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pompa Air',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Status: $pumpStatus'),
                    ],
                  ),
                ),
                FlutterSwitch(
                  width: 60,
                  height: 30.0,
                  valueFontSize: 20.0,
                  toggleSize: 22.0,
                  value: _isPumpOn,
                  borderRadius: 30.0,
                  padding: 2.0,
                  showOnOff: true,
                  onToggle: _togglePump,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
