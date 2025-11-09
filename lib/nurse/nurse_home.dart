import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. ADD THIS
import 'package:google_generative_ai/google_generative_ai.dart'; // <-- 2. ADD THIS
import 'nurse_appbar.dart';
import 'nurse_drawer.dart';
// 3. You can REMOVE 'import 'chatbot_page.dart';'

// 4. ADD THE ChatMessage CLASS HERE
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class NurseHome extends StatefulWidget {
  const NurseHome({super.key});

  @override
  State<NurseHome> createState() => _NurseHomeState();
}

class _NurseHomeState extends State<NurseHome> {
  final _firestore = FirebaseFirestore.instance;

  // --- 5. ADD ALL CHAT LOGIC HERE ---
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late final GenerativeModel _model;
  bool _loading = false;
  bool _isChatVisible = false; // Controls the popup
  // --- END OF CHAT LOGIC ---

  @override
  void initState() {
    super.initState();
    // Initialize the Gemini model
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('API key not found. Make sure to set it in .env file');
      return;
    }
    _model = GenerativeModel(
      // Note: Using 'gemini-1.5-flash' as it worked before.
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  @override
  void dispose() {
    // Dispose chat controllers
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 6. ADD ALL CHAT FUNCTIONS HERE ---

  // Toggles the chat window visibility
  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text;
    if (messageText.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _loading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final content = [Content.text(messageText)];
      final response = await _model.generateContent(content);

      setState(() {
        _messages.add(
            ChatMessage(text: response.text ?? 'No response', isUser: false));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages
            .add(ChatMessage(text: 'Error: ${e.toString()}', isUser: false));
        _loading = false;
      });
      _scrollToBottom();
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  // --- END OF CHAT FUNCTIONS ---

  // This is your existing function (no changes)
  Future<void> _addPatientDialog() async {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final icCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Patient Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: icCtrl,
                  decoration: const InputDecoration(
                    labelText: 'IC Number (Unique ID)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: mobileCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    minimumSize: const Size.fromHeight(45),
                  ),
                  onPressed: () async {
                    if (icCtrl.text.isEmpty ||
                        nameCtrl.text.isEmpty ||
                        addressCtrl.text.isEmpty ||
                        ageCtrl.text.isEmpty ||
                        mobileCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }
                    await _firestore
                        .collection('patients')
                        .doc(icCtrl.text)
                        .set({
                      'ic_number': icCtrl.text,
                      'name': nameCtrl.text,
                      'address': addressCtrl.text,
                      'age': ageCtrl.text,
                      'mobile': mobileCtrl.text,
                      'timestamp': Timestamp.now(),
                    });

                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B2CBF);

    return Scaffold(
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      backgroundColor: const Color(0xFFF5F5F5),

      // --- 7. MODIFY THE FAB ---
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat, // Change this
        backgroundColor: purple,
        child: Icon(
          _isChatVisible ? Icons.close : Icons.smart_toy, // Change icon
          color: Colors.white,
        ),
      ),

      // --- 8. MODIFY THE BODY (use a Stack) ---
      body: Stack(
        children: [
          // This is your original body content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PATIENT DETAILS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: purple, size: 30),
                          onPressed: _addPatientDialog,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('patients')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Center(
                              child: Text('No patient records'));
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                MaterialStatePropertyAll(Colors.grey.shade800),
                            headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            columns: const [
                              DataColumn(label: Text('IC Number')),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Address')),
                              DataColumn(label: Text('Age')),
                              DataColumn(label: Text('Mobile')),
                            ],
                            rows: docs.map((d) {
                              final data = d.data() as Map<String, dynamic>;
                              return DataRow(cells: [
                                DataCell(Text(data['ic_number'] ?? '')),
                                DataCell(Text(data['name'] ?? '')),
                                DataCell(Text(data['address'] ?? '')),
                                DataCell(Text(data['age'] ?? '')),
                                DataCell(Text(data['mobile'] ?? '')),
                              ]);
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 9. ADD THE CHAT POPUP WIDGET ---
          if (_isChatVisible)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildChatPopup(), // This is our new chat window
            ),
        ],
      ),
    );
  }

  // --- 10. ADD THE CHAT POPUP UI BUILDER ---
  Widget _buildChatPopup() {
    return Container(
      width: 350,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CHATBOT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _toggleChat,
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _loading) {
                  return _buildChatBubble(
                      ChatMessage(text: '...', isUser: false));
                }
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      hintText:
                          _loading ? 'Bot is thinking...' : 'Type Message...',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _loading ? null : _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF7B2CBF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 11. ADD THE CHAT BUBBLE BUILDER ---
  Widget _buildChatBubble(ChatMessage message) {
    const purple = Color(0xFF7B2CBF);

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
            color: message.isUser ? purple : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ]),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
