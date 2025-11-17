import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ClinicReportPage extends StatelessWidget {
  const ClinicReportPage({super.key});

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏥 Clinic Overall Report"),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: _loadReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  // 1. SUMMARY
                  _sectionCard(
                    title: "📌 1. Clinic Summary",
                    child: _summaryGrid(data),
                  ),

                  // 2. APPOINTMENT TRENDS
                  _sectionCard(
                    title: "📈 2. Monthly Appointment Trend",
                    child: SizedBox(
                      height: 250,
                      child: _appointmentLineChart(data["appointments"]),
                    ),
                  ),

                  // 3. SERVICE COMPARISON
                  _sectionCard(
                    title: "📊 3. Service Usage Comparison",
                    child: SizedBox(
                      height: 250,
                      child: _serviceBarChart(data),
                    ),
                  ),

                  // 4. PATIENT AGE DEMOGRAPHICS
                  _sectionCard(
                    title: "🥧 4. Patient Demographics",
                    child: SizedBox(
                      height: 250,
                      child: _patientPieChart(data["patients"]),
                    ),
                  ),

                  // 5. APPOINTMENTS TABLE
                  _sectionCard(
                    title: "📅 5. Appointment Summary",
                    child: _appointmentSummary(data["appointments"]),
                  ),

                  // 6. HOME VISITS
                  _sectionCard(
                    title: "🏠 6. Home Visit Report",
                    child: _scrollTable(data['homeVisits'], [
                      'name', 'ic_number', 'doctor', 'visit_date', 'task', 'summary'
                    ]),
                  ),

                  // 7. MATERNAL & CHILD CARE
                  _sectionCard(
                    title: "🤰 7. Maternal & Child Health Report",
                    child: _scrollTable(data['maternal'], [
                      'patient', 'type', 'visit_date', 'risk_sign', 'vaccination_status'
                    ]),
                  ),

                  // 8. REFERRAL REPORT
                  _sectionCard(
                    title: "📤 8. Referral Report",
                    child: _scrollTable(data['referrals'], [
                      'patientName', 'patientNric', 'date', 'reason', 'referrerOrg'
                    ]),
                  ),

                  // 9. STAFF
                  _sectionCard(
                    title: "👩‍⚕️ 9. Staff Activity Summary",
                    child: _scrollTable(data['staff'], [
                      'name', 'role', 'appointments', 'home_visits', 'referrals'
                    ]),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------
  // SECTION CARD UI
  // ------------------------------
  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                )),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // SUMMARY GRID
  // ------------------------------
  Widget _summaryGrid(Map<String, dynamic> data) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _summaryItem("Patients", data['totalPatients'], Icons.people),
        _summaryItem("Appointments", data['totalAppointments'], Icons.calendar_today),
        _summaryItem("Home Visits", data['totalHomeVisits'], Icons.home),
        _summaryItem("Maternal Cases", data['totalMaternal'], Icons.pregnant_woman),
        _summaryItem("Referrals", data['totalReferrals'], Icons.send),
      ],
    );
  }

  Widget _summaryItem(String label, int value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$value",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label),
            ],
          )
        ],
      ),
    );
  }

  // ------------------------------
  // LINE CHART - APPOINTMENTS PER MONTH
  // ------------------------------
  Widget _appointmentLineChart(List<QueryDocumentSnapshot> docs) {
    Map<int, int> monthly = {};

    for (var d in docs) {
      final date = DateTime.tryParse(d['availability_date'] ?? "");
      if (date == null) continue;
      monthly[date.month] = (monthly[date.month] ?? 0) + 1;
    }

    return LineChart(
      LineChartData(
        borderData: FlBorderData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = [
                  "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                ];
                return Text(months[value.toInt()]);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: monthly.entries
                .map((e) =>
                    FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            isCurved: true,
            color: Colors.deepPurple,
            barWidth: 4,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // BAR CHART - SERVICE COMPARISON
  // ------------------------------
  Widget _serviceBarChart(Map<String, dynamic> data) {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ["Appt", "Home", "Maternal", "Refer"];
                return Text(labels[value.toInt()]);
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              toY: data["totalAppointments"].toDouble(),
              color: Colors.blue
            )
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              toY: data["totalHomeVisits"].toDouble(),
              color: Colors.green
            )
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
              toY: data["totalMaternal"].toDouble(),
              color: Colors.orange
            )
          ]),
          BarChartGroupData(x: 3, barRods: [
            BarChartRodData(
              toY: data["totalReferrals"].toDouble(),
              color: Colors.red
            )
          ]),
        ],
      ),
    );
  }

  // ------------------------------
  // PIE CHART - PATIENT AGE DEMOGRAPHICS
  // ------------------------------
  Widget _patientPieChart(List<QueryDocumentSnapshot> patients) {
    int child = 0, adult = 0, elderly = 0;

    for (var p in patients) {
      final ageStr = p['age']?.toString();
      final age = int.tryParse(ageStr ?? "");
      if (age == null) continue;

      if (age < 12) child++;
      else if (age < 60) adult++;
      else elderly++;
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        sections: [
          PieChartSectionData(
            value: child.toDouble(),
            color: Colors.blue,
            title: "Child",
          ),
          PieChartSectionData(
            value: adult.toDouble(),
            color: Colors.green,
            title: "Adult",
          ),
          PieChartSectionData(
            value: elderly.toDouble(),
            color: Colors.orange,
            title: "Elderly",
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // TABLE (SCROLLABLE)
  // ------------------------------
  Widget _scrollTable(List<QueryDocumentSnapshot> docs, List<String> fields) {
    if (docs.isEmpty) return const Text("No records available");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: _tableList(docs, fields),
    );
  }

  Widget _tableList(List<QueryDocumentSnapshot> docs, List<String> fields) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // HEADER
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: fields
              .map((f) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      f.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ))
              .toList(),
        ),

        // DATA
        ...docs.map((d) {
          final row = d.data() as Map<String, dynamic>;
          return TableRow(
            children: fields
                .map((f) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        row[f]?.toString() ?? "-",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
          );
        })
      ],
    );
  }

  // ------------------------------
  // APPOINTMENT SUMMARY BOXES
  // ------------------------------
  Widget _appointmentSummary(List<QueryDocumentSnapshot> docs) {
    int upcoming = 0, past = 0;

    for (var d in docs) {
      final date = DateTime.tryParse(d['availability_date'] ?? "");
      if (date == null) continue;

      if (date.isAfter(DateTime.now())) upcoming++;
      else past++;
    }

    return Column(
      children: [
        _summaryItem("Upcoming", upcoming, Icons.arrow_forward),
        const SizedBox(height: 12),
        _summaryItem("Past", past, Icons.check_circle),
      ],
    );
  }
}
