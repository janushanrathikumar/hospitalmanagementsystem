import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'nurse_appbar.dart';
import 'nurse_drawer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? filePath;

  ChatMessage({required this.text, required this.isUser, this.filePath});
}

class NurseHome extends StatefulWidget {
  const NurseHome({super.key});

  @override
  State<NurseHome> createState() => _NurseHomeState();
}

class _NurseHomeState extends State<NurseHome> {
  final _firestore = FirebaseFirestore.instance;

  // Chat logic
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late final GenerativeModel _model;
  bool _loading = false;
  bool _isChatVisible = false;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('API key not found. Make sure to set it in .env file');
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Toggle chat visibility
  void _toggleChat() {
    setState(() {
      _isChatVisible = !_isChatVisible;
    });
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
Future<void> _pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );

  if (result == null) return; 

  final file = result.files.first;
  
  // 1. Check for byte data (Web-compatible approach)
  // This is used instead of dart:io.File(path).readAsBytesSync()
  final bytes = file.bytes;
  if (bytes == null) {
    setState(() {
      _messages.add(ChatMessage(
        text: "❌ Unable to read file content.",
        isUser: false,
      ));
      _loading = false;
    });
    return;
  }
  
  // Update UI immediately
  setState(() {
    _messages.add(ChatMessage(
      text: "📎 ${file.name}",
      isUser: true,
      filePath: file.path, 
    ));
    _loading = true;
  });
  _scrollToBottom();
  
  String extractedText = '';

  // Quick check for PDF magic number (using bytes)
  if (!(bytes.length >= 4 &&
      bytes[0] == 0x25 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x44 &&
      bytes[3] == 0x46)) {
    setState(() {
      _messages.add(ChatMessage(
        text: "❌ Unsupported file format. Please select a valid PDF.",
        isUser: false,
      ));
      _loading = false;
    });
    return;
  }

  // 2. Syncfusion PDF Text Extraction (Using bytes)
  try {
    final pdfDocument = PdfDocument(inputBytes: bytes);
    
    // Correctly initialize extractor with the document
    final PdfTextExtractor extractor = PdfTextExtractor(pdfDocument);
    extractedText = extractor.extractText();
    
    pdfDocument.dispose();
  } catch (e) {
    print("Syncfusion PDF extraction failed: $e");
    extractedText = ''; // Ensure text is empty if extraction fails
  }

  // ML Kit OCR fallback removed for Web compatibility.
  
  // 3. Check Final Extraction Result
  if (extractedText.trim().isEmpty) {
    setState(() {
      _messages.add(ChatMessage(
        text: "❗ Unable to extract text. PDF might be encrypted, scanned, or empty.",
        isUser: false,
      ));
      _loading = false;
    });
    return;
  }

  // 4. Send Extracted Text to Gemini Model
  final summaryPrompt = """
Here is the content of a PDF. Please summarize it in clear bullet points:

$extractedText
""";

  try {
    final response = await _model.generateContent([Content.text(summaryPrompt)]);

    // 5. Add Bot Response
    setState(() {
      _messages.add(ChatMessage(
        text: response.text ?? "⚠ Unable to generate summary.",
        isUser: false,
      ));
      _loading = false;
    });
  } catch (e) {
    print('Critical Error generating content: $e');
    setState(() {
      _messages.add(ChatMessage(
        text: "❌ AI response failed: $e",
        isUser: false,
      ));
      _loading = false;
    });
  }

  _scrollToBottom();
}
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
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: purple,
        child: Icon(
          _isChatVisible ? Icons.close : Icons.smart_toy,
          color: Colors.white,
        ),
      ),
      body: Stack(
        children: [
          // Main content
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
                          icon:
                              const Icon(Icons.add_circle, color: purple, size: 30),
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
                          return const Center(child: Text('No patient records'));
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor:
                                MaterialStateProperty.all(Colors.grey.shade800),
                            headingTextStyle: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
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
          // Chat popup
          if (_isChatVisible)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildChatPopup(),
            ),
        ],
      ),
    );
  }

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
          // Header
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
          // Messages
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
          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _loading ? null : _pickFile,
                ),
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
