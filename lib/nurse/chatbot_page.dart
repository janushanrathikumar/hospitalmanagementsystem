import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- 1. Import
import 'package:google_generative_ai/google_generative_ai.dart'; // <-- 2. Import

// A simple class to hold message data
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // --- 3. Add Gemini variables ---
  late final GenerativeModel _model;
  bool _loading = false;
  // ------------------------------

  @override
  void initState() {
    super.initState();
    // --- 4. Initialize the model ---
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      print('API key not found. Make sure to set it in .env file');
      return;
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    // -------------------------------
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- 5. Update _sendMessage to call the API ---
  Future<void> _sendMessage() async {
    final messageText = _messageController.text;
    if (messageText.isEmpty || _loading) return;

    // Add the user's message
    setState(() {
      _messages.add(ChatMessage(text: messageText, isUser: true));
      _loading = true; // Show a loading indicator
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Send the message to the Gemini API
      final content = [Content.text(messageText)];
      final response = await _model.generateContent(content);

      // Add the bot's response
      setState(() {
        _messages.add(
            ChatMessage(text: response.text ?? 'No response', isUser: false));
        _loading = false; // Hide loading
      });
      _scrollToBottom();
    } catch (e) {
      // Handle errors
      setState(() {
        _messages
            .add(ChatMessage(text: 'Error: ${e.toString()}', isUser: false));
        _loading = false; // Hide loading
      });
      _scrollToBottom();
      print('Error sending message: $e');
    }
  }
  // --- End of update ---

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('CHATBOT'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount:
                  _messages.length + (_loading ? 1 : 0), // +1 for loading
              itemBuilder: (context, index) {
                // --- 6. Add a loading bubble ---
                if (index == _messages.length && _loading) {
                  return _buildChatBubble(
                      ChatMessage(text: '...', isUser: false));
                }
                // -----------------------------

                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
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
                    // --- 7. Disable input while loading ---
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
                  // Disable button while loading
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
            color: message.isUser ? purple : Colors.white,
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
