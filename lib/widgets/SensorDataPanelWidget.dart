import 'package:flutter/material.dart';

class SensorDataPanelWidget extends StatelessWidget {
  final String selectedPlot;
  final Map<String, dynamic> plotData;

  const SensorDataPanelWidget({
    required this.selectedPlot,
    required this.plotData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with selected plot name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Panel Monitor - $selectedPlot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Display sensor data if available, else show a message
          plotData.isNotEmpty
              ? Column(
                  children: [
                    // Row for soil moisture and air humidity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SensorDataItem(
                          title: 'Kelembapan Tanah',
                          value: plotData['soilMoistureNPK']?.toString() ?? 'N/A', // Corrected typo
                        ),
                        SensorDataItem(
                          title: 'Kelembapan Udara',
                          value: plotData['airHumidity']?.toString() ?? 'N/A',
                        ),
                      ],
                    ),
                    Divider(),

                    // pH data
                    // SensorDetailItem(
                    //   icon: Icons.grass,
                    //   title: 'pH',
                    //   value: plotData['pH']?.toString() ?? 'N/A',
                    // ),

                    // Temperature data
                    
                    SensorDetailItem(
                      icon: Icons.thermostat,
                      title: 'Suhu Udara',
                      value: (plotData['airTemperature'] != null ? plotData['airTemperature'].toString() + " °C" : 'N/A'),
                    ),

                    SensorDetailItem(
                      icon: Icons.terrain,
                      title: 'Suhu Tanah',
                      value: (plotData['soilTemperature'] != null ? plotData['soilTemperature'].toString() + " °C" : 'N/A'),
                    ),

                    SensorDetailItem(
                      icon: Icons.science,
                      title: 'PH',
                      value: (plotData['pH'] != null ? plotData['pH'].toString() + "" : 'N/A'),
                    ),

                    // Pump Status data
                    SensorDetailItem(
                      icon: plotData['mode'] == 1 ? Icons.hdr_auto : Icons.fiber_manual_record,
                      title: 'Mode',
                      value: plotData['mode'] == 1 ? 'OTOMATIS' : 'MANUAL',
                    ),

                    // Pump Status data
                    SensorDetailItem(
                      icon: plotData['statusPompa'] == 1 ? Icons.power : Icons.power_off,
                      title: 'Status Pompa',
                      value: plotData['statusPompa'] == 1 ? 'ON' : 'OFF',
                    ),


                    Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SensorDataItem(
                          title: 'Natrium',
                          value: (plotData['nitrogen'] != null ? '${plotData['nitrogen']} mg/kg' : 'N/A'), // Corrected typo
                        ),
                        SensorDataItem(
                          title: 'Phospor',
                          value: (plotData['phosphorus'] != null ? '${plotData['phosphorus']} mg/kg' : 'N/A'),
                        ),
                        SensorDataItem(
                          title: 'Kalium',
                          value: (plotData['potassium'] != null ? '${plotData['potassium']} mg/kg' : 'N/A'),
                        ),
                      ],
                    ),
                  ],
                )
              : Center(
                  child: Text("No data available for $selectedPlot"),
                ),
        ],
      ),
    );
  }
}

class SensorDataItem extends StatelessWidget {
  final String title;
  final String value;

  const SensorDataItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.orange, // Color for sensor data
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SensorDetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SensorDetailItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 24),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.green[900],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
