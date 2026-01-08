import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hospitalmanagementsystem/admin/adminappbar.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F6),
      appBar: const AdminAppBar(),
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            _buildClinicOverviewSection(),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildPatientDemographicsCard()),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildUpcomingAppointmentsCard()),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildMonthlyRegistrationLineChart()),
                const SizedBox(width: 20),
                Expanded(child: _buildAppointmentsBarChart()),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildClinicOverviewSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Clinic Overview',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
      ),
      const SizedBox(height: 20),
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: const [
          _StatTile(
            label: 'Total Patients',
            collection: 'patients',
            icon: Icons.people_outline,
            color: Colors.blue,
          ),
          _StatTile(
            label: 'Appointments',
            collection: 'appointments',
            icon: Icons.event_available,
            color: Colors.purple,
          ),
          _StatTile(
            label: 'Home Visits',
            collection: 'home_visits',
            icon: Icons.home_outlined,
            color: Colors.orange,
          ),
          _StatTile(
            label: 'Maternal Cases',
            collection: 'maternal_child_care',
            icon: Icons.child_care,
            color: Colors.pink,
          ),
          _StatTile(
            label: 'Total Referrals',
            collection: 'referral_letters',
            icon: Icons.description_outlined,
            color: Colors.teal,
          ),
          _StatTile(
            label: 'Active Staff',
            collection: 'users',
            icon: Icons.badge_outlined,
            color: Colors.indigo,
          ),
        ],
      ),
    ],
  );
}

  Widget _buildPatientDemographicsCard() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Demographics',
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
                            value: 43,
                            color: Colors.blue,
                            title: '43%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 31,
                            color: Colors.pink,
                            title: '31%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 14,
                            color: Colors.orange,
                            title: '14%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        PieChartSectionData(
                            value: 12,
                            color: Colors.teal,
                            title: '12%',
                            radius: 50,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Male', Colors.blue),
                    _legendItem('Female', Colors.pink),
                    _legendItem('Children (<12)', Colors.orange),
                    _legendItem('Adults (13-59)', Colors.teal),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsCard() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Upcoming Appointments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .orderBy('timestamp', descending: true)
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                return ListView.separated(
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(doc['name'] ?? 'Guest',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(doc['slot_time'] ?? '',
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
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

  Widget _buildMonthlyRegistrationLineChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Patient Registrations',
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
                    barWidth: 3,
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 8),
                      FlSpot(3, 7),
                      FlSpot(4, 12)
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

  Widget _buildAppointmentsBarChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appointments & Home Visits',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 10, 5),
                  _barGroup(1, 12, 8),
                  _barGroup(2, 8, 4),
                  _barGroup(3, 14, 9),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  BarChartGroupData _barGroup(int x, double y1, double y2) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y1, color: Colors.blue, width: 10),
      BarChartRodData(toY: y2, color: Colors.teal.shade300, width: 10),
    ]);
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
class _StatTile extends StatelessWidget {
  final String label, collection;
  final Color color;
  final IconData icon; // Define the icon field here
  
  const _StatTile({
    required this.label, 
    required this.collection, 
    required this.color,
    required this.icon, // Add this line to define the icon field
  });

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
              color: color.withOpacity(0.05), // Light background based on theme color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 2)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 30, // Large font for numbers
                    color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade700, 
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}