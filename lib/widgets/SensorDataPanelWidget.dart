import 'package:flutter/material.dart';

class SensorDataPanelWidget extends StatelessWidget {
  final String selectedPlot;
  final Map<String, dynamic> plotData;

  const SensorDataPanelWidget({
    required this.selectedPlot,
    required this.plotData,
  });

  // ----- Helpers -----
  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s.isEmpty || s == 'n/a' || s == 'na' || s == 'null') return null;
      return double.tryParse(s.replaceAll(',', '.'));
    }
    return null;
  }

  /// Ambil kelembaban tanah: prioritas soilMoistureNPK -> fallback soilMoisture
  /// Return String siap tampil (atau 'N/A' jika keduanya tak ada).
  String _pickSoilMoistureDisplay(Map<String, dynamic> data) {
    final mNpk = _parseDouble(data['soilMoistureNPK']);
    if (mNpk != null) return mNpk.toString(); // tambahkan " %" jika perlu
    final mSoil = _parseDouble(data['soilMoisture']);
    if (mSoil != null) return mSoil.toString(); // tambahkan " %" jika perlu
    return 'N/A';
  }

  String _strOrNA(dynamic v, {String suffix = ''}) {
    if (v == null) return 'N/A';
    final parsed = _parseDouble(v);
    if (parsed == null) return 'N/A';
    final s = parsed.toString();
    return suffix.isEmpty ? s : '$s $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
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
          const SizedBox(height: 16),

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
                          // ✅ Pakai soilMoistureNPK, fallback ke soilMoisture
                          value: _pickSoilMoistureDisplay(plotData),
                        ),
                        SensorDataItem(
                          title: 'Kelembapan Udara',
                          value: _strOrNA(plotData['airHumidity']),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Temperature data
                    SensorDetailItem(
                      icon: Icons.thermostat,
                      title: 'Suhu Udara',
                      value: _strOrNA(plotData['airTemperature'], suffix: '°C'),
                    ),

                    SensorDetailItem(
                      icon: Icons.terrain,
                      title: 'Suhu Tanah',
                      value: _strOrNA(plotData['soilTemperature'], suffix: '°C'),
                    ),

                    SensorDetailItem(
                      icon: Icons.science,
                      title: 'PH',
                      value: _strOrNA(plotData['pH']),
                    ),

                    // Mode
                    SensorDetailItem(
                      icon: plotData['mode'] == 1 ? Icons.hdr_auto : Icons.fiber_manual_record,
                      title: 'Mode',
                      value: plotData['mode'] == 1 ? 'OTOMATIS' : 'MANUAL',
                    ),

                    // Pump Status
                    SensorDetailItem(
                      icon: plotData['statusPompa'] == 1 ? Icons.power : Icons.power_off,
                      title: 'Status Pompa',
                      value: plotData['statusPompa'] == 1 ? 'ON' : 'OFF',
                    ),

                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // (Catatan: label "Natrium" di kode asal tampaknya salah.
                        // Umumnya N adalah Nitrogen. Jika memang ingin Nitrogen, ubah labelnya.)
                        SensorDataItem(
                          title: 'Nitrogen (N)',
                          value: _strOrNA(plotData['nitrogen'], suffix: 'mg/kg'),
                        ),
                        SensorDataItem(
                          title: 'Fosfor (P)',
                          value: _strOrNA(plotData['phosphorus'], suffix: 'mg/kg'),
                        ),
                        SensorDataItem(
                          title: 'Kalium (K)',
                          value: _strOrNA(plotData['potassium'], suffix: 'mg/kg'),
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
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.orange,
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
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const Spacer(),
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
