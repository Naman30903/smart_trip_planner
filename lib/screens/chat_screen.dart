import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_response.dart';
import '../models/message.dart';
import '../services/openai_service.dart';
import '../providers/chat_provider.dart';
import 'dart:convert';

class ChatScreen extends ConsumerStatefulWidget {
  final TripItinerary itinerary;
  final Function(TripItinerary) onItineraryUpdated;

  const ChatScreen({
    Key? key,
    required this.itinerary,
    required this.onItineraryUpdated,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    // Add initial system message about the current itinerary
    _messages.add(
      Message(
        content:
            "Your current itinerary: ${widget.itinerary.title}\n"
            "From: ${widget.itinerary.startDate} to ${widget.itinerary.endDate}",
        sender: MessageSender.ai,
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(Message(content: userMessage, sender: MessageSender.user));
      _messages.add(
        Message(
          content: "Thinking...",
          sender: MessageSender.ai,
          isLoading: true,
        ),
      );
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final responseAsync = ref.read(
        refineItineraryProvider(
          RefineParams(
            followUp: userMessage,
            currentItinerary: widget.itinerary,
          ),
        ),
      );
      final responseValue = await responseAsync;

      // If responseValue is AsyncValue<String>, extract the value
      responseValue.when(
        data: (data) => _handleGeminiResponse(data),
        loading: () {},
        error: (err, stack) {
          setState(() {
            _messages.removeLast();
            _messages.add(
              Message(
                content:
                    "Sorry, I couldn't update your itinerary. Please try again.",
                sender: MessageSender.ai,
              ),
            );
            _isTyping = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        // Remove the "Thinking..." message
        _messages.removeLast();
        // Add error message
        _messages.add(
          Message(
            content:
                "Sorry, I couldn't update your itinerary. Please try again.",
            sender: MessageSender.ai,
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _handleGeminiResponse(String response) {
    // Try to parse the response as a JSON to update the itinerary
    try {
      // Extract JSON from response (remove any markdown formatting if present)
      String jsonStr = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> updatedItineraryJson = jsonDecode(jsonStr);
      final updatedItinerary = TripItinerary.fromJson(updatedItineraryJson);

      // Call the callback to update the parent's itinerary
      widget.onItineraryUpdated(updatedItinerary);

      setState(() {
        // Remove the "Thinking..." message
        _messages.removeLast();
        // Add the AI's response
        _messages.add(
          Message(
            content: "I've updated your itinerary with your request.",
            sender: MessageSender.ai,
          ),
        );
        _isTyping = false;
      });
    } catch (e) {
      // If not valid JSON, just display the response as text
      setState(() {
        // Remove the "Thinking..." message
        _messages.removeLast();
        // Add the AI's response
        _messages.add(Message(content: response, sender: MessageSender.ai));
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.itinerary.title,
          style: const TextStyle(color: Colors.black, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00704A),
            radius: 20,
            child: const Text(
              "S",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageItem(message);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Follow up to refine',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.mic, color: Color(0xFF00704A)),
                          onPressed: () {
                            // Implement speech-to-text functionality here
                          },
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: const Color(0xFF00704A),
                  elevation: 0,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFFF9B00),
              radius: 20,
              child: const Text(
                "I",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? "You" : "Itinera AI",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUser ? Colors.black : const Color(0xFFFF9B00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  message.isLoading
                      ? Row(
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF9B00),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              message.content,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        )
                      : Text(
                          message.content,
                          style: const TextStyle(color: Colors.black87),
                        ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF00704A),
              radius: 20,
              child: const Text(
                "S",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
