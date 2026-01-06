import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'nurse_appbar.dart';
import 'nurse_drawer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? filePath;

  ChatMessage({required this.text, required this.isUser, this.filePath});
}

String _filterGender = "All";
String _filterAgeRange = "All";
int _currentPage = 1;
int _rowsPerPage = 10;

class NurseHome1 extends StatefulWidget {
  const NurseHome1({super.key});

  @override
  State<NurseHome1> createState() => _NurseHomeState();
}

class _NurseHomeState extends State<NurseHome1> {
  static const Color sidebarPurple = Color(0xFF7B2CBF);
  static const Color accentGreen = Color(0xFF426A5A);
  static const Color bgColor = Color(0xFFF3F4F8);

  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _bpController = TextEditingController();

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bmiController = TextEditingController();
  final TextEditingController _hba1cController = TextEditingController();
  final TextEditingController _cholesterolController = TextEditingController();
  final TextEditingController _medHistoryController = TextEditingController();
  final TextEditingController _treatmentController = TextEditingController();
  String _selectedGender = "Female";

  final _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  late final GenerativeModel _model;
  bool _isChatVisible = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      debugPrint('API key not found. Make sure to set it in .env file');
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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
    final messageText = _chatController.text;
    if (messageText.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _loading = true;
    });
    _chatController.clear();
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
      debugPrint('Error sending message: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final file = result.files.first;
    final bytes = file.bytes;

    if (bytes == null) {
      setState(() {
        _messages.add(ChatMessage(
          text: "❌ Unable to read file content.",
          isUser: false,
        ));
      });
      return;
    }

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

    try {
      final pdfDocument = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(pdfDocument);
      extractedText = extractor.extractText();
      pdfDocument.dispose();
    } catch (e) {
      debugPrint("Syncfusion PDF extraction failed: $e");
    }

    if (extractedText.trim().isEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: "❗ Unable to extract text. PDF might be encrypted or scanned.",
          isUser: false,
        ));
        _loading = false;
      });
      return;
    }

    final summaryPrompt =
        "Here is the content of a PDF. Please summarize it in clear bullet points:\n\n$extractedText";

    try {
      final response =
          await _model.generateContent([Content.text(summaryPrompt)]);
      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? "⚠ Unable to generate summary.",
          isUser: false,
        ));
        _loading = false;
      });
    } catch (e) {
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

  // --- DATABASE LOGIC: ADD PATIENT ---
  Future<void> _savePatientToFirebase() async {
    if (_nameController.text.isEmpty || _icController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in Name and NRIC")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('patients').add({
        'name': _nameController.text.trim(),
        'ic_number': _icController.text.trim(),
        'gender': _selectedGender,
        'age': _ageController.text.trim(),
        'address': _addressController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'bmi': _bmiController.text, // New
        'bp': _bpController.text, // New
        'hba1c': _hba1cController.text, // New
        'cholesterol': _cholesterolController.text,
        'med_history': _medHistoryController.text,
        'treatment': _treatmentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _clearForm();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient registered successfully!")),
      );
    } catch (e) {
      debugPrint("Firebase Error: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _icController.clear();
    _ageController.clear();
    _addressController.clear();
    _mobileController.clear();
    _heightController.clear();
    _weightController.clear();
    _bpController.clear();
  }

  void _showAddPatientDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF8F9FA), // Soft background
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: 900,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- SECTION 1: PATIENT INFORMATION ---
                    _buildSectionCard("Patient Information", [
                      _dialogFieldInline("Name", _nameController),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _buildDropdownField(
                                  "Gender",
                                  ["Male", "Female"],
                                  _selectedGender,
                                  (val) => setDialogState(
                                      () => _selectedGender = val!))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildDatePickerField(
                                  "Birth Date", _dobController)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline("Age", _ageController)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogFieldInline("NRIC", _icController),
                      const SizedBox(height: 12),
                      _dialogFieldInline("Address", _addressController),
                    ]),

                    const SizedBox(height: 20),

                    // --- SECTION 2: VITAL SIGNS ---
                    _buildSectionCard("Vital Signs", [
                      Row(
                        children: [
                          Expanded(
                              child: _dialogFieldInline(
                                  "Height", _heightController,
                                  suffix: "cm")),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline(
                                  "Weight", _weightController,
                                  suffix: "kg")),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline("BMI", _bmiController)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline("BP", _bpController,
                                  hint: "120/80")),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _dialogFieldInline(
                                  "HBA1c", _hba1cController,
                                  suffix: "%")),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline(
                                  "Total Cholesterol", _cholesterolController,
                                  suffix: "mg/dL")),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // --- SECTION 3: CLINICAL INFORMATION ---
                    _buildSectionCard("Clinical Information", [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: _dialogFieldInline(
                                  "Medicine History", _medHistoryController,
                                  maxLines: 2,
                                  hint:
                                      "e.g. Hypertension medication since 2021")),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _dialogFieldInline(
                                  "Treatment Summary", _treatmentController,
                                  maxLines: 2, hint: "e.g. Daily monitoring")),
                        ],
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.only(bottom: 20, right: 24),
            actions: [
              ElevatedButton(
                onPressed: _savePatientToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6962),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save Changes",
                    style: TextStyle(color: Colors.white)),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print, size: 18),
                label: const Text("Print PDF"),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18)),
                child: const Text("Delete Record",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _dialogFieldInline(String label, TextEditingController controller,
      {String? suffix, String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

// 3. Date Picker
  Widget _buildDatePickerField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon: const Icon(Icons.calendar_today, size: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              controller.text =
                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
            }
          },
        ),
      ],
    );
  }

// 4. Dropdown
  Widget _buildDropdownField(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isDense: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dialogField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          TextField(
              controller: controller,
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: const NurseAppBar(),
      drawer: const NurseDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PATIENT LIST",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildPatientTable()),
              ],
            ),
          ),
          if (_isChatVisible)
            Positioned(bottom: 90, right: 20, child: _buildChatPopup()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleChat,
        backgroundColor: sidebarPurple,
        child: Icon(_isChatVisible ? Icons.close : Icons.smart_toy,
            color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end, // Aligns buttons and dropdowns to the bottom
      children: [
        // 1. Search Text Field
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Name or NRIC",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // 2. Gender Dropdown with Label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Gender",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterGender,
                  items: ["All", "Male", "Female"]
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) => setState(() => _filterGender = val!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // 3. Age Dropdown with Label
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Age",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterAgeRange,
                  items: ["All", "0-18", "19-40", "41-60", "60+"]
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (val) => setState(() => _filterAgeRange = val!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // 4. Add Patient Button
        ElevatedButton.icon(
          onPressed: _showAddPatientDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Add New Patient",
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 19)), // Slightly adjusted padding for alignment
        ),
      ],
    );
  }

  Widget _buildPatientTable() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 1. Apply Search and Dropdown Filters
                var filteredItems = snapshot.data!.docs.where((d) {
                  final nameMatch = d['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery) ||
                      d['ic_number'].toString().contains(_searchQuery);
                  final genderMatch =
                      _filterGender == "All" || d['gender'] == _filterGender;

                  bool ageMatch = true;
                  if (_filterAgeRange != "All") {
                    int age = int.tryParse(d['age'].toString()) ?? 0;
                    if (_filterAgeRange == "0-18")
                      ageMatch = age <= 18;
                    else if (_filterAgeRange == "19-40")
                      ageMatch = age >= 19 && age <= 40;
                    else if (_filterAgeRange == "41-60")
                      ageMatch = age >= 41 && age <= 60;
                    else if (_filterAgeRange == "60+") ageMatch = age > 60;
                  }
                  return nameMatch && genderMatch && ageMatch;
                }).toList();

                // 2. Pagination Calculation
                int totalItems = filteredItems.length;
                int totalPages = (totalItems / _rowsPerPage).ceil();
                if (_currentPage > totalPages && totalPages > 0)
                  _currentPage = totalPages;

                int startIndex = (_currentPage - 1) * _rowsPerPage;
                int endIndex = startIndex + _rowsPerPage;
                if (endIndex > totalItems) endIndex = totalItems;

                List<DocumentSnapshot> pageItems = totalItems > 0
                    ? filteredItems.sublist(startIndex, endIndex)
                    : [];

                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: pageItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) => _tableRow(
                            pageItems[i].data() as Map<String, dynamic>),
                      ),
                    ),
                    // 3. Pagination Control Row
                    _buildPaginationControls(totalPages, totalItems),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages, int totalItems) {
    return Padding(
      // Added extra bottom padding (60) to ensure the FAB doesn't cover the numbers
      padding: const EdgeInsets.fromLTRB(16, 16, 80, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // // View Button
          // ElevatedButton.icon(
          //   onPressed: () {
          //     // Logic to view details
          //   },
          //   icon: const Icon(Icons.visibility, size: 18, color: Colors.white),
          //   label: const Text("View All Details",
          //       style: TextStyle(color: Colors.white)),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: accentGreen,
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //   ),
          // ),

          // Pagination Numbers
          Row(
            children: [
              Text(
                "Page $_currentPage of $totalPages",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(width: 16),

              // Previous Button
              _pageNavButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
              ),

              const SizedBox(width: 8),

              // Simple Logic to show a few page numbers
              Row(
                children: List.generate(totalPages, (index) {
                  int pageNum = index + 1;
                  // Only show current page, first, last, and neighbors if many pages exist
                  if (totalPages > 5 &&
                      (pageNum != 1 &&
                          pageNum != totalPages &&
                          (pageNum - _currentPage).abs() > 1)) {
                    if (pageNum == 2 || pageNum == totalPages - 1)
                      return const Text("...");
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = pageNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _currentPage == pageNum
                            ? sidebarPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentPage == pageNum
                              ? sidebarPurple
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        "$pageNum",
                        style: TextStyle(
                          color: _currentPage == pageNum
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(width: 8),

              // Next Button
              _pageNavButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageNavButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
        ),
        child: Icon(icon,
            size: 20, color: onTap == null ? Colors.grey : sidebarPurple),
      ),
    );
  }

  Widget _tableHeader() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child:
                  Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("NRIC", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text("Gender",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("Age", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              flex: 2,
              child: Text("Address",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("BMI", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text("BP", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text("HbA1c", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child: Text("Last Visit",
                  style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 60), // Space for alignment with the action column
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> data) {
    bool isMale = data['gender'] == "Male";

    String lastVisit = "N/A";
    if (data['timestamp'] != null) {
      DateTime dt = (data['timestamp'] as Timestamp).toDate();
      lastVisit = "${dt.day}/${dt.month}/${dt.year}";
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Basic Info
          Expanded(
              child: Text(data['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(data['ic_number'] ?? '')),
          Expanded(
            child: Row(children: [
              Icon(isMale ? Icons.male : Icons.female,
                  size: 16, color: isMale ? Colors.blue : Colors.pink),
              Text(" ${data['gender']}")
            ]),
          ),
          Expanded(child: Text(data['age'] ?? '')),
          Expanded(
              flex: 2,
              child:
                  Text(data['address'] ?? '', overflow: TextOverflow.ellipsis)),

          Expanded(child: Text(data['bmi'] ?? '-')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(data['bp'] ?? '-'),
                const Text("mmHg",
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(child: Text("${data['hba1c'] ?? '-'}%")),
          Expanded(child: Text(lastVisit)),

          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildChatPopup() {
    return Container(
      width: 350,
      height: 450,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
                color: sidebarPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
            child: const Center(
                child: Text("AI CLINIC ASSISTANT",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, i) => ListTile(
                  title: Text(_messages[i].text),
                  tileColor:
                      _messages[i].isUser ? Colors.blue[50] : Colors.white),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.attach_file), onPressed: _pickFile),
                Expanded(
                    child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration:
                            const InputDecoration(hintText: "Ask AI..."))),
                IconButton(
                    icon: const Icon(Icons.send, color: accentGreen),
                    onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
