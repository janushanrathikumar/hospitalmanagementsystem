import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'nurse_drawer.dart';
import 'nurse_appbar.dart';
class ClinicReportPage extends StatelessWidget {
  const ClinicReportPage({super.key});

 
  static const Color primaryTeal = Color(0xFF356859);
  static const Color accentPurple = Color(0xFF6C63FF);
  static const Color bgCanvas = Color(0xFFF4F7F6);
  static const Color cardShadow = Color(0x0A000000);

  Future<Map<String, dynamic>> _loadReport() async {
    final db = FirebaseFirestore.instance;
    final patients = await db.collection('patients').get();
    final appointments = await db.collection('appointments').get();
    final homeVisits = await db.collection('home_visits').get();
    final maternal = await db.collection('maternal_child_care').get();
    final referrals = await db.collection('referral_letters').get();
    final users = await db.collection('users').get();

    return {
      "patients": patients.docs,
      "appointments": appointments.docs,
      "homeVisits": homeVisits.docs,
      "maternal": maternal.docs,
      "referrals": referrals.docs,
      "staff": users.docs,
      "totalPatients": patients.size,
      "totalAppointments": appointments.size,
      "totalHomeVisits": homeVisits.size,
      "totalMaternal": maternal.size,
      "totalReferrals": referrals.size,
    };
  }

  @override
  Widget build(BuildContext context) {
        const Color bgLight = Color(0xFFF1F2F6);
    return Scaffold(
     backgroundColor: bgLight,
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      body: FutureBuilder(
        future: _loadReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: primaryTeal));
          final data = snapshot.data as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Executive Summary",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // 1. STATS GRID
                _buildModernSummaryGrid(data),
                const SizedBox(height: 32),

                // 2. ANALYTICS ROW (Charts)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _sectionCard(
                        title: "Appointment Trends",
                        child: SizedBox(
                            height: 300,
                            child: _appointmentLineChart(data["appointments"])),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: _sectionCard(
                        title: "Demographics",
                        child: SizedBox(
                            height: 300,
                            child: _patientPieChart(data["patients"])),
                      ),
                    ),
                  ],
                ),

                // 3. SERVICE BAR CHART
                _sectionCard(
                  title: "Service Volume Comparison",
                  child: SizedBox(height: 200, child: _serviceBarChart(data)),
                ),

                // 4. DETAILED TABLES
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("Detailed Activity Logs",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),

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
    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _statTile("Total Patients", data['totalPatients'],
              Icons.people_outline, Colors.blue),
          _statTile("Appointments", data['totalAppointments'],
              Icons.event_available, accentPurple),
          _statTile("Home Visits", data['totalHomeVisits'], Icons.home_outlined,
              Colors.orange),
          _statTile("Maternal Health", data['totalMaternal'], Icons.child_care,
              Colors.pink),
          _statTile("Active Referrals", data['totalReferrals'],
              Icons.description_outlined, Colors.teal),
        ],
      );
    });
  }

  Widget _statTile(String label, int value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: cardShadow, blurRadius: 10, offset: Offset(0, 4))
        ],
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
          Text("$value",
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryTeal)),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _expandableTableCard(
      String title, List<QueryDocumentSnapshot> docs, List<String> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      borderOnForeground: true,
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        leading: const Icon(Icons.table_chart_outlined, color: primaryTeal),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
              columns: fields
                  .map((f) => DataColumn(
                      label: Text(f.toUpperCase(),
                          style: const TextStyle(fontSize: 11))))
                  .toList(),
              rows: docs.map((d) {
                final row = d.data() as Map<String, dynamic>;
                return DataRow(
                    cells: fields
                        .map((f) => DataCell(Text(row[f]?.toString() ?? "-",
                            style: const TextStyle(fontSize: 12))))
                        .toList());
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  // --- CHARTS (Updated Styling) ---

  Widget _appointmentLineChart(List<QueryDocumentSnapshot> docs) {
    Map<int, int> monthly = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0,
      8: 0,
      9: 0,
      10: 0,
      11: 0,
      12: 0
    };
    for (var d in docs) {
      final date = DateTime.tryParse(d['availability_date'] ?? "");
      if (date != null) monthly[date.month] = (monthly[date.month] ?? 0) + 1;
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        titlesData: FlTitlesData(
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, _) {
                    const months = [
                      "Jan",
                      "Feb",
                      "Mar",
                      "Apr",
                      "May",
                      "Jun",
                      "Jul",
                      "Aug",
                      "Sep",
                      "Oct",
                      "Nov",
                      "Dec"
                    ];
                    return val.toInt() >= 1 && val.toInt() <= 12
                        ? Text(months[val.toInt() - 1],
                            style: const TextStyle(fontSize: 10))
                        : const SizedBox();
                  })),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: monthly.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            isCurved: true,
            color: primaryTeal,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData:
                BarAreaData(show: true, color: primaryTeal.withOpacity(0.05)),
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
      if (age < 12)
        child++;
      else if (age < 60)
        adult++;
      else
        elderly++;
    }
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
              value: child.toDouble(),
              color: Colors.blueAccent,
              title: 'Child',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
          PieChartSectionData(
              value: adult.toDouble(),
              color: accentPurple,
              title: 'Adult',
              radius: 55,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
          PieChartSectionData(
              value: elderly.toDouble(),
              color: Colors.orangeAccent,
              title: 'Elderly',
              radius: 50,
              titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
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
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    const labs = ["Appt", "Home", "Maternal", "Refer"];
                    return Text(labs[v.toInt()],
                        style: const TextStyle(fontSize: 10));
                  })),
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
      BarChartRodData(
          toY: y,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(4))
    ]);
  }
}
