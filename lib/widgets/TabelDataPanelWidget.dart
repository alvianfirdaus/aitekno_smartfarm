import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TabelDataPanelWidget extends StatefulWidget {
  final Map<String, dynamic> plotData;

  const TabelDataPanelWidget({
    required this.plotData,
    Key? key,
  }) : super(key: key);

  @override
  _TabelDataPanelWidgetState createState() => _TabelDataPanelWidgetState();
}

class _TabelDataPanelWidgetState extends State<TabelDataPanelWidget> {
  /// zhistory yang sudah dinormalisasi: key tanggal dipaksa ke yyyy_MM_dd
  Map<String, Map<String, dynamic>> _zhistoryNorm = {};
  late String selectedDate; // yyyy_MM_dd

  @override
  void initState() {
    super.initState();
    _zhistoryNorm = _normalizeZhistory(widget.plotData['zhistory']);
    _pickLatestOrToday();
  }

  @override
  void didUpdateWidget(covariant TabelDataPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.plotData, widget.plotData)) {
      _zhistoryNorm = _normalizeZhistory(widget.plotData['zhistory']);
      if (!_zhistoryNorm.containsKey(selectedDate)) {
        _pickLatestOrToday();
      } else {
        setState(() {}); // refresh tampilan
      }
    }
  }

  // ======================
  // Normalisasi & Helpers
  // ======================

  /// "2025-08-06" -> "2025_08_06"
  String _normDateKey(String dateKey) => dateKey.replaceAll('-', '_');

  /// Bangun peta zhistory dengan key tanggal dinormalisasi (yyyy_MM_dd)
  Map<String, Map<String, dynamic>> _normalizeZhistory(dynamic raw) {
    if (raw == null || raw is! Map) return {};
    final Map<String, dynamic> hist = Map<String, dynamic>.from(raw);
    final out = <String, Map<String, dynamic>>{};
    hist.forEach((k, v) {
      final nk = _normDateKey(k.toString());
      if (v is Map) out[nk] = Map<String, dynamic>.from(v);
    });
    return out;
  }

  /// Ambil tanggal terbaru yang tersedia; jika kosong, pakai hari ini
  void _pickLatestOrToday() {
    final today = DateFormat('yyyy_MM_dd').format(DateTime.now());
    final dates = _zhistoryNorm.keys.toList()..sort((a, b) => b.compareTo(a)); // desc
    if (dates.contains(today)) {
      selectedDate = today;
    } else if (dates.isNotEmpty) {
      selectedDate = dates.first;
    } else {
      selectedDate = today;
    }
    if (mounted) setState(() {});
  }

  /// Convert dinamis ke String rapi
  String _asString(dynamic v) {
    if (v == null) return '-';
    if (v is bool) return v ? 'true' : 'false';
    return v.toString().trim();
  }

  /// Parse angka fleksibel (String/num) → String (tanpa error)
  String _numToText(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toString();
    if (v is String) {
      final t = v.trim().replaceAll(',', '.');
      final d = double.tryParse(t);
      return d?.toString() ?? v.trim();
    }
    return v.toString();
  }

  /// Parse statusPompa ke ON/OFF
  String _statusText(dynamic v) {
    if (v == null) return 'OFF';
    if (v is bool) return v ? 'ON' : 'OFF';
    if (v is num) return v == 1 ? 'ON' : 'OFF';
    if (v is String) {
      final t = v.trim();
      if (t == '1' || t.toLowerCase() == 'on' || t.toLowerCase() == 'true') return 'ON';
      return 'OFF';
    }
    return 'OFF';
  }

  bool get dataAvailable => _zhistoryNorm.containsKey(selectedDate);

  Future<void> _selectDate() async {
    final initial = DateTime.tryParse(selectedDate.replaceAll('_', '-')) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked == null) return;

    final formatted = DateFormat('yyyy_MM_dd').format(picked);
    setState(() => selectedDate = formatted);

    if (!_zhistoryNorm.containsKey(formatted) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data tidak tersedia untuk tanggal ini")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data untuk selectedDate
    final Map<String, dynamic>? selectedMap = _zhistoryNorm[selectedDate];

    // Susun baris tabel
    final List<DataRow> tableRows = [];
    if (selectedMap != null) {
      // typed + sorted by time "HH:mm"
      final times = selectedMap.keys.toList()..sort();
      for (final time in times) {
        final value = selectedMap[time];
        if (value is! Map) continue;
        final entry = Map<String, dynamic>.from(value);

        // alias kelembaban tanah
        final soilMoist =
            entry.containsKey('soilMoistureNPK') ? entry['soilMoistureNPK'] : entry['soilMoisture'];

        tableRows.add(
          DataRow(
            cells: [
              DataCell(Text(_asString(time))),
              DataCell(Text(_numToText(entry['nitrogen']))),
              DataCell(Text(_numToText(entry['phosphorus']))),
              DataCell(Text(_numToText(entry['potassium']))),
              DataCell(Text(_numToText(entry['airTemperature']))),
              DataCell(Text(_numToText(entry['soilTemperature']))),
              DataCell(Text(_numToText(soilMoist))),
              DataCell(Text(_numToText(entry['airHumidity']))),
              DataCell(Text(_numToText(entry['pH']))),
              DataCell(Text(_statusText(entry['statusPompa']))),
            ],
          ),
        );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Tabel History Lingkungan",
              style: TextStyle(
                color: Color(0xFF145215),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Header tanggal
          Container(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 114, 23),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: _selectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    selectedDate.replaceAll('_', '-'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tabel data
          dataAvailable
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => const Color.fromARGB(255, 169, 214, 130),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Waktu')),
                      DataColumn(label: Text('N')),
                      DataColumn(label: Text('P')),
                      DataColumn(label: Text('K')),
                      DataColumn(
                        label: Column(
                          children: [
                            Text('Suhu', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Udara', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          children: [
                            Text('Suhu', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Tanah', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          children: [
                            Text('Kelembaban', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Tanah', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      DataColumn(
                        label: Column(
                          children: [
                            Text('Kelembaban', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Udara', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      DataColumn(label: Text('pH')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: tableRows,
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Data tidak tersedia untuk tanggal ini.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
        ],
      ),
    );
  }
}
