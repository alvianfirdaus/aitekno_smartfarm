import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class EditCatatanScreen extends StatefulWidget {
  final String selectedPlot;
  final String catatanKey;
  final String initialCatatan;
  final String initialTanggal;
  final String initialWaktu;

  const EditCatatanScreen({
    required this.selectedPlot,
    required this.catatanKey,
    required this.initialCatatan,
    required this.initialTanggal,
    required this.initialWaktu,
  });

  @override
  _EditCatatanScreenState createState() => _EditCatatanScreenState();
}

class _EditCatatanScreenState extends State<EditCatatanScreen> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final TextEditingController catatanController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    catatanController.text = widget.initialCatatan;
    selectedDate = DateFormat("d MMMM yyyy").parse(widget.initialTanggal);
    List<String> timeParts = widget.initialWaktu.split(":");
    selectedTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
  }

  void updateCatatan() {
    if (catatanController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
      String formattedDate = DateFormat("d MMMM yyyy").format(selectedDate!);
      String formattedTime = "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

      Map<String, dynamic> updatedCatatan = {
        "catatan": catatanController.text,
        "tanggal": formattedDate,
        "waktu": formattedTime,
      };

      databaseReference.child("${widget.selectedPlot}/zcatatan/${widget.catatanKey}").update(updatedCatatan).then((_) {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 101, 31),
        title: Text(
          "Edit Catatan",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Tanggal
            Text("Tanggal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            GestureDetector(
              onTap: () async {
                selectedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                setState(() {});
              },
              child: Container(
                width: double.infinity, // Tambahkan ini
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Text(
                  selectedDate == null
                      ? "Pilih Tanggal"
                      : DateFormat("d MMMM yyyy").format(selectedDate!),
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),

            // Field Waktu
            Text("Waktu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            
            GestureDetector(
              onTap: () async {
                selectedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                setState(() {});
              },
              child: Container(
                width: double.infinity, // Tambahkan ini
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Text(
                  selectedTime == null
                      ? "Pilih Waktu"
                      : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),

            // Field Catatan
            Text("Catatan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: TextField(
                controller: catatanController,
                decoration: InputDecoration.collapsed(
                  hintText: "Masukkan Catatan",
                  hintStyle: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                maxLines: 3,
              ),
            ),

            // Tombol Simpan Perubahan
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: updateCatatan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 101, 31),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Simpan Perubahan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFF8F8F8),
    );
  }
}