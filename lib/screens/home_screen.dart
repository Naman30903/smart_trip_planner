import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/openai_service.dart';
import '../models/api_response.dart';
import 'itinerary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final savedItineraries = [
    "Japan Trip, 20 days vacation,explore ky...",
    "India Trip, 7 days work trip, suggest affor...",
    "Europe trip, include Paris, Berlin, Dortmun...",
    "Two days weekend getaway to somewhe...",
  ];

  final TextEditingController _tripController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;

  // Initialize Gemini service with your API key
  final GeminiService _geminiService = GeminiService(
    apiKey: "AIzaSyBcVFjO8TEtV6b_vCN1RLoIUz7bDV-y440",
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _tripController.text = val.recognizedWords;
              _tripController.selection = TextSelection.fromPosition(
                TextPosition(offset: _tripController.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Function to generate itinerary
  Future<void> _generateItinerary() async {
    if (_tripController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your trip first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final itinerary = await _geminiService.generateItinerary(
        _tripController.text,
      );

      // Navigate to the itinerary screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItineraryScreen(itinerary: itinerary),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tripController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Hey Shubham ",
                            style: TextStyle(
                              color: Color(0xFF00704A),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          WidgetSpan(
                            child: Padding(
                              padding: EdgeInsets.only(left: 2.0),
                              child: Text("👋", style: TextStyle(fontSize: 28)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00704A),
                      radius: 24,
                      child: const Text(
                        "S",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Text(
                    "What’s your vision\nfor this trip?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFF00704A), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tripController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText:
                                "Describe your trip (e.g. 7 days in Bali next April, 3 people, mid-range budget...)",
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: Color(0xFF00704A),
                            size: 28,
                          ),
                          onPressed: _listen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00704A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 0,
                      ),
                      onPressed: _isLoading ? null : _generateItinerary,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create My Itinerary",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Center(
                  child: Text(
                    "Offline Saved Itineraries",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...savedItineraries.map(
                  (itinerary) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.circle,
                          color: Color(0xFF00C48C),
                          size: 16,
                        ),
                        title: Text(
                          itinerary,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
