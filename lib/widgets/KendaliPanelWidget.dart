import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class KendaliPanelWidget extends StatefulWidget {
  final String selectedPlot;

  const KendaliPanelWidget({super.key, required this.selectedPlot});

  @override
  State<KendaliPanelWidget> createState() => _KendaliPanelWidgetState();
}

class _KendaliPanelWidgetState extends State<KendaliPanelWidget> {
  bool isManualMode = false;
  bool isPumpOn = false;

  DatabaseReference? modeReference;
  DatabaseReference? pumpControlReference;

  StreamSubscription<DatabaseEvent>? modeSubscription;
  StreamSubscription<DatabaseEvent>? pumpControlSubscription;

  @override
  void initState() {
    super.initState();
    _setupListeners(widget.selectedPlot);
  }

  @override
  void didUpdateWidget(covariant KendaliPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlot != oldWidget.selectedPlot) {
      _cancelListeners();
      _setupListeners(widget.selectedPlot);
    }
  }

  void _setupListeners(String plot) {
    final ref = FirebaseDatabase.instance.ref();
    modeReference = ref.child('$plot/mode');
    pumpControlReference = ref.child('$plot/manualPumpControl');

    modeSubscription = modeReference!.onValue.listen((event) {
      final value = event.snapshot.value;
      setState(() {
        isManualMode = value == 0;
      });
    });

    pumpControlSubscription = pumpControlReference!.onValue.listen((event) {
      final value = event.snapshot.value;
      setState(() {
        isPumpOn = value == 1;
      });
    });
  }

  void _cancelListeners() {
    modeSubscription?.cancel();
    pumpControlSubscription?.cancel();
  }

  void updateMode(bool manual) {
    final value = manual ? 0 : 1;
    FirebaseDatabase.instance.ref('${widget.selectedPlot}/mode').set(value);
  }

  void updatePumpControl(bool on) {
    final value = on ? 1 : 0;
    FirebaseDatabase.instance.ref('${widget.selectedPlot}/manualPumpControl').set(value);
  }

  @override
  void dispose() {
    _cancelListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330, // Atur lebar kotak di sini
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
          Text(
            'Kendali IOT - ${widget.selectedPlot}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[900],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mode:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
              Row(
                children: [
                  ModeButton(
                    mode: 'Manual',
                    isSelected: isManualMode,
                    onTap: () => updateMode(true),
                  ),
                  const SizedBox(width: 10),
                  ModeButton(
                    mode: 'Otomatis',
                    isSelected: !isManualMode,
                    onTap: () => updateMode(false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: isManualMode
                ? ElevatedButton(
                    onPressed: () => updatePumpControl(!isPumpOn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPumpOn ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: Text(
                      isPumpOn ? 'Matikan Pompa' : 'Hidupkan Pompa',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                : const Text(
                    'Mode Otomatis Aktif',
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
          ),
        ],
      ),
    );
  }
}

// ModeButton widget terpisah
class ModeButton extends StatelessWidget {
  final String mode;
  final bool isSelected;
  final VoidCallback onTap;

  const ModeButton({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          mode,
          style: TextStyle(
            fontSize: 16,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
