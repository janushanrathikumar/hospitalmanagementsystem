import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'nurse_appbar.dart';
import 'nurse_drawer.dart';

class NurseDash extends StatelessWidget {
  const NurseDash({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3469);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nurse Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
            const SizedBox(height: 20),

            // 1. Top Overview Stats
            _buildNurseOverviewSection(),
            const SizedBox(height: 25),

            // 2. Middle Row: Visit Tracking and Task List
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildHomeVisitStatsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildPendingTasksCard()),
              ],
            ),
            const SizedBox(height: 25),

            // 3. Bottom Row: Activity Charts
            Row(
              children: [
                Expanded(child: _buildPatientCareTrendChart()),
                const SizedBox(width: 20),
                Expanded(child: _buildCareDistributionBarChart()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildNurseOverviewSection() {
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
          const Text('Care Summary',
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
                  label: 'Today\'s Visits',
                  collection: 'home_visits',
                  color: Colors.teal),
              _StatTile(
                  label: 'Maternal Cases',
                  collection: 'maternal_child_care',
                  color: Colors.pink),
              _StatTile(
                  label: 'Total Reports',
                  collection: 'reports',
                  color: const Color(0xFF4A3469)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeVisitStatsCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Demographics (Care)',
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
                            value: 40,
                            color: Colors.teal,
                            title: '40%',
                            radius: 50),
                        PieChartSectionData(
                            value: 35,
                            color: Colors.pink,
                            title: '35%',
                            radius: 50),
                        PieChartSectionData(
                            value: 25,
                            color: Colors.orange,
                            title: '25%',
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
                    _legendItem('Home Care', Colors.teal),
                    _legendItem('Maternal', Colors.pink),
                    _legendItem('Referrals', Colors.orange),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPendingTasksCard() {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today\'s Tasks',
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
                      title: Text(doc['name'] ?? 'Task',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['task'] ?? 'Routine Visit',
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.check_circle_outline,
                          color: Colors.teal),
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

  Widget _buildPatientCareTrendChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nursing Activities Trend',
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
                    color: Colors.teal,
                    barWidth: 4,
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 6),
                      FlSpot(3, 5),
                      FlSpot(4, 9)
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

  Widget _buildCareDistributionBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weekly Comparison',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 5, 8),
                  _barGroup(1, 7, 6),
                  _barGroup(2, 12, 5),
                  _barGroup(3, 8, 9),
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
      BarChartRodData(toY: y1, color: Colors.teal.shade300, width: 12),
      BarChartRodData(
          toY: y2, color: const Color(0xFF4A3469).withOpacity(0.7), width: 12),
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

// --- SHARED STAT TILE (NURSE VERSION) ---
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
