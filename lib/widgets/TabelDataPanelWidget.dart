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
  late String selectedDate;

  @override
  void initState() {
    super.initState();
    String today = DateFormat('yyyy_MM_dd').format(DateTime.now());
    selectedDate = today;
  }

  bool get dataAvailable {
    return widget.plotData['zhistory']?.containsKey(selectedDate) ?? false;
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
      setState(() {
        selectedDate = formattedDate;
      });

      if (!widget.plotData['zhistory']!.containsKey(formattedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data tidak tersedia untuk tanggal ini")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? selectedData =
        widget.plotData['zhistory']?[selectedDate]?.cast<String, dynamic>();

    List<DataRow> tableRows = [];

    if (selectedData != null) {
      List<String> sortedTimes = selectedData.keys.toList()..sort();
      for (var time in sortedTimes) {
        var value = selectedData[time];
        if (value is Map) {
          tableRows.add(
            DataRow(
              cells: [
                DataCell(Text(time)),
                DataCell(Text('${value['nitrogen'] ?? '-'}')),
                DataCell(Text('${value['phosphorus'] ?? '-'}')),
                DataCell(Text('${value['potassium'] ?? '-'}')),
                DataCell(Text('${value['airTemperature'] ?? '-'}')),
                DataCell(Text('${value['soilTemperature'] ?? '-'}')),
                DataCell(Text('${value['soilMoistureNPK'] ?? '-'}')),
                DataCell(Text('${value['airHumidity'] ?? '-'}')),
                DataCell(Text('${value['pH'] ?? '-'}')),
                DataCell(Text((value['statusPompa'] == 1) ? 'ON' : 'OFF')),
              ],
            ),
          );
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Center(
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
                    DateFormat('yyyy-MM-dd').format(
                      DateTime.parse(selectedDate.replaceAll("_", "-")),
                    ),
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
