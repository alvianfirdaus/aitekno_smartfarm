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
    String plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
    DatabaseReference ref = FirebaseDatabase.instance.ref('$plotKey/zhistory');
    DataSnapshot snapshot = await ref.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      double totalN = 0, totalP = 0, totalK = 0;
      int jumlah = 0;

      String bulanSekarang = DateFormat('MM').format(DateTime.now());

      data.forEach((date, timeData) {
        if (date.substring(5, 7) == bulanSekarang) {
          (timeData as Map).forEach((time, values) {
            if (values != null && values is Map) {
              double n = (values['n'] ?? 0).toDouble();
              double p = (values['p'] ?? 0).toDouble();
              double k = (values['k'] ?? 0).toDouble();

              totalN += n;
              totalP += p;
              totalK += k;
              jumlah++;
            }
          });
        }
      });

      if (jumlah > 0) {
        setState(() {
          nController.text = (totalN / jumlah).toStringAsFixed(1);
          pController.text = (totalP / jumlah).toStringAsFixed(1);
          kController.text = (totalK / jumlah).toStringAsFixed(1);
        });
      } else {
        print("Tidak ada data bulan ini.");
      }
    } else {
      print("Data tidak ditemukan.");
    }
  }

  double rendah(double x) => x <= 50 ? 1.0 : x <= 100 ? (100 - x) / 50 : 0.0;
  double sedang(double x) => x <= 50 ? 0.0 : x <= 100 ? (x - 50) / 50 : x <= 150 ? (150 - x) / 50 : 0.0;
  double tinggi(double x) => x <= 100 ? 0.0 : x <= 150 ? (x - 100) / 50 : 1.0;

  final List<Map<String, String>> rules = [
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Rendah', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA + SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Sedang', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA + SP-36', 'generatif': 'SP-36'},
    {'n': 'Rendah', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA + SP-36', 'generatif': 'SP-36'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Rendah', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA + KCl', 'generatif': 'KCl'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Sedang', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA', 'generatif': 'NPK rendah N'},
    {'n': 'Rendah', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'unsur hara sedang', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'unsur hara rendah', 'vegetatif': 'Urea/ZA + KCl', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'unsur hara sedang', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Rendah', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'unsur hara sedang', 'vegetatif': 'Urea/ZA', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Rendah', 'output': 'unsur hara rendah', 'vegetatif': 'SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Sedang', 'output': 'unsur hara sedang', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Sedang', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'unsur hara sedang', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Rendah', 'output': 'unsur hara sedang', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Sedang', 'output': 'unsur hara sedang', 'vegetatif': 'NPK 15-15-15', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'unsur hara sedang', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Sedang', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'P dan K sesuai'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Rendah', 'output': 'unsur hara sedang', 'vegetatif': 'SP-36 + KCl', 'generatif': 'SP-36 + KCl'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Sedang', 'output': 'unsur hara sedang', 'vegetatif': 'SP-36', 'generatif': 'SP-36'},
    {'n': 'Tinggi', 'p': 'Rendah', 'k': 'Tinggi', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Rendah', 'output': 'unsur hara sedang', 'vegetatif': 'KCl', 'generatif': 'KCl'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Sedang', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Sedang', 'k': 'Tinggi', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Rendah', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Sedang', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
    {'n': 'Tinggi', 'p': 'Tinggi', 'k': 'Tinggi', 'output': 'unsur hara tinggi', 'vegetatif': 'Tidak perlu', 'generatif': 'Tidak perlu'},
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
      'unsur hara rendah': 0.0,
      'unsur hara sedang': 0.0,
      'unsur hara tinggi': 0.0,
    };
    Map<String, String> pupukPilihan = {
      'unsur hara rendah': '',
      'unsur hara sedang': '',
      'unsur hara tinggi': '',
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
    double ts_ls = 1 / 2 * 25 * 1; // Luas derajat kurva keanggotaan output
    double ts_dk1 = 25 + (ts_ls * alphaMax['unsur hara rendah']!); // Domain terkecil (dynamic based on implication)
    double ts_dk = ts_dk1 - 25; // Domain terkecil
    double ts_db1 = 50 - (ts_ls * alphaMax['unsur hara rendah']!);
    double ts_db = ts_db1 - 25;
    double ts_ab = ts_db - ts_dk;
    double ts_t = 1 - alphaMax['unsur hara rendah']!;
    double ts_lb = alphaMax['unsur hara rendah']! * ts_ab * ts_t;
    double ts_ls1 = ts_ls - ts_lb;
    double ts_m = 25 * ts_ls1;
    double ts_c10 = alphaMax['unsur hara rendah']! * ts_m;
    double ts_d10 = alphaMax['unsur hara rendah']! * ts_ls1;

    // ---------------------------Menghitung agregasi Cukup Subur
    double cs_ls = 1 / 2 * 40 * 1; // Luas derajat kurva keanggotaan output
    double cs_dk1 = 40 + (cs_ls * alphaMax['unsur hara sedang']!); // Domain terkecil (dynamic based on implication)
    double cs_dk = cs_dk1 - 40; // Domain terkecil
    double cs_db1 = 80 - (cs_ls * alphaMax['unsur hara sedang']!);
    double cs_db = cs_db1 - 40;
    double cs_ab = cs_db - cs_dk;
    double cs_t = 1 - alphaMax['unsur hara sedang']!;
    double cs_lb = alphaMax['unsur hara sedang']! * cs_ab * cs_t;
    double cs_ls1 = cs_ls - cs_lb;
    double cs_m = 60 * cs_ls1;
    double cs_c10 = alphaMax['unsur hara sedang']! * cs_m;
    double cs_d10 = alphaMax['unsur hara sedang']! * cs_ls1;

    // -------------------------------------Menghitung agregasi Subur
    double s_ls = 1 / 2 * 30 * 1; // Luas derajat kurva keanggotaan output
    double s_dk1 = 30 + (s_ls * alphaMax['unsur hara tinggi']!); // Domain terkecil (dynamic based on implication)
    double s_dk = s_dk1 - 30; // Domain terkecil
    double s_db1 = 100 - (s_ls * alphaMax['unsur hara tinggi']!);
    double s_db = s_db1 - 30;
    double s_ab = s_db - s_dk;
    double s_t = 1 - alphaMax['unsur hara tinggi']!;
    double s_lb = alphaMax['unsur hara tinggi']! * s_ab * s_t;
    double s_ls1 = s_ls - s_lb;
    double s_m = 86 * s_ls1;
    double s_c10 = alphaMax['unsur hara tinggi']! * s_m;
    double s_d10 = alphaMax['unsur hara tinggi']! * s_ls1;

    //-----------------------------------Defuzzifikasi W (menggunakan formula yang diberikan)
    double numerator = ts_c10 + cs_c10 + s_c10;
    double denominator = ts_d10 + cs_d10 + s_d10;
    double result = numerator / denominator;


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
        // Gambar Header
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

        // Plot Mengambang di Tengah
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

        // Isi Konten
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
                                    TextSpan(
                                      text: '"$faseTanaman"',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: ' dengan kadar unsur hara '),
                                    TextSpan(
                                      text: '"$luasDerajat"',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: ' dan hasil perhitungan fuzzi mamdani '),
                                    TextSpan(
                                      text: '"$hasilKesuburan"',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: '. Anda dianjurkan menambahkan pupuk '),
                                    TextSpan(
                                      text: '"$rekomendasiPupuk"',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
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
