import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── NOTIFICATIONS ─────────────────────────────────────────────────────────
final FlutterLocalNotificationsPlugin _notifs =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifs.initialize(const InitializationSettings(android: android));
}

Future<void> sendNightlyReport(double totalGB, String topApp) async {
  const channel = AndroidNotificationDetails(
    'daily_report',
    'Daily Data Report',
    channelDescription: 'Nightly data usage summary',
    importance: Importance.high,
    priority: Priority.high,
  );
  await _notifs.show(
    0,
    '📊 Daily Data Report',
    'You used ${totalGB.toStringAsFixed(1)} GB today. $topApp was your top app.',
    const NotificationDetails(android: channel),
  );
}

// ── MAIN ──────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('dataUsage');
  await initNotifications();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const DataTrackerApp());
}

// ── APP MODEL ─────────────────────────────────────────────────────────────
class AppUsage {
  final String name, emoji;
  final Color color;
  final double mb;
  AppUsage(this.name, this.emoji, this.color, this.mb);
  String get display => mb >= 1024
      ? '${(mb / 1024).toStringAsFixed(1)} GB'
      : '${mb.toStringAsFixed(0)} MB';
}

// Demo data — replace with real data after installing on phone
final List<AppUsage> demoApps = [
  AppUsage('Facebook', '📘', const Color(0xFF1877F2), 1800),
  AppUsage('WhatsApp', '💬', const Color(0xFF25D366), 1200),
  AppUsage('YouTube', '▶', const Color(0xFFFF0000), 900),
  AppUsage('Instagram', '📸', const Color(0xFFE1306C), 500),
  AppUsage('Chrome', '🌐', const Color(0xFF4285F4), 250),
  AppUsage('Gmail', '📧', const Color(0xFFEA4335), 150),
];

double get totalMB => demoApps.fold(0, (s, a) => s + a.mb);
double get totalGB => totalMB / 1024;

// ── APP ROOT ──────────────────────────────────────────────────────────────
class DataTrackerApp extends StatelessWidget {
  const DataTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C6CFA),
          surface: Color(0xFF16161F),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ── BOTTOM NAV ────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _pages = const [
    HomeScreen(),
    ReportScreen(),
    TipsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF16161F),
        selectedItemColor: const Color(0xFF7C6CFA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Report'),
          BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb_outline),
              activeIcon: Icon(Icons.lightbulb),
              label: 'Tips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// ── SHARED ────────────────────────────────────────────────────────────────
Widget kCard({required Widget child}) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: child,
    );

Widget kLabel(String t) => Text(t.toUpperCase(),
    style: const TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1));

// ── HOME ──────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Send nightly notification when app opens
    Future.delayed(const Duration(seconds: 2), () {
      sendNightlyReport(totalGB, demoApps[0].name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final limitGB =
        (Hive.box('dataUsage').get('dailyLimit', defaultValue: 6.0) as num)
            .toDouble();
    final pct = (totalGB / limitGB).clamp(0.0, 1.0);
    final remaining = (limitGB - totalGB).clamp(0.0, limitGB);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Data Tracker',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE8E8F0))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF16161F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2A2A3A))),
                child: const Text('Today',
                    style: TextStyle(fontSize: 12, color: Colors.grey))),
          ]),
          const SizedBox(height: 16),

          // Notification card
          kCard(
              child: Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFF7C6CFA).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications,
                    color: Color(0xFF7C6CFA), size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Nightly report sent at 10:00 PM',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE0E0EE),
                          fontWeight: FontWeight.w600)),
                  Text('You used ${totalGB.toStringAsFixed(1)} GB today.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
          ])),

          // Donut chart
          Center(
            child: SizedBox(
                height: 180,
                width: 180,
                child: Stack(alignment: Alignment.center, children: [
                  PieChart(PieChartData(
                    sections: [
                      PieChartSectionData(
                          value: pct * 100,
                          color: const Color(0xFF7C6CFA),
                          radius: 28,
                          title: ''),
                      PieChartSectionData(
                          value: (1 - pct) * 100,
                          color: const Color(0xFF1E1E2B),
                          radius: 28,
                          title: ''),
                    ],
                    centerSpaceRadius: 64,
                    sectionsSpace: 3,
                  )),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('${totalGB.toStringAsFixed(1)} GB',
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE8E8F0))),
                    const Text('used today',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text('of ${limitGB.toStringAsFixed(0)} GB limit',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7C6CFA))),
                  ]),
                ])),
          ),
          const SizedBox(height: 16),

          // Stat cards
          Row(children: [
            _stat('${(totalGB * 0.44).toStringAsFixed(1)} GB', 'Mobile',
                const Color(0xFF7C6CFA)),
            const SizedBox(width: 10),
            _stat('${(totalGB * 0.56).toStringAsFixed(1)} GB', 'WiFi',
                const Color(0xFF4AB8D8)),
            const SizedBox(width: 10),
            _stat('${remaining.toStringAsFixed(1)} GB', 'Left',
                Colors.greenAccent),
          ]),
          const SizedBox(height: 20),

          kLabel('top apps today'),
          const SizedBox(height: 10),
          ...demoApps.map((a) => _appRow(a)),
        ]),
      ),
    );
  }

  Widget _stat(String val, String label, Color dot) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A3A))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(val,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE8E8F0))),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: dot, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ]),
        ),
      );

  Widget _appRow(AppUsage a) {
    final pct = a.mb / totalMB;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFF1E1E2B)))),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: a.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(a.emoji, style: const TextStyle(fontSize: 18)))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.name,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC8C8D8),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFF1E1E2B),
                  valueColor: AlwaysStoppedAnimation(a.color),
                  minHeight: 4)),
        ])),
        const SizedBox(width: 10),
        Text(a.display,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7C6CFA),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ── REPORT ────────────────────────────────────────────────────────────────
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final weekData = [3.2, 5.1, 2.8, 4.4, 6.0, 4.8, 0.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Report',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8E8F0))),
          const SizedBox(height: 4),
          const Text('Saturday, March 14',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          kCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                kLabel('7-day usage'),
                const SizedBox(height: 16),
                SizedBox(
                    height: 160,
                    child: BarChart(BarChartData(
                      barGroups: List.generate(
                          7,
                          (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: weekData[i],
                                    color: i == 5
                                        ? const Color(0xFF7C6CFA)
                                        : const Color(0xFF2A2A4A),
                                    width: 26,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(5)),
                                  )
                                ],
                              )),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => Text(days[v.toInt()],
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)))),
                      ),
                      gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                              color: Color(0xFF1E1E2B), strokeWidth: 1)),
                      borderData: FlBorderData(show: false),
                      maxY: 8,
                    ))),
              ])),
          kCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                kLabel('all apps today'),
                const SizedBox(height: 12),
                ...demoApps.map((a) {
                  final pct = ((a.mb / totalMB) * 100).toStringAsFixed(0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Text(a.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(a.name,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFFC8C8D8)))),
                      Text('$pct%',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      Text(a.display,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7C6CFA),
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }),
              ])),
        ]),
      ),
    );
  }
}

// ── TIPS ──────────────────────────────────────────────────────────────────
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const _tips = [
    (
      Icons.videocam_off,
      'Disable Facebook video autoplay',
      'Facebook Settings → Videos → turn off autoplay. Saves 500 MB/day.'
    ),
    (
      Icons.timer,
      'Set a screen time limit',
      'Settings → Digital Wellbeing → set 2-hour daily limit for social apps.'
    ),
    (
      Icons.wifi,
      'WiFi only for heavy apps',
      'Set YouTube and Netflix to WiFi only mode inside each app settings.'
    ),
    (
      Icons.data_saver_on,
      'Enable Data Saver mode',
      'Settings → Network → Data Saver. Reduces background usage by 40%.'
    ),
    (
      Icons.phonelink_off,
      'Restrict background data',
      'Settings → Apps → select app → Data Usage → restrict background.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Smart Tips',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8E8F0))),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1218),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF5A2A3A))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.warning_amber, color: Color(0xFFF09898), size: 18),
                SizedBox(width: 8),
                Text('High usage detected!',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF09898),
                        fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text(
                  'You used ${totalGB.toStringAsFixed(1)} GB today. '
                  'Social media used 73% of your data.',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFA07080), height: 1.5)),
            ]),
          ),
          ..._tips.map((t) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A1630),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3A2F6A))),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: const Color(0xFF7C6CFA).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(t.$1,
                              color: const Color(0xFF7C6CFA), size: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(t.$2,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFC0B8F0),
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(t.$3,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7870A8),
                                    height: 1.5)),
                          ])),
                    ]),
              )),
        ]),
      ),
    );
  }
}

// ── SETTINGS ──────────────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _limit = 6.0;
  int _hour = 22;
  bool _addiction = true;
  bool _tips = true;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('dataUsage');
    _limit = (box.get('dailyLimit', defaultValue: 6.0) as num).toDouble();
    _hour = box.get('reportHour', defaultValue: 22) as int;
    _addiction = box.get('addictionAlerts', defaultValue: true) as bool;
    _tips = box.get('dailyTips', defaultValue: true) as bool;
  }

  void _save(String k, dynamic v) => Hive.box('dataUsage').put(k, v);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Settings',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8E8F0))),
          const SizedBox(height: 20),
          kCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                kLabel('daily data limit'),
                const SizedBox(height: 12),
                Slider(
                    value: _limit,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    activeColor: const Color(0xFF7C6CFA),
                    inactiveColor: const Color(0xFF2A2A3A),
                    onChanged: (v) {
                      setState(() => _limit = v);
                      _save('dailyLimit', v);
                    }),
                Text('${_limit.toStringAsFixed(0)} GB per day',
                    style: const TextStyle(
                        color: Color(0xFF7C6CFA), fontSize: 13)),
              ])),
          kCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                kLabel('nightly report time'),
                const SizedBox(height: 12),
                Row(
                    children: [21, 22, 23].map((h) {
                  final sel = _hour == h;
                  return Expanded(
                      child: GestureDetector(
                    onTap: () {
                      setState(() => _hour = h);
                      _save('reportHour', h);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFF7C6CFA)
                              : const Color(0xFF1E1E2B),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${h - 12} PM',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: sel ? Colors.white : Colors.grey,
                              fontWeight:
                                  sel ? FontWeight.w600 : FontWeight.normal)),
                    ),
                  ));
                }).toList()),
              ])),
          kCard(
              child: Column(children: [
            _toggle('Addiction alerts', 'Warn if social media > 50% usage',
                _addiction, (v) {
              setState(() => _addiction = v);
              _save('addictionAlerts', v);
            }),
            const Divider(color: Color(0xFF2A2A3A), height: 20),
            _toggle(
                'Daily tips', 'Show smart data-saving recommendations', _tips,
                (v) {
              setState(() => _tips = v);
              _save('dailyTips', v);
            }),
          ])),
        ]),
      ),
    );
  }

  Widget _toggle(String title, String sub, bool val, ValueChanged<bool> cb) =>
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC8C8D8),
                  fontWeight: FontWeight.w500)),
          Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        Switch(value: val, onChanged: cb, activeColor: const Color(0xFF7C6CFA)),
      ]);
}
