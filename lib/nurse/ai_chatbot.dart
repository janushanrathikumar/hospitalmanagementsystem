import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AiChatBot extends StatefulWidget {
  final GenerativeModel model;
  final Color primaryColor;

  const AiChatBot({
    super.key,
    required this.model,
    this.primaryColor = const Color(0xFF4A3469),
  });

  @override
  State<AiChatBot> createState() => _AiChatBotState();
}

class _AiChatBotState extends State<AiChatBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = false;

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({'text': text, 'user': true});
      _loading = true;
    });
    _controller.clear();
    _scrollBottom();

    try {
      final response =
          await widget.model.generateContent([Content.text(text)]);
      setState(() {
        _messages.add({
          'text': response.text ?? "No response",
          'user': false
        });
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'text': "Error: $e", 'user': false});
        _loading = false;
      });
    }
    _scrollBottom();
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.first.bytes == null) return;

    final bytes = result.files.first.bytes!;
    final pdf = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(pdf).extractText();
    pdf.dispose();

    await _sendMessage(
        "Summarize the following medical document:\n\n$text");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Text(
              "AI Clinic Assistant",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg['user']
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: msg['user']
                          ? widget.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(msg['text']),
                  ),
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickPdf),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: _sendMessage,
                  decoration:
                      const InputDecoration(hintText: "Ask something..."),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: widget.primaryColor),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          )
        ],
      ),
    );
  }
}
