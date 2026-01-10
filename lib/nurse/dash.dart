import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'nurse_appbar.dart';
import 'nurse_drawer.dart';
import 'ai_chatbot.dart';

class NurseDash extends StatefulWidget {
  const NurseDash({super.key});

  @override
  State<NurseDash> createState() => _NurseDashState();
}

class _NurseDashState extends State<NurseDash> {
  static const Color primaryPurple = Color(0xFF4A3469);
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),

      // 🤖 AI CHATBOT BUTTON (BOTTOM RIGHT)
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        child: const Icon(Icons.smart_toy, color: Colors.white),
        onPressed: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: "ChatBot",
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, anim1, anim2) {
              return Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80, right: 20),
                  child: Material(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AiChatBot(
                        model: _model,
                        primaryColor: primaryPurple,
                      ),
                    ),
                  ),
                ),
              );
            },
            transitionBuilder: (context, anim1, anim2, child) {
              return FadeTransition(
                opacity: anim1,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(anim1),
                  child: child,
                ),
              );
            },
          );
        },
      ),
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
            _buildNurseOverviewSection(),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildHomeVisitStatsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildPendingTasksCard()),
              ],
            ),
            const SizedBox(height: 25),
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

  // ================= UI SECTIONS =================

  Widget _buildNurseOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
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
            childAspectRatio: 2.2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 30,
            children: const [
              _StatTile(
                  label: "Today's Visits",
                  collection: 'home_visits',
                  color: Colors.teal),
              _StatTile(
                  label: "Maternal Cases",
                  collection: 'maternal_child_care',
                  color: Colors.pink),
              _StatTile(
                  label: "Total Reports",
                  collection: 'reports',
                  color: primaryPurple),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Demographics',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      value: 40, color: Colors.teal, title: '40%', radius: 50),
                  PieChartSectionData(
                      value: 35, color: Colors.pink, title: '35%', radius: 50),
                  PieChartSectionData(
                      value: 25,
                      color: Colors.orange,
                      title: '25%',
                      radius: 50),
                ],
              ),
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
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Tasks",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(doc['name'] ?? 'Task',
                          style: const TextStyle(fontSize: 13)),
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
    return _chartContainer(
      title: "Nursing Activities Trend",
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(show: false),
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
                FlSpot(4, 9),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCareDistributionBarChart() {
    return _chartContainer(
      title: "Weekly Comparison",
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
    );
  }

  // ================= HELPERS =================

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      );

  Widget _chartContainer({required String title, required Widget child}) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y1, double y2) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y1, color: Colors.teal.shade300, width: 12),
      BarChartRodData(
          toY: y2, color: primaryPurple.withOpacity(0.7), width: 12),
    ]);
  }
}

// ================= STAT TILE =================

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
        final count =
            snapshot.hasData ? snapshot.data!.docs.length.toString() : '0';
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(count,
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
