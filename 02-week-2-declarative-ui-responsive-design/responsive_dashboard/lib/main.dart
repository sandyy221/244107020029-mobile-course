import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: isDark,
        onDarkChanged: (value) => setState(() => isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Overview'),
        actions: [
          Semantics(
            label: isDark ? 'Aktifkan mode terang' : 'Aktifkan mode gelap',
            toggled: isDark,
            child: Row(
              children: [
                Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Profil (Container, Row, Column, Expanded)
            const ProfileHeader(),
            const SizedBox(height: 20),

            // Section Title
            Text(
              'Statistik Akademik',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // 2. Grid Kartu Informasi Responsif (1 kolom sempit / 2 kolom lebar)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 600;
                final crossAxisCount = isWideScreen ? 2 : 1;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWideScreen ? 2.5 : 2.8,
                  children: const [
                    AcademicCard(
                      title: 'IPK Kumulatif',
                      value: '3.85',
                      icon: Icons.grade,
                      color: Colors.blue,
                      semanticLabel: 'IPK Kumulatif Anda saat ini adalah 3.85',
                    ),
                    AcademicCard(
                      title: 'Total SKS Lulus',
                      value: '84 SKS',
                      icon: Icons.school,
                      color: Colors.green,
                      semanticLabel: 'Total SKS yang telah lulus adalah 84 SKS',
                    ),
                    AcademicCard(
                      title: 'Persentase Kehadiran',
                      value: '95%',
                      icon: Icons.event_available,
                      color: Colors.orange,
                      semanticLabel: 'Persentase kehadiran perkuliahan 95 persen',
                    ),
                    AcademicCard(
                      title: 'Tugas Pending',
                      value: '3 Tugas',
                      icon: Icons.assignment_late,
                      color: Colors.red,
                      semanticLabel: 'Ada 3 tugas pending yang perlu diselesaikan',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Header Profil
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Foto Profil Mahasiswa',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sandy Kurniawan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Teknik Informatika • Semester 4',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Kartu Informasi Akademik
class AcademicCard extends StatelessWidget {
  const AcademicCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.semanticLabel,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
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