import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import doctor header + drawer
import '../doctor/doctor_appbar.dart';
import '../doctor/doctor_drawer.dart';

class ClinicReportPage extends StatelessWidget {
  const ClinicReportPage({super.key});

  Future<Map<String, dynamic>> _loadReport() async {
    final db = FirebaseFirestore.instance;

    final patients = await db.collection('patients').get();
    final appointments = await db.collection('appointments').get();
    final homeVisits = await db.collection('home_visits').get();
    final maternal = await db.collection('maternal_child_care').get();
    final referrals = await db.collection('referral_letters').get();

    return {
      "totalPatients": patients.size,
      "totalAppointments": appointments.size,
      "totalHomeVisits": homeVisits.size,
      "totalMaternal": maternal.size,
      "totalReferrals": referrals.size,

      "appointments": appointments.docs,
      "patients": patients.docs,
      "maternal": maternal.docs,
      "homeVisits": homeVisits.docs,
      "referrals": referrals.docs,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ⭐ Your custom appbar & drawer added
      appBar: DoctorAppBar(),
      drawer: DoctorDrawer(),

      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: FutureBuilder(
          future: _loadReport(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "🏥 Clinic Overall Report",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SUMMARY
                  _title("1. Clinic Summary"),
                  _summaryTable(data),

                  const SizedBox(height: 30),

                  // BAR CHART
                  _title("2. Monthly Activity Chart"),
                  SizedBox(height: 220, child: _barChart(data)),

                  const SizedBox(height: 30),

                  // PIE CHART
                  _title("3. Patient Breakdown"),
                  SizedBox(height: 220, child: _pieChart(data)),

                  const SizedBox(height: 30),

                  // APPOINTMENT SUMMARY
                  _title("4. Appointment Summary"),
                  _appointmentSummary(data["appointments"]),

                  const SizedBox(height: 30),

                  // Maternal
                  _title("5. Maternal & Child Health"),
                  _tableList(data['maternal'], [
                    'patient', 'type', 'visit_date', 'risk_sign'
                  ]),

                  const SizedBox(height: 30),

                  // Home visits
                  _title("6. Home Visits"),
                  _tableList(data['homeVisits'], [
                    'name', 'ic_number', 'doctor', 'visit_date', 'task'
                  ]),

                  const SizedBox(height: 30),

                  // Referral
                  _title("7. Referral Summary"),
                  _tableList(data['referrals'], [
                    'patientName', 'patientNric', 'reason', 'referrerOrg'
                  ]),

                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------
  //   UI COMPONENTS
  // ---------------------

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _summaryTable(Map<String, dynamic> data) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      children: [
        _row("Total Registered Patients", data["totalPatients"].toString()),
        _row("Total Appointments", data["totalAppointments"].toString()),
        _row("Total Home Visits", data["totalHomeVisits"].toString()),
        _row("Maternal & Child Health Cases", data["totalMaternal"].toString()),
        _row("Referrals", data["totalReferrals"].toString()),
      ],
    );
  }

  TableRow _row(String key, String value) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(key)),
        Padding(padding: const EdgeInsets.all(8), child: Text(value)),
      ],
    );
  }

  Widget _tableList(List<QueryDocumentSnapshot> docs, List<String> fields) {
    if (docs.isEmpty) return const Text("No records found");

    return Table(
      border: TableBorder.all(color: Colors.grey),
      children: [
        // Header
        TableRow(
          children: fields
              .map((f) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(f.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ))
              .toList(),
        ),
        // Rows
        ...docs.map((d) {
          final row = d.data() as Map<String, dynamic>;
          return TableRow(
            children: fields
                .map((f) => Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(row[f]?.toString() ?? "-"),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _appointmentSummary(List<QueryDocumentSnapshot> docs) {
    int past = 0;
    int upcoming = 0;

    for (var d in docs) {
      String date = d['availability_date'] ?? "";
      final dt = DateTime.tryParse(date);

      if (dt == null) continue;
      if (dt.isBefore(DateTime.now())) {
        past++;
      } else {
        upcoming++;
      }
    }

    return _summaryTable({
      "Past": past,
      "Upcoming": upcoming,
    });
  }

  // -----------------------
  //     CHARTS
  // -----------------------

  Widget _barChart(Map<String, dynamic> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
                toY: data["totalAppointments"].toDouble(),
                color: Colors.deepPurple)
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
                toY: data["totalHomeVisits"].toDouble(), color: Colors.blue)
          ]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              switch (value.toInt()) {
                case 1:
                  return const Text("Appointments");
                case 2:
                  return const Text("Home Visits");
              }
              return const Text("");
            },
          )),
        ),
      ),
    );
  }

  Widget _pieChart(Map<String, dynamic> data) {
    int total = data["totalPatients"];

    return PieChart(
      PieChartData(centerSpaceRadius: 40, sections: [
        PieChartSectionData(
          color: Colors.deepPurple,
          value: total.toDouble(),
          title: "$total Patients",
        )
      ]),
    );
  }
}
