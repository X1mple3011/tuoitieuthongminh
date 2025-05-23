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
  TimeOfDay? scheduledTime;
  int durationMinutes = 5;

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _db.child('soil/value').onValue.listen((event) {
      setState(() {
        soilValue = event.snapshot.value as int? ?? 0;
      });
    });

    _db.child('pump/status').onValue.listen((event) {
      setState(() {
        pumpStatus = event.snapshot.value as int? ?? 0;
      });
    });

    _db.child('pump/mode').onValue.listen((event) {
      setState(() {
        mode = event.snapshot.value.toString();
      });
    });

    _db.child('pump/schedule').onValue.listen((event) {
      final val = event.snapshot.value;
      if (val != null && val is String) {
        final parts = val.split(":");
        if (parts.length == 2) {
          scheduledTime = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 0,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        }
      }
    });

    _db.child('pump/duration').onValue.listen((event) {
      setState(() {
        durationMinutes = event.snapshot.value as int? ?? 5;
      });
    });
  }

  void _togglePump() async {
    final newStatus = pumpStatus == 1 ? 0 : 1;
    await _db.child('pump/status').set(newStatus);
    if (newStatus == 1) {
      Future.delayed(Duration(minutes: durationMinutes), () {
        _db.child('pump/status').set(0);
      });
    }
  }

  void _toggleMode() {
    String newMode = mode == 'auto' ? 'manual' : 'auto';
    _db.child('pump/mode').set(newMode);
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => scheduledTime = picked);
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _db.child('pump/schedule').set(timeStr);
    }
  }

  void _selectDuration() async {
    final controller = TextEditingController(text: durationMinutes.toString());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thời gian tưới (phút)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                _db.child('pump/duration').set(val);
                setState(() => durationMinutes = val);
              }
              Navigator.of(ctx).pop();
            },
            child: Text('Lưu'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = scheduledTime != null
        ? '${scheduledTime!.hour.toString().padLeft(2, '0')}:${scheduledTime!.minute.toString().padLeft(2, '0')}'
        : 'Chưa đặt giờ';

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
            Column(
              children: [
                Text('Giờ bắt đầu tưới: $timeStr', style: TextStyle(fontSize: 18)),
                ElevatedButton(
                  onPressed: _selectTime,
                  child: Text('Chọn giờ tưới'),
                ),
                SizedBox(height: 10),
                Text('Thời lượng tưới: $durationMinutes phút', style: TextStyle(fontSize: 18)),
                ElevatedButton(
                  onPressed: _selectDuration,
                  child: Text('Chỉnh thời lượng tưới'),
                ),
              ],
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
