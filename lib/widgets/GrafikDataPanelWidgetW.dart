import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GrafikBulananWidget extends StatefulWidget {
  final Map<String, dynamic> plotData;

  const GrafikBulananWidget({
    Key? key,
    required this.plotData,
  }) : super(key: key);

  @override
  State<GrafikBulananWidget> createState() => _GrafikBulananWidgetState();
}

class _GrafikBulananWidgetState extends State<GrafikBulananWidget> {
  late String selectedMonth;
  late String selectedData;

  final List<String> dataOptions = [
    "Nutrisi (NPK)",
    "Kelembaban Tanah",
    "Suhu Udara",
    "Kelembaban Udara",
    "Suhu Tanah",
    "pH Tanah",
  ];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    selectedMonth = DateFormat('yyyy_MM').format(now);
    selectedData = dataOptions[0];
  }

  Map<String, Map<int, double>> _getNpkAveragesPerDay() {
    final historyRaw = widget.plotData['zhistory'];
    if (historyRaw == null || historyRaw is! Map) return {};

    final Map<String, dynamic> history = Map<String, dynamic>.from(historyRaw);
    final Map<String, Map<int, List<double>>> npkPerDay = {
      'nitrogen': {},
      'phosphorus': {},
      'potassium': {}
    };

    history.forEach((dateKey, timeEntriesRaw) {
      if (dateKey.startsWith(selectedMonth)) {
        int day = int.tryParse(dateKey.split('_').last) ?? 0;

        if (timeEntriesRaw is Map) {
          final timeEntries = Map<String, dynamic>.from(timeEntriesRaw);

          for (var entryRaw in timeEntries.values) {
            if (entryRaw is Map) {
              final entry = Map<String, dynamic>.from(entryRaw);
              for (var key in ['nitrogen', 'phosphorus', 'potassium']) {
                var value = entry[key];
                if (value != null && value is num) {
                  npkPerDay[key]!.putIfAbsent(day, () => []).add(value.toDouble());
                }
              }
            }
          }
        }
      }
    });

    final Map<String, Map<int, double>> npkAverages = {
      'nitrogen': {},
      'phosphorus': {},
      'potassium': {}
    };

    npkPerDay.forEach((key, dataPerDay) {
      dataPerDay.forEach((day, values) {
        double avg = values.reduce((a, b) => a + b) / values.length;
        npkAverages[key]![day] = double.parse(avg.toStringAsFixed(2)); // Round to 2 decimal places
      });
    });

    return npkAverages;
  }

  Map<int, double> _getSingleValueAveragesPerDay(String key) {
    final historyRaw = widget.plotData['zhistory'];
    if (historyRaw == null || historyRaw is! Map) return {};

    final Map<String, dynamic> history = Map<String, dynamic>.from(historyRaw);
    final Map<int, List<double>> dataPerDay = {};

    history.forEach((dateKey, timeEntriesRaw) {
      if (dateKey.startsWith(selectedMonth)) {
        int day = int.tryParse(dateKey.split('_').last) ?? 0;

        if (timeEntriesRaw is Map) {
          final timeEntries = Map<String, dynamic>.from(timeEntriesRaw);

          for (var entryRaw in timeEntries.values) {
            if (entryRaw is Map) {
              final entry = Map<String, dynamic>.from(entryRaw);
              var value = entry[key];
              if (value != null && value is num) {
                dataPerDay.putIfAbsent(day, () => []).add(value.toDouble());
              }
            }
          }
        }
      }
    });

    final Map<int, double> dailyAverages = {};
    dataPerDay.forEach((day, values) {
      double avg = values.reduce((a, b) => a + b) / values.length;
      dailyAverages[day] = double.parse(avg.toStringAsFixed(2)); // Round to 2 decimal places
    });

    return dailyAverages;
  }

  void _selectMonth() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse("${selectedMonth.replaceAll("_", "-")}-01"),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      selectableDayPredicate: (date) => date.day == 1, // Only allow day 1 to simplify
      helpText: "Pilih Bulan",
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateFormat('yyyy_MM').format(picked);
      });
    }
  }

  List<FlSpot> generateFullMonthSpots(Map<int, double> rawData) {
    return List<FlSpot>.generate(31, (i) {
      final day = i + 1;
      final value = rawData[day] ?? 0; // default to 0 if no data
      return FlSpot(day.toDouble(), value);
    });
  }
  double calculateMinY(List<FlSpot> data) {
    if (data.isEmpty) return 0;
    final min = data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    return (min - 10).clamp(0, double.infinity);
  }

  double calculateMaxY(List<FlSpot> data) {
    if (data.isEmpty) return 200;
    final max = data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return max + 10;
  }

  double calculateMinYMultiple(List<List<FlSpot>> datasets) {
    final allY = datasets.expand((list) => list.map((e) => e.y));
    if (allY.isEmpty) return 0;
    final min = allY.reduce((a, b) => a < b ? a : b);
    return (min - 10).clamp(0, double.infinity);
  }

  double calculateMaxYMultiple(List<List<FlSpot>> datasets) {
    final allY = datasets.expand((list) => list.map((e) => e.y));
    if (allY.isEmpty) return 200;
    final max = allY.reduce((a, b) => a > b ? a : b);
    return max + 10;
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> nData = [];
    List<FlSpot> pData = [];
    List<FlSpot> kData = [];
    List<FlSpot> singleData = [];

    if (selectedData == "Nutrisi (NPK)") {
      final npk = _getNpkAveragesPerDay();
      nData = generateFullMonthSpots(npk['nitrogen'] ?? {});
      pData = generateFullMonthSpots(npk['phosphorus'] ?? {});
      kData = generateFullMonthSpots(npk['potassium'] ?? {});
    } else {
      String key;
      switch (selectedData) {
        case "Kelembaban Tanah":
          key = "soilMoistureNPK";
          break;
        case "Kelembaban Udara":
          key = "airHumidity";
          break;
        case "Suhu Udara":
          key = "airTemperature";
          break;
        case "Suhu Tanah":
          key = "soilTemperature";
          break;
        case "pH Tanah":
          key = "pH";
          break;
        default:
          key = "n";
      }
      final avgData = _getSingleValueAveragesPerDay(key);
      singleData = generateFullMonthSpots(avgData);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              "Grafik Bulanan",
              style: const TextStyle(
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
                TextButton.icon(
                  onPressed: _selectMonth,
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    selectedMonth.replaceAll("_", "-"),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                DropdownButton<String>(
                  value: selectedData,
                  dropdownColor: const Color.fromARGB(255, 20, 114, 23),
                  iconEnabledColor: Colors.white,
                  underline: Container(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  items: dataOptions.map((data) {
                    return DropdownMenuItem(
                      value: data,
                      child: Text(
                        data,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        selectedData = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                minY: selectedData == "Nutrisi (NPK)"
                    ? calculateMinYMultiple([nData, pData, kData])
                    : calculateMinY(singleData),
                maxY: selectedData == "Nutrisi (NPK)"
                    ? calculateMaxYMultiple([nData, pData, kData])
                    : calculateMaxY(singleData),
                lineBarsData: selectedData == "Nutrisi (NPK)"
                    ? [
                        LineChartBarData(spots: nData, isCurved: true, color: Colors.blue, barWidth: 3),
                        LineChartBarData(spots: pData, isCurved: true, color: Colors.green, barWidth: 3),
                        LineChartBarData(spots: kData, isCurved: true, color: Colors.red, barWidth: 3),
                      ]
                    : selectedData == "Kelembaban Udara"
                      ? [
                          LineChartBarData(spots: singleData, isCurved: true, color: Colors.orange, barWidth: 3), // Custom color for Kelembaban Udara
                        ]
                      : selectedData == "Suhu Udara"
                          ? [
                              LineChartBarData(spots: singleData, isCurved: true, color: Colors.red, barWidth: 3), // Custom color for Temperature
                            ]
                          : selectedData == "Kelembaban Tanah"
                            ? [
                                LineChartBarData(spots: singleData, isCurved: true, color: Colors.brown, barWidth: 3),
                              ]
                            : selectedData == "pH Tanah"
                              ? [
                                  LineChartBarData(spots: singleData, isCurved: true, color: Colors.purple, barWidth: 3),
                                ]
                              : [
                                  LineChartBarData(spots: singleData, isCurved: true, color: Colors.blue, barWidth: 3),
                                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int day = value.toInt();
                        if (day >= 1 && day <= 31) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(day.toString(), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
