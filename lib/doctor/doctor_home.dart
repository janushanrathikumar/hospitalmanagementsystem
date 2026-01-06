import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'doctor_appbar.dart';
import 'doctor_drawer.dart';

class DoctorHome extends StatelessWidget {
  const DoctorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: const DoctorAppBar(),
      drawer: const DoctorDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Overview Stats (Big Tiles, No Icons)
            _buildDoctorOverviewSection(),
            const SizedBox(height: 25),

            // 2. Middle Row: Patient Demographics and Today's Queue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildPatientStatsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildTodayAppointmentsCard()),
              ],
            ),
            const SizedBox(height: 25),

            // 3. Bottom Row: Weekly Performance Charts
            Row(
              children: [
                Expanded(child: _buildConsultationTrendChart()),
                const SizedBox(width: 20),
                Expanded(child: _buildPatientVolumeBarChart()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildDoctorOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _StatTile(
                  label: 'My Patients',
                  collection: 'patients',
                  color: Colors.blue),
              _StatTile(
                  label: 'Pending Reviews',
                  collection: 'appointments',
                  color: Colors.orange),
              _StatTile(
                  label: 'Total Consults',
                  collection: 'consultations',
                  color: Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStatsCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Case Mix',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                            value: 50,
                            color: Colors.blue,
                            title: '50%',
                            radius: 50),
                        PieChartSectionData(
                            value: 30,
                            color: Colors.purple,
                            title: '30%',
                            radius: 50),
                        PieChartSectionData(
                            value: 20,
                            color: Colors.orange,
                            title: '20%',
                            radius: 50),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Routine', Colors.blue),
                    _legendItem('Emergency', Colors.purple),
                    _legendItem('Follow-up', Colors.orange),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTodayAppointmentsCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Schedule',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(doc['name'] ?? 'Patient',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['slot_time'] ?? 'No Time',
                          style: const TextStyle(fontSize: 11)),
                      trailing:
                          const Icon(Icons.arrow_right, color: Colors.purple),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTrendChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consultation Trend',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 4,
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 5),
                      FlSpot(2, 3),
                      FlSpot(3, 8),
                      FlSpot(4, 6)
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientVolumeBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New vs Returning',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 8, 4),
                  _barGroup(1, 10, 7),
                  _barGroup(2, 14, 10),
                  _barGroup(3, 9, 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y1, double y2) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y1, color: Colors.purple.shade300, width: 12),
      BarChartRodData(toY: y2, color: Colors.orange.shade300, width: 12),
    ]);
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// --- SHARED STAT TILE (BIG VERSION) ---
class _StatTile extends StatelessWidget {
  final String label, collection;
  final Color color;

  const _StatTile(
      {required this.label, required this.collection, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String count =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3), width: 2)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(count,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 32, color: color)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
