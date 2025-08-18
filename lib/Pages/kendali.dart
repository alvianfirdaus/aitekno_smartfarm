import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aitekno_smartfarm/widgets/KendaliPanelWidget.dart';

class KendaliScreen extends StatefulWidget {
  @override
  _KendaliScreenState createState() => _KendaliScreenState();
}

class _KendaliScreenState extends State<KendaliScreen> {
  String selectedPlot = '';
  String selectedPlotName = '';
  Map<String, dynamic> plotData = {};
  List<String> availablePlots = [];
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadInitialPlot();
    _fetchAvailablePlots();
  }

  Future<void> _loadInitialPlot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlotName = prefs.getString('selected_plot') ?? 'Plot 01';
    final plotKey = savedPlotName.toLowerCase().replaceAll(' ', '');

    setState(() {
      selectedPlot = plotKey;
      selectedPlotName = savedPlotName;
    });

    listenToPlotData(plotKey);
  }

  void listenToPlotData(String plot) {
    databaseReference.child(plot).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          plotData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  void _fetchAvailablePlots() {
    databaseReference.once().then((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final plots = data.keys.where((key) => key.toString().startsWith('plot')).toList();
        setState(() {
          availablePlots = plots.map((e) => _toPlotName(e)).toList();
        });
      }
    });
  }

  String _toPlotName(String key) {
    final number = key.replaceAll(RegExp(r'[^0-9]'), '');
    return 'Plot ${number.padLeft(2, '0')}';
  }

  Future<void> _selectPlotDialog() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Pilih Perangkat"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availablePlots.map((plotName) {
              return ListTile(
                title: Text(plotName),
                onTap: () => Navigator.pop(context, plotName),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null && selected != selectedPlotName) {
      final prefs = await SharedPreferences.getInstance();
      final newKey = selected.toLowerCase().replaceAll(' ', '');
      setState(() {
        selectedPlot = newKey;
        selectedPlotName = selected;
      });
      await prefs.setString('selected_plot', selected);
      listenToPlotData(newKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/headerkendali.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
          Positioned(
            top: 160,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Center(
                  child: PlotBox(
                    plotName: selectedPlotName,
                    isSelected: true,
                    onTap: _selectPlotDialog,
                  ),
                ),
                SizedBox(height: 40),
                KendaliPanelWidget(
                  selectedPlot: selectedPlot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlotBox extends StatelessWidget {
  final bool isSelected;
  final String plotName;
  final VoidCallback onTap;

  const PlotBox({
    required this.isSelected,
    required this.plotName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color.fromARGB(255, 255, 255, 255) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.green.shade900,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices,
              color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
            ),
            SizedBox(width: 8),
            Text(
              'Perangkat : $plotName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
