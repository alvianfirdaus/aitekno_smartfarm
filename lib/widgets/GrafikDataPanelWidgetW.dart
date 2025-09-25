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
  late String selectedMonth; // format ui: yyyy_MM
  late String selectedData;

  final List<String> dataOptions = const [
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
    final now = DateTime.now();
    selectedMonth = DateFormat('yyyy_MM').format(now);
    selectedData = dataOptions[0];
  }

  // ======================
  // Helpers
  // ======================

  // Normalisasi "2025-08-06" -> "2025_08_06"
  String _normDateKey(String dateKey) => dateKey.replaceAll('-', '_');

  // Ambil hari (dd) dari "yyyy_mm_dd" atau "yyyy-mm-dd"
  int _extractDay(String dateKey) {
    final m = RegExp(r'^(\d{4})[-_](\d{2})[-_](\d{2})$').firstMatch(dateKey);
    if (m == null) return 0;
    return int.tryParse(m.group(3)!) ?? 0;
  }

  // Parser angka fleksibel (String/num), toleran koma desimal, dan handle "n/a"
  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t.isEmpty || t == 'n/a' || t == 'na' || t == 'null') return null;
      return double.tryParse(t.replaceAll(',', '.'));
    }
    return null;
  }

  String _keyFor(String label) {
    switch (label) {
      case "Kelembaban Tanah":
        // KUNCI UTAMA untuk kelembaban tanah
        // (logika fallback ke soilMoisture ada di _getSingleValueAveragesPerDay)
        return "soilMoistureNPK";
      case "Kelembaban Udara":
        return "airHumidity";
      case "Suhu Udara":
        return "airTemperature";
      case "Suhu Tanah":
        return "soilTemperature";
      case "pH Tanah":
        return "pH";
      default:
        return "";
    }
  }

  // ======================
  // Data Builders
  // ======================

  Map<String, Map<int, double>> _getNpkAveragesPerDay() {
    final historyRaw = widget.plotData['zhistory'];
    if (historyRaw == null || historyRaw is! Map) return {};

    final Map<String, dynamic> history = Map<String, dynamic>.from(historyRaw);
    final Map<String, Map<int, List<double>>> npkPerDay = {
      'nitrogen': {},
      'phosphorus': {},
      'potassium': {},
    };

    history.forEach((dateKeyRaw, timeEntriesRaw) {
      final dateKey = _normDateKey(dateKeyRaw);
      if (!dateKey.startsWith(selectedMonth)) return;

      final day = _extractDay(dateKey);
      if (day == 0 || timeEntriesRaw is! Map) return;

      final timeEntries = Map<String, dynamic>.from(timeEntriesRaw);
      for (final entryRaw in timeEntries.values) {
        if (entryRaw is! Map) continue;
        final entry = Map<String, dynamic>.from(entryRaw);

        for (final k in ['nitrogen', 'phosphorus', 'potassium']) {
          final d = _asDouble(entry[k]);
          if (d != null) {
            npkPerDay[k]!.putIfAbsent(day, () => <double>[]).add(d);
          }
        }
      }
    });

    final Map<String, Map<int, double>> npkAverages = {
      'nitrogen': {},
      'phosphorus': {},
      'potassium': {},
    };

    npkPerDay.forEach((key, perDay) {
      perDay.forEach((day, values) {
        final avg = values.reduce((a, b) => a + b) / values.length;
        npkAverages[key]![day] = double.parse(avg.toStringAsFixed(2));
      });
    });

    return npkAverages;
  }

  /// Ambil rata-rata per hari untuk 1 metrik (kelembaban, suhu, pH)
  /// KHUSUS "soilMoistureNPK": prefer NPK, fallback ke soilMoisture jika NPK null/invalid.
  Map<int, double> _getSingleValueAveragesPerDay(String key) {
    final historyRaw = widget.plotData['zhistory'];
    if (historyRaw == null || historyRaw is! Map || key.isEmpty) return {};

    final Map<String, dynamic> history = Map<String, dynamic>.from(historyRaw);
    final Map<int, List<double>> dataPerDay = {};

    history.forEach((dateKeyRaw, timeEntriesRaw) {
      final dateKey = _normDateKey(dateKeyRaw);
      if (!dateKey.startsWith(selectedMonth)) return;

      final day = _extractDay(dateKey);
      if (day == 0 || timeEntriesRaw is! Map) return;

      final timeEntries = Map<String, dynamic>.from(timeEntriesRaw);
      for (final entryRaw in timeEntries.values) {
        if (entryRaw is! Map) continue;
        final entry = Map<String, dynamic>.from(entryRaw);

        double? val;
        if (key == 'soilMoistureNPK') {
          // ✅ Prefer soilMoistureNPK -> fallback soilMoisture
          val = _asDouble(entry['soilMoistureNPK']);
          val ??= _asDouble(entry['soilMoisture']);
        } else {
          val = _asDouble(entry[key]);
        }

        if (val != null) {
          dataPerDay.putIfAbsent(day, () => <double>[]).add(val);
        }
      }
    });

    final Map<int, double> dailyAverages = {};
    dataPerDay.forEach((day, values) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      dailyAverages[day] = double.parse(avg.toStringAsFixed(2));
    });
    return dailyAverages;
  }

  // ======================
  // Chart helpers
  // ======================

  List<FlSpot> generateFullMonthSpots(Map<int, double> rawData) {
    return List<FlSpot>.generate(31, (i) {
      final day = i + 1;
      final value = rawData[day] ?? 0; // default 0 jika tidak ada data
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

  Future<void> _selectMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse("${selectedMonth.replaceAll("_", "-")}-01"),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
      selectableDayPredicate: (date) => date.day == 1,
      helpText: "Pilih Bulan",
    );
    if (picked != null) {
      setState(() {
        selectedMonth = DateFormat('yyyy_MM').format(picked);
      });
    }
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
      final key = _keyFor(selectedData);
      final avgData = _getSingleValueAveragesPerDay(key);
      singleData = generateFullMonthSpots(avgData);
    }

    final minY = selectedData == "Nutrisi (NPK)"
        ? calculateMinYMultiple([nData, pData, kData])
        : calculateMinY(singleData);
    final maxY = selectedData == "Nutrisi (NPK)"
        ? calculateMaxYMultiple([nData, pData, kData])
        : calculateMaxY(singleData);

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
          const Center(
            child: Text(
              "Grafik Bulanan",
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
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final day = value.toInt();
                        if (day >= 1 && day <= 31) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              day.toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: selectedData == "Nutrisi (NPK)"
                    ? [
                        LineChartBarData(spots: nData, isCurved: true, color: Colors.blue, barWidth: 3),
                        LineChartBarData(spots: pData, isCurved: true, color: Colors.green, barWidth: 3),
                        LineChartBarData(spots: kData, isCurved: true, color: Colors.red, barWidth: 3),
                      ]
                    : selectedData == "Kelembaban Udara"
                        ? [LineChartBarData(spots: singleData, isCurved: true, color: Colors.orange, barWidth: 3)]
                        : selectedData == "Suhu Udara"
                            ? [LineChartBarData(spots: singleData, isCurved: true, color: Colors.red, barWidth: 3)]
                            : selectedData == "Kelembaban Tanah"
                                ? [LineChartBarData(spots: singleData, isCurved: true, color: Colors.brown, barWidth: 3)]
                                : selectedData == "pH Tanah"
                                    ? [LineChartBarData(spots: singleData, isCurved: true, color: Colors.purple, barWidth: 3)]
                                    : [LineChartBarData(spots: singleData, isCurved: true, color: Colors.blue, barWidth: 3)],
              ),
            ),
          ),
          if (selectedData == "Nutrisi (NPK)") ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendDot(color: Colors.blue, label: "Nitrogen (N)"),
                SizedBox(width: 12),
                _LegendDot(color: Colors.green, label: "Phosphorus (P)"),
                SizedBox(width: 12),
                _LegendDot(color: Colors.red, label: "Potassium (K)"),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }
}
