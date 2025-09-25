import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GrafikDataPanelWidget extends StatefulWidget {
  final String selectedPlot;           // input dari parent (misal: "Nutrisi (NPK)")
  final Map<String, dynamic> plotData; // harus mengandung 'zhistory'

  const GrafikDataPanelWidget({
    required this.selectedPlot,
    required this.plotData,
    Key? key,
  }) : super(key: key);

  @override
  _GrafikDataPanelWidgetState createState() => _GrafikDataPanelWidgetState();
}

class _GrafikDataPanelWidgetState extends State<GrafikDataPanelWidget> {
  // Opsi dropdown yang valid
  static const List<String> kPlotOptions = [
    "Nutrisi (NPK)",
    "Kelembaban Udara",
    "Kelembaban Tanah",
    "Suhu Udara",
    "Suhu Tanah",
    "pH Tanah",
  ];

  // Normalisasi nilai plot masuk agar selalu valid
  String _normalizeSelectedPlot(String? incoming) {
    if (incoming == null) return kPlotOptions.first;
    return kPlotOptions.contains(incoming) ? incoming : kPlotOptions.first;
  }

  late String selectedDate; // format: yyyy-MM-dd
  late String selectedPlot; // selalu dijaga valid via _normalizeSelectedPlot
  bool dataAvailable = true;

  /// zhistory yang sudah dinormalisasi: date key dipaksa ke yyyy-MM-dd
  Map<String, Map<String, dynamic>> _zhistoryNorm = {};

  @override
  void initState() {
    super.initState();
    selectedPlot = _normalizeSelectedPlot(widget.selectedPlot);
    _zhistoryNorm = _normalizeZhistory(widget.plotData['zhistory']);
    _setLatestAvailableDate();
  }

  @override
  void didUpdateWidget(covariant GrafikDataPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Plot jenis metrik berubah dari parent
    if (oldWidget.selectedPlot != widget.selectedPlot) {
      setState(() {
        selectedPlot = _normalizeSelectedPlot(widget.selectedPlot);
      });
    }

    // Data berubah dari parent
    if (!identical(oldWidget.plotData, widget.plotData)) {
      _zhistoryNorm = _normalizeZhistory(widget.plotData['zhistory']);

      if (!_zhistoryNorm.containsKey(selectedDate)) {
        _setLatestAvailableDate();
      } else {
        setState(() => dataAvailable = true);
      }
    }
  }

  // ======================
  // Normalisasi & Helpers
  // ======================

  /// Paksa semua key tanggal menjadi yyyy-MM-dd
  String _normDateKey(String dateKey) => dateKey.replaceAll('_', '-');

  /// Bangun peta zhistory dengan date key dinormalisasi (yyyy-MM-dd)
  Map<String, Map<String, dynamic>> _normalizeZhistory(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final Map<String, dynamic> hist = Map<String, dynamic>.from(raw);
    final Map<String, Map<String, dynamic>> out = {};

    hist.forEach((k, v) {
      final nk = _normDateKey(k.toString());
      if (v is Map) out[nk] = Map<String, dynamic>.from(v);
    });
    return out;
  }

  /// Parser angka fleksibel (String/num), toleran spasi & koma desimal, handle "n/a"
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

  void _setLatestAvailableDate() {
    final dates = _zhistoryNorm.keys.toList()..sort((a, b) => b.compareTo(a)); // desc
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (dates.contains(today)) {
      selectedDate = today;
      dataAvailable = true;
    } else if (dates.isNotEmpty) {
      selectedDate = dates.first;
      dataAvailable = true;
    } else {
      selectedDate = today; // fallback
      dataAvailable = false;
    }

    if (mounted) setState(() {}); // trigger rebuild
  }

  // ======================
  // Chart Builders
  // ======================

  /// Ambil map "HH:mm" → entry data untuk selectedDate (sudah norm)
  Map<String, dynamic>? _selectedDayEntries() {
    final dayMap = _zhistoryNorm[selectedDate];
    if (dayMap == null) return null;

    // Pastikan typed
    final typed = <String, dynamic>{};
    for (final e in dayMap.entries) {
      if (e.value is Map) typed[e.key] = Map<String, dynamic>.from(e.value as Map);
    }
    return typed;
  }

  double _convertTimeToDouble(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hours = double.parse(parts[0]);
        final minutes = double.parse(parts[1]) / 60.0;
        return hours + minutes;
      }
    } catch (_) {}
    return 0.0;
  }

  String _convertDoubleToTime(double value) {
    if (value.isNaN || value.isInfinite) return "00:00";
    int hours = value.floor().clamp(0, 23);
    int minutes = ((value - hours) * 60).round().clamp(0, 59);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  double _minY(List<FlSpot> series) {
    if (series.isEmpty) return 0;
    final m = series.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    return (m - 10).clamp(0, double.infinity);
  }

  double _maxY(List<FlSpot> series) {
    if (series.isEmpty) return 200;
    final m = series.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return m + 10;
  }

  double _minY3(List<FlSpot> a, List<FlSpot> b, List<FlSpot> c) {
    final all = [...a, ...b, ...c];
    return _minY(all);
  }

  double _maxY3(List<FlSpot> a, List<FlSpot> b, List<FlSpot> c) {
    final all = [...a, ...b, ...c];
    return _maxY(all);
  }

  @override
  Widget build(BuildContext context) {
    final selectedData = _selectedDayEntries();

    // Dataset containers
    final List<FlSpot> nData = [];
    final List<FlSpot> pData = [];
    final List<FlSpot> kData = [];
    final List<FlSpot> airHumidityData = [];
    final List<FlSpot> soilMoistureData = [];
    final List<FlSpot> airTemperatureData = [];
    final List<FlSpot> soilTemperatureData = [];
    final List<FlSpot> pHData = [];

    if (selectedData != null) {
      final sortedTimes = selectedData.keys.toList()..sort();
      for (final t in sortedTimes) {
        final entryRaw = selectedData[t];
        if (entryRaw is! Map) continue;
        final entry = Map<String, dynamic>.from(entryRaw);
        final x = _convertTimeToDouble(t);

        if (selectedPlot == "Nutrisi (NPK)") {
          final n = _asDouble(entry['nitrogen']);
          final p = _asDouble(entry['phosphorus']);
          final k = _asDouble(entry['potassium']);
          if (n != null) nData.add(FlSpot(x, n));
          if (p != null) pData.add(FlSpot(x, p));
          if (k != null) kData.add(FlSpot(x, k));
        } else if (selectedPlot == "Kelembaban Udara") {
          final v = _asDouble(entry['airHumidity']);
          if (v != null) airHumidityData.add(FlSpot(x, v));
        } else if (selectedPlot == "Kelembaban Tanah") {
          // ✅ prefer soilMoistureNPK → fallback soilMoisture
          final vNpk  = _asDouble(entry['soilMoistureNPK']);
          final vSoil = _asDouble(entry['soilMoisture']);
          final v = vNpk ?? vSoil;
          if (v != null) soilMoistureData.add(FlSpot(x, v));
        } else if (selectedPlot == "Suhu Udara") {
          final v = _asDouble(entry['airTemperature']);
          if (v != null) airTemperatureData.add(FlSpot(x, v));
        } else if (selectedPlot == "Suhu Tanah") {
          final v = _asDouble(entry['soilTemperature']);
          if (v != null) soilTemperatureData.add(FlSpot(x, v));
        } else if (selectedPlot == "pH Tanah") {
          final v = _asDouble(entry['pH']);
          if (v != null) pHData.add(FlSpot(x, v));
        }
      }
    }

    // Tentukan min/max dinamis
    final double minY = selectedPlot == "Nutrisi (NPK)"
        ? _minY3(nData, pData, kData)
        : selectedPlot == "Kelembaban Udara"
            ? _minY(airHumidityData)
            : selectedPlot == "Kelembaban Tanah"
                ? _minY(soilMoistureData)
                : selectedPlot == "Suhu Udara"
                    ? _minY(airTemperatureData)
                    : selectedPlot == "Suhu Tanah"
                        ? _minY(soilTemperatureData)
                        : _minY(pHData);

    final double maxY = selectedPlot == "Nutrisi (NPK)"
        ? _maxY3(nData, pData, kData)
        : selectedPlot == "Kelembaban Udara"
            ? _maxY(airHumidityData)
            : selectedPlot == "Kelembaban Tanah"
                ? _maxY(soilMoistureData)
                : selectedPlot == "Suhu Udara"
                    ? _maxY(airTemperatureData)
                    : selectedPlot == "Suhu Tanah"
                        ? _maxY(soilTemperatureData)
                        : _maxY(pHData);

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
          const Center(
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
                      const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        selectedDate, // sudah yyyy-MM-dd
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
                    value: kPlotOptions.contains(selectedPlot) ? selectedPlot : kPlotOptions.first,
                    iconEnabledColor: Colors.white,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: kPlotOptions
                        .map((v) => DropdownMenuItem<String>(
                              value: v,
                              child: Text(v, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      setState(() => selectedPlot = newValue);
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
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Text(
                        _convertDoubleToTime(value),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: selectedPlot == "Nutrisi (NPK)"
                    ? [
                        LineChartBarData(spots: nData, isCurved: true, color: Colors.blue,  barWidth: 3),
                        LineChartBarData(spots: pData, isCurved: true, color: Colors.green, barWidth: 3),
                        LineChartBarData(spots: kData, isCurved: true, color: Colors.red,   barWidth: 3),
                      ]
                    : selectedPlot == "Kelembaban Udara"
                        ? [LineChartBarData(spots: airHumidityData,    isCurved: true, color: Colors.orange, barWidth: 3)]
                        : selectedPlot == "Kelembaban Tanah"
                            ? [LineChartBarData(spots: soilMoistureData,  isCurved: true, color: Colors.brown,  barWidth: 3)]
                            : selectedPlot == "Suhu Udara"
                                ? [LineChartBarData(spots: airTemperatureData, isCurved: true, color: Colors.red,    barWidth: 3)]
                                : selectedPlot == "Suhu Tanah"
                                    ? [LineChartBarData(spots: soilTemperatureData, isCurved: true, color: Colors.brown,  barWidth: 3)]
                                    : [LineChartBarData(spots: pHData, isCurved: true, color: Colors.purple, barWidth: 3)],
              ),
            ),
          ),
          if (selectedPlot == "Nutrisi (NPK)") ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendDot(color: Colors.blue,  label: "Nitrogen (N)"),
                SizedBox(width: 12),
                _LegendDot(color: Colors.green, label: "Fosfor (P)"),
                SizedBox(width: 12),
                _LegendDot(color: Colors.red,   label: "Kalium (K)"),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(selectedDate) ?? DateTime.now(), // yyyy-MM-dd
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(pickedDate); // yyyy-MM-dd
      if (_zhistoryNorm.containsKey(formatted)) {
        setState(() {
          selectedDate = formatted;
          dataAvailable = true;
        });
      } else {
        setState(() {
          dataAvailable = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data tidak tersedia untuk tanggal ini")),
          );
        }
      }
    }
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
