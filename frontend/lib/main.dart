import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CONFIGURATION ---
const String baseUrl = 'http://localhost:8080';

// --- AESTHETIC THEME COLORS (Volt & Black) ---
const Color kBackgroundColor = Color(0xFF000000); // Pure Black (OLED)
const Color kSurfaceColor = Color(0xFF1C1C1E); // Dark Gray (iOS System Gray)
const Color kAccentColor = Color(0xFFCEF20D); // Volt Green (Fitness Energy)
const Color kSecondaryAccent = Color(
  0xFFFFFFFF,
); // White for high contrast text
const Color kSubTextColor = Color(0xFF8E8E93); // Subtle gray text

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider()..loadSchedule(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// --- PROVIDER (Unchanged Logic) ---
class ScheduleProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _schedule = [];
  bool _isLoading = false;

  List<dynamic> get schedule => _schedule;
  bool get isLoading => _isLoading;

  Future<void> loadSchedule() async {
    _isLoading = true;
    notifyListeners();
    try {
      String? cachedData = await _storage.read(key: 'cached_schedule');
      if (cachedData != null) {
        _schedule = jsonDecode(cachedData);
      }
    } catch (e) {
      print("Storage Error: $e");
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data?sheet=Schedule'),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _schedule = jsonResponse['data'];
        await _storage.write(
          key: 'cached_schedule',
          value: jsonEncode(_schedule),
        );
      }
    } catch (e) {
      print("API Error: $e");
    }
    _isLoading = false;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jan 10 Sprint',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBackgroundColor,
        primaryColor: kAccentColor,
        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kSecondaryAccent,
            fontSize: 22,
            fontWeight: FontWeight.w900, // Extra Bold Title
            letterSpacing: 1.0,
          ),
          iconTheme: IconThemeData(color: kSecondaryAccent),
        ),
        // Card Theme
        cardTheme: CardThemeData(
          color: kSurfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kSubTextColor.withOpacity(0.2), width: 1),
          ),
        ),
        // Color Scheme
        colorScheme: const ColorScheme.dark(
          primary: kAccentColor,
          surface: kSurfaceColor,
          onPrimary: kBackgroundColor,
          onSurface: kSecondaryAccent,
        ),
        // Text Theme
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kSecondaryAccent),
          bodyMedium: TextStyle(color: kSubTextColor),
          titleMedium: TextStyle(
            color: kSecondaryAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kAccentColor, width: 2),
          ),
          hintStyle: TextStyle(color: kSubTextColor.withOpacity(0.5)),
          labelStyle: const TextStyle(color: kSubTextColor),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("JAN 10 SPRINT")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "DASHBOARD",
                style: TextStyle(
                  color: kSubTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 20),
              _MenuButton(
                icon: Icons.calendar_today_rounded,
                label: "MY SCHEDULE",
                subLabel: "View your weekly plan",
                // Gradient for primary action
                gradient: const LinearGradient(
                  colors: [kAccentColor, Color(0xFFAACC00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                textColor: Colors.black, // Dark text on bright button
                iconColor: Colors.black,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _MenuButton(
                icon: Icons.add_circle_outline_rounded,
                label: "LOG WORKOUT",
                subLabel: "Track weights & reps",
                color: kSurfaceColor,
                textColor: kSecondaryAccent,
                iconColor: kAccentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutLogger()),
                ),
              ),
              const SizedBox(height: 20),
              _MenuButton(
                icon: Icons.camera_alt_outlined,
                label: "SCAN CARDIO",
                subLabel: "AI Auto-Logger",
                color: kSurfaceColor,
                textColor: kSecondaryAccent,
                iconColor: Colors.cyanAccent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CardioScanner()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 1: SCHEDULE VIEWER ---
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("WEEKLY PLAN")),
      body: provider.isLoading && provider.schedule.isEmpty
          ? const Center(child: CircularProgressIndicator(color: kAccentColor))
          : provider.schedule.isEmpty
          ? Center(
              child: Text(
                "No data. Seed backend.",
                style: TextStyle(color: kSubTextColor),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: provider.schedule.length,
              itemBuilder: (context, index) {
                final row = provider.schedule[index];
                String day = row.length > 0 ? row[0].toString() : "";
                String title = row.length > 1 ? row[1].toString() : "";
                String details = row.length > 2 ? row[2].toString() : "";

                bool isToday =
                    DateTime.now().weekday == (index + 1); // Simple check

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: isToday
                        ? Border.all(color: kAccentColor, width: 1)
                        : null,
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: kAccentColor,
                      collapsedIconColor: kSubTextColor,
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isToday ? kAccentColor : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          day.replaceAll("Day ", ""),
                          style: TextStyle(
                            color: isToday ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isToday ? kAccentColor : kSecondaryAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              details,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: kSubTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --- SCREEN 2: WORKOUT LOGGER ---
class WorkoutLogger extends StatefulWidget {
  const WorkoutLogger({super.key});
  @override
  State<WorkoutLogger> createState() => _WorkoutLoggerState();
}

class _WorkoutLoggerState extends State<WorkoutLogger> {
  final _detailsController = TextEditingController();
  String? _selectedWorkout;
  bool _isSaving = false;

  Future<void> _submitLog() async {
    if (_selectedWorkout == null && _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please add details")));
      return;
    }
    setState(() => _isSaving = true);
    String finalLog =
        (_selectedWorkout != null ? "$_selectedWorkout\n" : "") +
        (_detailsController.text.isNotEmpty
            ? "Notes: ${_detailsController.text}"
            : "");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submit'),
        body: jsonEncode({
          "target_sheet": "Logs",
          "row_data": [
            "Weight Training",
            DateTime.now().toString().split('.')[0],
            finalLog,
          ],
        }),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("LOGGED SUCCESSFULLY ✅")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>().schedule;

    return Scaffold(
      appBar: AppBar(title: const Text("LOG WORKOUT")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label("SELECT DAY"),
            DropdownButtonFormField<String>(
              isExpanded: true,
              hint: Text(
                "Choose workout...",
                style: TextStyle(color: kSubTextColor),
              ),
              value: _selectedWorkout,
              icon: Icon(Icons.keyboard_arrow_down, color: kAccentColor),
              dropdownColor: kSurfaceColor,
              items: schedule.map<DropdownMenuItem<String>>((row) {
                String label =
                    "${row.length > 0 ? row[0] : 'Day ?'}: ${row.length > 1 ? row[1] : ''}";
                return DropdownMenuItem(
                  value: label,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedWorkout = v),
            ),
            const SizedBox(height: 24),
            _Label("DETAILS & WEIGHTS"),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                hintText: "e.g. Bench: 60kg 5x5...",
              ),
              maxLines: 6,
              style: const TextStyle(color: kSecondaryAccent),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "SAVE LOG",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 3: CARDIO SCANNER ---
class CardioScanner extends StatefulWidget {
  const CardioScanner({super.key});
  @override
  State<CardioScanner> createState() => _CardioScannerState();
}

class _CardioScannerState extends State<CardioScanner> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;

  Future<void> _scanPhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/analyze-image'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', photo.path));
      var response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        setState(() => _result = jsonDecode(response.body));
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("AUTO-LOGGED ✅")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI SCANNER")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _isAnalyzing ? null : _scanPhoto,
                child: Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isAnalyzing ? kAccentColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kAccentColor.withOpacity(0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.center_focus_weak,
                          size: 50,
                          color: kAccentColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isAnalyzing ? "ANALYZING..." : "TAP TO SCAN",
                        style: TextStyle(
                          color: kSecondaryAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_result != null) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "RESULTS",
                    style: TextStyle(
                      color: kSubTextColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _ResultRow(label: "TIME", value: _result!['duration'] ?? "--"),
                _ResultRow(
                  label: "DISTANCE",
                  value: _result!['distance'] ?? "--",
                ),
                _ResultRow(
                  label: "CALORIES",
                  value: _result!['calories'] ?? "--",
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS ---

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: kSubTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kSubTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kAccentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color? color;
  final Gradient? gradient;
  final Color textColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.subLabel,
    this.color,
    this.gradient,
    required this.textColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: color,
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      subLabel,
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textColor.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
