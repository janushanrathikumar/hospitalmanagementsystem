import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospitalmanagementsystem/doctor/doctor_appbar.dart';
import 'package:hospitalmanagementsystem/doctor/doctor_drawer.dart';
import 'doctor_appbar.dart';
import 'doctor_drawer.dart';

class ClinicReportPage extends StatelessWidget {
  const ClinicReportPage({super.key});

  // Modern Color Palette
  static const Color primaryTeal = Color(0xFF356859);
  static const Color accentPurple = Color(0xFF6C63FF);
  static const Color bgLight = Color(0xFFF1F2F6);
  static const Color cardShadow = Color(0x0A000000);

  Future<Map<String, dynamic>> _loadReport() async {
    final db = FirebaseFirestore.instance;
    
    // Fetching all collections in parallel for better performance
    final results = await Future.wait([
      db.collection('patients').get(),
      db.collection('appointments').get(),
      db.collection('home_visits').get(),
      db.collection('maternal_child_care').get(),
      db.collection('referral_letters').get(),
    ]);

    return {
      "patients": results[0].docs,
      "appointments": results[1].docs,
      "homeVisits": results[2].docs,
      "maternal": results[3].docs,
      "referrals": results[4].docs,
      "totalPatients": results[0].size,
      "totalAppointments": results[1].size,
      "totalHomeVisits": results[2].size,
      "totalMaternal": results[3].size,
      "totalReferrals": results[4].size,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: const DoctorAppBar(), // Using Nurse AppBar
      drawer: const DoctorDrawer(),   // Using Nurse Drawer
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadReport(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryTeal));
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading reports. Check permissions."));
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Executive Summary",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(245, 0, 0, 0)),
                ),
                const SizedBox(height: 20),

                // 1. MODERN STATS GRID
                _buildModernSummaryGrid(data),
                const SizedBox(height: 32),

                // 2. ANALYTICS ROW (Line & Pie Charts)
                LayoutBuilder(builder: (context, constraints) {
                  // Make it a column on mobile, row on desktop/tablet
                  bool isMobile = constraints.maxWidth < 800;
                  return Flex(
                    direction: isMobile ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isMobile ? 0 : 2,
                        child: _sectionCard(
                          title: "Appointment Trends",
                          child: SizedBox(
                            height: 300,
                            child: _appointmentLineChart(data["appointments"]),
                          ),
                        ),
                      ),
                      if (!isMobile) const SizedBox(width: 20),
                      Expanded(
                        flex: isMobile ? 0 : 1,
                        child: _sectionCard(
                          title: "Patient Demographics",
                          child: SizedBox(
                            height: 300,
                            child: _patientPieChart(data["patients"]),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                // 3. SERVICE BAR CHART
                _sectionCard(
                  title: "Service Volume Comparison",
                  child: SizedBox(height: 200, child: _serviceBarChart(data)),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Detailed Activity Logs",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTeal),
                  ),
                ),

                // 4. DATA TABLES (Expandable)
                _expandableTableCard("Referral Report", data['referrals'],
                    ['patientName', 'date', 'reason', 'referrerOrg']),
                _expandableTableCard("Home Visit Logs", data['homeVisits'],
                    ['name', 'doctor', 'visit_date', 'task']),
                _expandableTableCard("Maternal Health", data['maternal'],
                    ['patient', 'type', 'visit_date', 'risk_sign']),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildModernSummaryGrid(Map<String, dynamic> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _statTile("Total Patients", data['totalPatients'], Icons.people_outline, Colors.blue),
        _statTile("Appointments", data['totalAppointments'], Icons.event_available, accentPurple),
        _statTile("Home Visits", data['totalHomeVisits'], Icons.home_outlined, Colors.orange),
        _statTile("Maternal Health", data['totalMaternal'], Icons.child_care, Colors.pink),
        _statTile("Active Referrals", data['totalReferrals'], Icons.description_outlined, Colors.teal),
      ],
    );
  }

  Widget _statTile(String label, int value, IconData icon, Color color) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text("$value", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTeal)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _expandableTableCard(String title, List<QueryDocumentSnapshot> docs, List<String> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        leading: const Icon(Icons.table_chart_outlined, color: primaryTeal),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: fields.map((f) => DataColumn(label: Text(f.toUpperCase(), style: const TextStyle(fontSize: 11)))).toList(),
              rows: docs.map((d) {
                final row = d.data() as Map<String, dynamic>;
                return DataRow(
                  cells: fields.map((f) => DataCell(Text(row[f]?.toString() ?? "-", style: const TextStyle(fontSize: 12)))).toList()
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // --- CHARTS ---

  Widget _appointmentLineChart(List<QueryDocumentSnapshot> docs) {
    Map<int, int> monthly = {for (var i = 1; i <= 12; i++) i: 0};
    for (var d in docs) {
      final date = DateTime.tryParse(d['availability_date'] ?? "");
      if (date != null) monthly[date.month] = (monthly[date.month] ?? 0) + 1;
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, _) {
                const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                int idx = val.toInt() - 1;
                return (idx >= 0 && idx < 12) ? Text(months[idx], style: const TextStyle(fontSize: 10)) : const Text("");
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: monthly.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            color: primaryTeal,
            barWidth: 4,
            belowBarData: BarAreaData(show: true, color: primaryTeal.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _patientPieChart(List<QueryDocumentSnapshot> patients) {
    int child = 0, adult = 0, elderly = 0;
    for (var p in patients) {
      final age = int.tryParse(p['age']?.toString() ?? "");
      if (age == null) continue;
      if (age < 12) child++; else if (age < 60) adult++; else elderly++;
    }
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(value: child.toDouble(), color: Colors.blueAccent, title: 'Child', radius: 50),
          PieChartSectionData(value: adult.toDouble(), color: accentPurple, title: 'Adult', radius: 50),
          PieChartSectionData(value: elderly.toDouble(), color: Colors.orangeAccent, title: 'Elderly', radius: 50),
        ],
      ),
    );
  }

  Widget _serviceBarChart(Map<String, dynamic> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const labs = ["Appt", "Home", "Maternal", "Refer"];
                return (v.toInt() < 4) ? Text(labs[v.toInt()], style: const TextStyle(fontSize: 10)) : const Text("");
              },
            ),
          ),
        ),
        barGroups: [
          _makeGroup(0, data["totalAppointments"].toDouble(), accentPurple),
          _makeGroup(1, data["totalHomeVisits"].toDouble(), Colors.orange),
          _makeGroup(2, data["totalMaternal"].toDouble(), Colors.pink),
          _makeGroup(3, data["totalReferrals"].toDouble(), Colors.teal),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: color, width: 22, borderRadius: BorderRadius.circular(6))
    ]);
  }
}