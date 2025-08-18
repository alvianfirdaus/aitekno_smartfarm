import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GrafikDataPanelWidget extends StatefulWidget {
  final String selectedPlot;
  final Map<String, dynamic> plotData;

  const GrafikDataPanelWidget({
    required this.selectedPlot,
    required this.plotData,
    Key? key,
  }) : super(key: key);

  @override
  _GrafikDataPanelWidgetState createState() => _GrafikDataPanelWidgetState();
}

class _GrafikDataPanelWidgetState extends State<GrafikDataPanelWidget> {
  late String selectedDate;
  bool dataAvailable = true;
  String selectedPlot = "Nutrisi (NPK)";

  @override
  void initState() {
    super.initState();
    _setLatestAvailableDate();
  }

  void _setLatestAvailableDate() {
    List<String> dates = (widget.plotData['zhistory']?.keys.toList() ?? []).cast<String>();
    dates.sort((a, b) => b.compareTo(a));

    String today = DateFormat('yyyy_MM_dd').format(DateTime.now());
    if (dates.contains(today)) {
      selectedDate = today;
      dataAvailable = true;
    } else if (dates.isNotEmpty) {
      selectedDate = dates.first;
      dataAvailable = true;
    } else {
      selectedDate = today;
      dataAvailable = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedData = widget.plotData['zhistory']?[selectedDate]?.cast<String, dynamic>();
    List<FlSpot> nData = [];
    List<FlSpot> pData = [];
    List<FlSpot> kData = [];
    List<FlSpot> airHumidityData = [];
    List<FlSpot> soilMoistureData = [];
    List<FlSpot> temperatureData = [];
    List<FlSpot> temperaturSoilData = [];
    List<FlSpot> pHData = [];

    if (selectedData != null) {
      List<String> sortedTimes = selectedData.keys.toList()..sort();
      for (var key in sortedTimes) {
        var value = selectedData[key];
        if (value is Map) {
          double timeValue = _convertTimeToDouble(key);
          if (selectedPlot == "Nutrisi (NPK)") {
            nData.add(FlSpot(timeValue, (value['nitrogen'] ?? 0).toDouble()));
            pData.add(FlSpot(timeValue, (value['phosphorus'] ?? 0).toDouble()));
            kData.add(FlSpot(timeValue, (value['potassium'] ?? 0).toDouble()));
          } else if (selectedPlot == "Kelembaban Udara") {
            airHumidityData.add(FlSpot(timeValue, (value['airHumidity'] ?? 0).toDouble()));
          } else if (selectedPlot == "Kelembaban Tanah") {
            soilMoistureData.add(FlSpot(timeValue, (value['soilMoistureNPK'] ?? 0).toDouble()));
          } else if (selectedPlot == "Suhu Udara") {
            temperatureData.add(FlSpot(timeValue, (value['airTemperature'] ?? 0).toDouble()));
          }else if (selectedPlot == "Suhu Tanah") {
            temperaturSoilData.add(FlSpot(timeValue, (value['soilTemperature'] ?? 0).toDouble()));
          }else if (selectedPlot == "pH Tanah") {
            pHData.add(FlSpot(timeValue, (value['pH'] ?? 0).toDouble()));
          }
        }
      }
    }

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
          Center(
              child: Text(
                "Grafik Harian",
                style: TextStyle(
                  color: Color(0xFF145215),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 114, 23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _selectDate,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        selectedDate.replaceAll("_", "-"),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color.fromARGB(255, 20, 114, 23),
                    value: selectedPlot,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: ["Nutrisi (NPK)", "Kelembaban Udara", "Kelembaban Tanah", "Suhu Udara", "Suhu Tanah", "pH Tanah"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedPlot = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(_convertDoubleToTime(value), style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minY: selectedPlot == "Nutrisi (NPK)"
                    ? _calculateMinY(nData, pData, kData)
                    : 0,
                maxY: selectedPlot == "Nutrisi (NPK)"
                    ? _calculateMaxY(nData, pData, kData)
                    : 200,
                lineBarsData: selectedPlot == "Nutrisi (NPK)"
                ? [
                    LineChartBarData(spots: nData, isCurved: true, color: Colors.blue, barWidth: 3),
                    LineChartBarData(spots: pData, isCurved: true, color: Colors.green, barWidth: 3),
                    LineChartBarData(spots: kData, isCurved: true, color: Colors.red, barWidth: 3),
                  ]
                : selectedPlot == "Kelembaban Udara"
                    ? [LineChartBarData(spots: airHumidityData, isCurved: true, color: Colors.orange, barWidth: 3)]
                : selectedPlot == "Kelembaban Tanah"
                    ? [LineChartBarData(spots: soilMoistureData, isCurved: true, color: Colors.brown, barWidth: 3)]
                : selectedPlot == "Suhu Tanah"
                    ? [LineChartBarData(spots: temperaturSoilData, isCurved: true, color: Colors.brown, barWidth: 3)]
                : selectedPlot == "pH Tanah"
                    ? [LineChartBarData(spots: pHData, isCurved: true, color: Colors.purple, barWidth: 3)]
                : [LineChartBarData(spots: temperatureData, isCurved: true, color: Colors.red, barWidth: 3)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _convertTimeToDouble(String time) {
    try {
      List<String> parts = time.split(":");
      if (parts.length == 2) {
        double hours = double.parse(parts[0]);
        double minutes = double.parse(parts[1]) / 60;
        return hours + minutes;
      }
    } catch (e) {
      print("Error parsing time: $time");
    }
    return 0.0;
  }

  String _convertDoubleToTime(double value) {
    if (value.isNaN || value.isInfinite) {
      return "00:00";
    }

    int hours = value.floor();
    int minutes = ((value - hours) * 60).round();

    hours = hours.clamp(0, 23);
    minutes = minutes.clamp(0, 59);

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }
  double _calculateMinY(List<FlSpot> list1, List<FlSpot> list2, List<FlSpot> list3) {
    final allValues = [...list1, ...list2, ...list3].map((e) => e.y);
    if (allValues.isEmpty) return 0;
    double min = allValues.reduce((a, b) => a < b ? a : b);
    return (min - 10).clamp(0, double.infinity); // agar tidak minus
  }

  double _calculateMaxY(List<FlSpot> list1, List<FlSpot> list2, List<FlSpot> list3) {
    final allValues = [...list1, ...list2, ...list3].map((e) => e.y);
    if (allValues.isEmpty) return 200;
    double max = allValues.reduce((a, b) => a > b ? a : b);
    return max + 10;
  }


  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(selectedDate.replaceAll("_", "-")),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy_MM_dd').format(pickedDate);
      if (widget.plotData['zhistory']?.containsKey(formattedDate) ?? false) {
        setState(() {
          selectedDate = formattedDate;
          dataAvailable = true;
        });
      } else {
        setState(() {
          dataAvailable = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data tidak tersedia untuk tanggal ini")),
        );
      }
    }
  }
}
