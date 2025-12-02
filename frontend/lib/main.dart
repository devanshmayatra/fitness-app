import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- CONFIGURATION ---
const String baseUrl = 'https://fitness-app-0uue.onrender.com';

// --- AESTHETIC THEME COLORS (Volt & Black) ---
const Color kBackgroundColor = Color(0xFF000000);
const Color kSurfaceColor = Color(0xFF1C1C1E);
const Color kAccentColor = Color(0xFFCEF20D); // Volt Green
const Color kBlueAccent = Color(0xFF00C7FC); // Electric Blue
const Color kSecondaryAccent = Color(0xFFFFFFFF);
const Color kSubTextColor = Color(0xFF8E8E93);

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

// --- PROVIDER ---
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
      if (cachedData != null) _schedule = jsonDecode(cachedData);
    } catch (e) {
      print(e);
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
      print(e);
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
        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kSecondaryAccent,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
          iconTheme: IconThemeData(color: kSecondaryAccent),
        ),
        cardTheme: CardThemeData(
          color: kSurfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: kAccentColor,
          surface: kSurfaceColor,
          onSurface: kSecondaryAccent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccentColor),
          ),
          hintStyle: TextStyle(color: kSubTextColor.withOpacity(0.5)),
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
      body: SafeArea(
        // Fixed: Content hidden behind navbar
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader("PLANNING"),
                _MenuButton(
                  icon: Icons.calendar_today_rounded,
                  label: "SCHEDULE",
                  subLabel: "Weekly Plan",
                  gradient: const LinearGradient(
                    colors: [kAccentColor, Color(0xFFAACC00)],
                  ),
                  textColor: Colors.black,
                  iconColor: Colors.black,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _MenuButton(
                  icon: Icons.list_alt_rounded,
                  label: "PROTOCOLS",
                  subLabel: "Diet & Instructions",
                  color: kSurfaceColor,
                  textColor: kSecondaryAccent,
                  iconColor: kSecondaryAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InstructionsScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const _SectionHeader("ACTION"),
                Row(
                  children: [
                    Expanded(
                      child: _SmallMenuButton(
                        icon: Icons.add_circle_outline,
                        label: "LOG\nWEIGHTS",
                        color: kSurfaceColor,
                        iconColor: kAccentColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkoutLogger(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SmallMenuButton(
                        icon: Icons.camera_alt_outlined,
                        label: "SCAN\nCARDIO",
                        color: kSurfaceColor,
                        iconColor: kBlueAccent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CardioScanner(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const _SectionHeader("DATA"),
                _MenuButton(
                  icon: Icons.history_rounded,
                  label: "HISTORY LOGS",
                  subLabel: "View all workouts",
                  color: kSurfaceColor,
                  textColor: kSecondaryAccent,
                  iconColor: kSubTextColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LogsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 1: INSTRUCTIONS MANAGER ---
class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});
  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  List<dynamic> _instructions = [];
  final _controller = TextEditingController();
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  Future<void> _loadInstructions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/data?sheet=Instructions'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _instructions = jsonDecode(response.body)['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addInstruction() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isAdding = true);
    try {
      await http.post(
        Uri.parse('$baseUrl/submit'),
        body: jsonEncode({
          "target_sheet": "Instructions",
          "row_data": [_controller.text],
        }),
      );
      _controller.clear();
      _loadInstructions(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PROTOCOLS")),
      body: SafeArea(
        // Fixed: Input field hidden behind navbar
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kAccentColor),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _instructions.length,
                      itemBuilder: (context, index) {
                        final row = _instructions[index];
                        String text = row.isNotEmpty ? row[0].toString() : "";
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: kAccentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kSurfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Add new rule...",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _isAdding ? null : _addInstruction,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.arrow_upward),
                    style: IconButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 2: LOGS VIEWER (Filterable) ---
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<dynamic> _allLogs = [];
  List<dynamic> _filteredLogs = [];
  bool _isLoading = true;
  String _filter = "All"; // All, Weights, Cardio

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/data?sheet=Logs'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List<dynamic>;
        setState(() {
          // Reverse to show newest first
          _allLogs = data.reversed.toList();
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    if (_filter == "All") {
      _filteredLogs = _allLogs;
    } else if (_filter == "Cardio") {
      _filteredLogs = _allLogs
          .where((row) => row.isNotEmpty && row[0].toString() == "Cardio")
          .toList();
    } else {
      _filteredLogs = _allLogs
          .where(
            (row) => row.isNotEmpty && row[0].toString() == "Weight Training",
          )
          .toList();
    }
  }

  void _setFilter(String f) {
    setState(() {
      _filter = f;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HISTORY")),
      body: SafeArea(
        // Fixed: List content hidden behind navbar
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FilterChip("All", _filter == "All", () => _setFilter("All")),
                  const SizedBox(width: 12),
                  _FilterChip(
                    "Weights",
                    _filter == "Weights",
                    () => _setFilter("Weights"),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    "Cardio",
                    _filter == "Cardio",
                    () => _setFilter("Cardio"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kAccentColor),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        final row = _filteredLogs[index];
                        // Row structure: [Type, Date, Details, (Cardio: Duration, Dist, Cals)]
                        if (row.isEmpty) return const SizedBox();

                        String type = row[0].toString();
                        String dateRaw = row.length > 1
                            ? row[1].toString()
                            : "";
                        // Simple date parser to remove seconds
                        String date = dateRaw.length > 16
                            ? dateRaw.substring(0, 16)
                            : dateRaw;
                        String details = row.length > 2
                            ? row[2].toString()
                            : "";

                        bool isCardio = type == "Cardio";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(
                                color: isCardio ? kBlueAccent : kAccentColor,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Badge(
                                    backgroundColor: isCardio
                                        ? kBlueAccent.withOpacity(0.2)
                                        : kAccentColor.withOpacity(0.2),
                                    label: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        color: isCardio
                                            ? kBlueAccent
                                            : kAccentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      color: kSubTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isCardio && row.length > 5) ...[
                                // Cardio Specific Layout
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StatItem(
                                      value: row[3],
                                      label: "TIME",
                                      icon: Icons.timer,
                                    ),
                                    _StatItem(
                                      value: row[4],
                                      label: "DIST",
                                      icon: Icons.directions_run,
                                    ),
                                    _StatItem(
                                      value: row[5],
                                      label: "CAL",
                                      icon: Icons.local_fire_department,
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // Weight Training Layout
                                Text(
                                  details,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: kSecondaryAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- SCREEN 3: SCHEDULE VIEWER ---
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("WEEKLY PLAN")),
      body: SafeArea(
        // Fixed: List hidden behind navbar
        child: provider.isLoading && provider.schedule.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: kAccentColor),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: provider.schedule.length,
                itemBuilder: (context, index) {
                  final row = provider.schedule[index];
                  String day = row.length > 0
                      ? row[0].toString().replaceAll("Day ", "")
                      : "";
                  String title = row.length > 1 ? row[1].toString() : "";
                  String details = row.length > 2 ? row[2].toString() : "";
                  //workout starts from Tuesday
                  bool isToday = DateTime.now().weekday == (index + 2);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isToday ? Border.all(color: kAccentColor) : null,
                    ),
                    child: ExpansionTile(
                      iconColor: kAccentColor,
                      collapsedIconColor: kSubTextColor,
                      leading: CircleAvatar(
                        backgroundColor: isToday ? kAccentColor : Colors.black,
                        child: Text(
                          day,
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
                          fontSize: 15,
                          color: isToday ? kAccentColor : kSecondaryAccent,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              details,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: kSubTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// --- SCREEN 4: WORKOUT LOGGER ---
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
    if (_selectedWorkout == null && _detailsController.text.isEmpty) return;
    setState(() => _isSaving = true);
    String finalLog =
        (_selectedWorkout != null ? "$_selectedWorkout\n" : "") +
        (_detailsController.text.isNotEmpty
            ? "Notes: ${_detailsController.text}"
            : "");
    try {
      await http.post(
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      /* Error */
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleProvider>().schedule;
    return Scaffold(
      appBar: AppBar(title: const Text("LOG WORKOUT")),
      body: SafeArea(
        // Fixed: Button hidden behind navbar
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                isExpanded:
                    true, // Fixed: Prevents RenderFlex overflow on long text
                hint: const Text("Select Day..."),
                value: _selectedWorkout,
                dropdownColor: kSurfaceColor,
                items: schedule
                    .map<DropdownMenuItem<String>>(
                      (r) => DropdownMenuItem(
                        value: "${r[0]}: ${r.length > 1 ? r[1] : ''}",
                        child: Text(
                          "${r[0]}: ${r.length > 1 ? r[1] : ''}",
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedWorkout = v),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _detailsController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "Enter weights, reps, notes...",
                ),
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
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : const Text(
                          "SAVE LOG",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 5: CARDIO SCANNER ---
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Success! Auto-saved to Google Sheets ✅"),
            ),
          );
      } else {
        // ERROR HANDLING: If the backend fails, show the error code
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Server Error: ${response.statusCode} - ${response.body}",
              ),
            ),
          );
      }
    } catch (e) {
      // CONNECTION ERROR: If the backend is unreachable
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connection Error: $e. Check server & IP.")),
        );
    }
    setState(() => _isAnalyzing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI SCANNER")),
      body: SafeArea(
        // Fixed: Content hidden behind navbar
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isAnalyzing ? null : _scanPhoto,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _isAnalyzing ? kBlueAccent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.center_focus_weak,
                          size: 50,
                          color: kBlueAccent,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isAnalyzing ? "ANALYZING..." : "TAP TO SCAN",
                          style: const TextStyle(
                            color: kBlueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (_result != null) ...[
                  _StatItem(
                    value: _result!['duration'] ?? "--",
                    label: "TIME",
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: 10),
                  _StatItem(
                    value: _result!['distance'] ?? "--",
                    label: "DIST",
                    icon: Icons.directions_run,
                  ),
                  const SizedBox(height: 10),
                  _StatItem(
                    value: _result!['calories'] ?? "--",
                    label: "CAL",
                    icon: Icons.local_fire_department,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS ---
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: kSubTextColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kSubTextColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kSecondaryAccent,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: kSubTextColor)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.isSelected, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kAccentColor : kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : kSecondaryAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label, subLabel;
  final Color? color;
  final Gradient? gradient;
  final Color textColor, iconColor;
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 90,
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
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
                Icons.arrow_forward_ios,
                color: textColor.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;
  const _SmallMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kSecondaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
