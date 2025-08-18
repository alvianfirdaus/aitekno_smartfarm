import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Tambahkan ini untuk ambil bulan sekarang
import 'package:shared_preferences/shared_preferences.dart';

class HitungNutrisiScreen extends StatefulWidget {
  @override
  _HitungNutrisiScreenState createState() => _HitungNutrisiScreenState();
}

class _HitungNutrisiScreenState extends State<HitungNutrisiScreen> {
  String selectedPlot = "Plot 01"; // Default selected plot
  Map<String, dynamic> plotData = {}; // Plot data

  int jumlahTanaman = 1; // Default jumlah tanaman
  String vase = "Vegetatif"; // Default vase
  bool showResult = false; // Flag untuk menampilkan hasil

  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
   DateTime? selectedDate;

  Future<void> _loadSelectedPlot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlot = prefs.getString('selected_plot') ?? "Plot 01";
    setState(() {
      selectedPlot = savedPlot;
    });
    listenToPlotData(savedPlot.toLowerCase().replaceAll(' ', ''));
    ambilRataRataNPK(); // ← Pindahkan ke sini setelah plot terload
  }

  // Listen to Firebase Realtime Database updates
  void listenToPlotData(String plot) {
    databaseReference.child(plot).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          plotData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }


  final TextEditingController nController = TextEditingController();
  final TextEditingController pController = TextEditingController();
  final TextEditingController kController = TextEditingController();

  String fase = 'Vegetatif';
  
  String hasilKesuburan = '';
  String rekomendasiPupuk = '';
  String luasDerajat = '';


  @override
  void initState() {
    super.initState();
    _loadSelectedPlot(); // Load saved plot
    
    
  }

  Future<void> ambilRataRataNPK() async {
  if (selectedPlot.isEmpty || selectedDate == null) return;

  final plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
  final dateKey = DateFormat('yyyy_MM_dd').format(selectedDate!);

  final snapshot = await FirebaseDatabase.instance
      .ref()
      .child('$plotKey/zhistory/$dateKey')
      .get();

  if (snapshot.exists) {
    double totalN = 0;
    double totalP = 0;
    double totalK = 0;
    int count = 0;

    final dataPerJam = snapshot.value as Map<dynamic, dynamic>;

    dataPerJam.forEach((jam, data) {
      final dataMap = Map<String, dynamic>.from(data);
      final n = dataMap['nitrogen'] ?? 0;
      final p = dataMap['phosphorus'] ?? 0;
      final k = dataMap['potassium'] ?? 0;

      totalN += n.toDouble();
      totalP += p.toDouble();
      totalK += k.toDouble();
      count++;
    });

    if (count > 0) {
      final rataN = totalN / count;
      final rataP = totalP / count;
      final rataK = totalK / count;

      setState(() {
        nController.text = rataN.toStringAsFixed(1);
        pController.text = rataP.toStringAsFixed(1);
        kController.text = rataK.toStringAsFixed(1);
      });

      print("Rata-rata N: $rataN, P: $rataP, K: $rataK");
    }
  } else {
    print("Tidak ada data pada tanggal $dateKey");
    setState(() {
      nController.text = "";
      pController.text = "";
      kController.text = "";
    });
  }
}

  double rendah(double x) => x <= 50 ? 1.0 : x <= 100 ? (100 - x) / 50 : 0.0;
  double sedang(double x) => x <= 50 ? 0.0 : x <= 100 ? (x - 50) / 50 : x <= 150 ? (150 - x) / 50 : 0.0;
  double tinggi(double x) => x <= 100 ? 0.0 : x <= 150 ? (x - 100) / 50 : 1.0;

  final List<Map<String, String>> rules = [
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Rendah', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA + SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Sedang', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA + SP-36', 'generatif': 'SP-36'},
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA + SP-36', 'generatif': 'SP-36'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Rendah', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA + KCl', 'generatif': 'KCl'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Sedang', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA', 'generatif': 'NPK rendah N'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'Cukup Subur', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'Tidak Subur', 'vegetatif': 'Urea/ZA + KCl', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'Cukup Subur', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'Cukup Subur', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Rendah', 'output': 'Tidak Subur', 'vegetatif': 'SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Sedang', 'output': 'Cukup Subur', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'Cukup Subur', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Rendah', 'output': 'Cukup Subur', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Sedang', 'output': 'Cukup Subur', 'vegetatif': 'NPK 15-15-15', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'Cukup Subur', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Rendah', 'output': 'Cukup Subur', 'vegetatif': 'SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Sedang', 'output': 'Cukup Subur', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Rendah', 'output': 'Cukup Subur', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Sedang', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'Subur', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
  ];

  void hitungFuzzy() {
    double n = double.tryParse(nController.text) ?? 0.0;
    double p = double.tryParse(pController.text) ?? 0.0;
    double k = double.tryParse(kController.text) ?? 0.0;

    Map<String, double> uN = {
      'Rendah': rendah(n),
      'Sedang': sedang(n),
      'Tinggi': tinggi(n),
    };
    Map<String, double> uP = {
      'Rendah': rendah(p),
      'Sedang': sedang(p),
      'Tinggi': tinggi(p),
    };
    Map<String, double> uK = {
      'Rendah': rendah(k),
      'Sedang': sedang(k),
      'Tinggi': tinggi(k),
    };

    Map<String, double> alphaMax = {
      'Tidak Subur': 0.0,
      'Cukup Subur': 0.0,
      'Subur': 0.0,
    };
    Map<String, String> pupukPilihan = {
      'Tidak Subur': '',
      'Cukup Subur': '',
      'Subur': '',
    };

    for (var rule in rules) {
      double a = [
        uN[rule['n']]!,
        uP[rule['p']]!,
        uK[rule['k']]!,
      ].reduce((a, b) => a < b ? a : b);

      String label = rule['output']!;
      if (a > alphaMax[label]!) {
        alphaMax[label] = a;
        pupukPilihan[label] = fase == 'Vegetatif' ? rule['vegetatif']! : rule['generatif']!;
      }
    }
    //--------------------------------------menghitung agregasi Tidak Subur
   double koreksi = 0.93;  // kurang lebih untuk mendekati hasil MATLAB
    const double centroidTS = 25.0;
    const double centroidCS = 60.0;
    const double centroidS = 86.7;

    const double lebarAlas = 50.0;

    double luasTS = 0.5 * lebarAlas * alphaMax['Tidak Subur']!;
    double luasCS = 0.5 * 40 * alphaMax['Cukup Subur']!;
    double luasS = 0.5 * 20 * alphaMax['Subur']!;

// Asumsi semua fungsi keanggotaan output adalah segitiga simetris


double result = ((0.5 * 50 * alphaMax['Tidak Subur']! * 25) + ( 0.5 * 40* alphaMax['Cukup Subur']! * 60) + (0.5 * 20*alphaMax['Subur']! * 86.7)) /
                   (luasTS + luasCS + luasS);


    String kategoriKesuburan = '';
    if (result <= 50) {
      kategoriKesuburan = 'Unsur Hara Rendah';
    } else if (result > 50 && result <= 75) {
      kategoriKesuburan = 'Unsur Hara Sedang';
    } else {
      kategoriKesuburan = 'Unsur Hara Tinggi';
    }


    setState(() {
      hasilKesuburan = result.toStringAsFixed(2);
      rekomendasiPupuk = pupukPilihan[alphaMax.keys.firstWhere((key) => alphaMax[key] == alphaMax.values.reduce((a, b) => a > b ? a : b))]!;
      luasDerajat = kategoriKesuburan;
      showResult = true;

    });
  }

int umurTanaman = 0;
String faseTanaman = "";



@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Header Image
        Container(
          height: 230,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/RekomendasiPupuk.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Plot di Tengah
        Positioned(
          top: 158,
          left: 90,
          right: 90,
          child: PlotBox(
            plotName: selectedPlot,
            isSelected: true,
            onTap: () {
              final plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
              listenToPlotData(plotKey);
            },
          ),
        ),

        // Konten
        Padding(
          padding: const EdgeInsets.only(top: 250),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Pilih tanggal untuk menghitung rata-rata NPK:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                            await ambilRataRataNPK();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            selectedDate != null
                                ? DateFormat('dd MMMM yyyy').format(selectedDate!)
                                : 'Pilih tanggal',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      Text(
                        "Masukkan umur tanaman anda:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: 30',
                        ),
                        onChanged: (value) {
                          setState(() {
                            umurTanaman = int.tryParse(value) ?? 0;
                            faseTanaman = umurTanaman <= 42 ? 'Vegetatif' : 'Generatif';
                            fase = faseTanaman;
                          });
                        },
                      ),
                      SizedBox(height: 16),

                      if (fase != null) ...[
                        ElevatedButton(
                          onPressed: hitungFuzzy,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 39, 128, 15),
                            shape: StadiumBorder(),
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Hitung',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      if (hasilKesuburan.isNotEmpty) ...[
                        SizedBox(height: 30),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Berikut adalah rata rata kandungan N, P dan K lahan anda :",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Nitrogen (N)"),
                                  Text("${nController.text} mg/kg", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Phospor (P)"),
                                  Text("${pController.text} mg/kg", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Kalium (K)"),
                                  Text("${kController.text} mg/kg", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(height: 30, thickness: 1),
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                  children: [
                                    TextSpan(text: 'Saat ini tanaman anda berada di fase '),
                                    TextSpan(text: '"$faseTanaman"', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: ' dengan kadar unsur hara '),
                                    TextSpan(text: '"$luasDerajat"', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: ' dan hasil perhitungan fuzzi mamdani '),
                                    TextSpan(text: '"$hasilKesuburan"', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '. Anda dianjurkan menambahkan pupuk '),
                                    TextSpan(text: '"$rekomendasiPupuk"', style: TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: '.'), 
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}





  // Widget untuk kotak plot
  Widget _buildPlotBox(String plotName, String plotKey) {
    bool isSelected = selectedPlot == plotName;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlot = plotName;
          listenToPlotData(plotKey);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_florist,
                color: isSelected ? Colors.white : Colors.green,
                size: 30,
              ),
            ),
            SizedBox(height: 8),
            Text(
              plotName,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.green[900],
                fontSize: 12,
              ),
            ),
          ],
        ),
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
          color: isSelected ? Colors.white : Colors.white,
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
          Flexible(
            child: Text(
              'Perangkat : $plotName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
              ),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
      ),
      );
  }
}
