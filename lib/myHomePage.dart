import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gemini_gpt/message.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemini_gpt/themeNotifier.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController(); // Add a ScrollController
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose(); // Dispose the ScrollController when not in use
    super.dispose();
  }

  void _scrollToBottom() {
    // Check if there are items in the list to scroll
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  callGeminiModel() async {
    try {
      if (_controller.text.isNotEmpty) {
        String userInput = _controller.text;
        _controller.clear();

        setState(() {
          _messages.add(Message(text: userInput, isUser: true));
          _isLoading = true;
        });

        // Scroll to the bottom when a new user message is added
        _scrollToBottom();

        final model = GenerativeModel(model: 'gemini-pro', apiKey: dotenv.env['GOOGLE_API_KEY']!);
        final prompt = userInput.trim();
        final content = [Content.text(prompt)];
        final response = await model.generateContent(content);

        setState(() {
          _messages.add(Message(text: response.text!, isUser: false));
          _isLoading = false;
        });

        // Scroll to the bottom when a new AI response is added
        _scrollToBottom();
      }
    } catch (e) {
      print("Error : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset('assets/gpt-robot.png', height: 40, width: 40),
                const SizedBox(width: 10),
                Text('Gemini Gpt', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            GestureDetector(
              child: (currentTheme == ThemeMode.dark)
                  ? Icon(Icons.light_mode, color: Theme.of(context).colorScheme.secondary)
                  : Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.primary),
              onTap: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController, // Attach the ScrollController to ListView
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: ListTile(
                    title: Align(
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: message.isUser
                              ? LinearGradient(colors: [Colors.blue, Colors.blueAccent]) // Blue gradient for user messages
                              : LinearGradient(colors: [Colors.grey, Colors.grey.shade300]), // Gray gradient for AI messages
                          borderRadius: message.isUser
                              ? const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          )
                              : const BorderRadius.only(
                            topRight: Radius.circular(20),
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: message.isUser
                              ? Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white) // White text for user messages
                              : Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.black87), // Dark text for AI messages
                        ),
                      ),
                    ),
                  ),
                );

              },
            ),
          ),
          // User input field
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey.shade200],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: Theme.of(context).textTheme.titleSmall,
                      decoration: InputDecoration(
                        hintText: 'Write your message...',
                        hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isLoading
                      ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(), // Loading indicator
                    ),
                  )
                      : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      child: Image.asset('assets/send.png',height: 30, width: 30),
                      onTap: callGeminiModel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
