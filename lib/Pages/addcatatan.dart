import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AddCatatanScreen extends StatefulWidget {
  final String selectedPlot;

  const AddCatatanScreen({required this.selectedPlot});

  @override
  _AddCatatanScreenState createState() => _AddCatatanScreenState();
}

class _AddCatatanScreenState extends State<AddCatatanScreen> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
  final TextEditingController catatanController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  void saveCatatan() {
    if (catatanController.text.isNotEmpty && selectedDate != null && selectedTime != null) {
      String plotKey = widget.selectedPlot.toLowerCase();
      String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

      String formattedDate = DateFormat("d MMMM yyyy").format(selectedDate!);
      String formattedTime = "${selectedTime!.hour}:${selectedTime!.minute}";

      Map<String, dynamic> newCatatan = {
        "catatan": catatanController.text,
        "tanggal": formattedDate,
        "waktu": formattedTime,
      };

      databaseReference.child("$plotKey/zcatatan/$uniqueId").set(newCatatan).then((_) {
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
          "Catatan",
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
            Text(
              "Tanggal",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity, // Lebar penuh seperti catatan
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () async {
                  selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  setState(() {});
                },
                child: Text(
                  selectedDate == null
                      ? "Masukkan Tanggal"
                      : DateFormat("d MMMM yyyy").format(selectedDate!),
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),

            // Field Waktu
            Text(
              "Waktu",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity, // Lebar penuh seperti catatan
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: GestureDetector(
                onTap: () async {
                  selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {});
                },
                child: Text(
                  selectedTime == null
                      ? "Masukkan Waktu"
                      : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ),

            // Field Catatan
            Text(
              "Catatan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
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

            // Tombol Simpan
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveCatatan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 101, 31),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Simpan",
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
