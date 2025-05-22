import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tưới tiêu thông minh',
      theme: ThemeData(primarySwatch: Colors.green),
      home: PumpControlScreen(),
    );
  }
}

class PumpControlScreen extends StatefulWidget {
  const PumpControlScreen({super.key});
  @override
  PumpControlScreenState createState() => PumpControlScreenState();
}

class PumpControlScreenState extends State<PumpControlScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  int soilValue = 0;
  int pumpStatus = 0;
  String mode = 'auto';
  int threshold = 400;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _db.child('soil/value').onValue.listen((event) {
      setState(() {
        soilValue = event.snapshot.value as int;
      });
    });

    _db.child('pump/status').onValue.listen((event) {
      setState(() {
        pumpStatus = event.snapshot.value as int;
      });
    });

    _db.child('pump/mode').onValue.listen((event) {
      setState(() {
        mode = event.snapshot.value.toString();
      });
    });
  }

  void _togglePump() {
    _db.child('pump/status').set(pumpStatus == 1 ? 0 : 1);
  }

  void _toggleMode() {
    String newMode = mode == 'auto' ? 'manual' : 'auto';
    _db.child('pump/mode').set(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hệ thống tưới tiêu')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Độ ẩm đất: $soilValue', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('Chế độ: ${mode.toUpperCase()}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            if (mode == 'manual')
              ElevatedButton(
                onPressed: _togglePump,
                child: Text(pumpStatus == 1 ? 'Tắt bơm' : 'Bật bơm'),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleMode,
              child: Text('Chuyển sang chế độ ${mode == 'auto' ? 'MANUAL' : 'AUTO'}'),
            ),
          ],
        ),
      ),
    );
  }
}
