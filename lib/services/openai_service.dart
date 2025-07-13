import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_response.dart';
import '../models/message.dart';

class GeminiService {
  late final Gemini _gemini;
  final List<Content> _chatHistory = [];
  int _requestTokens = 0;
  int _responseTokens = 0;
  final int _maxTokens = 1000;

  int get requestTokens => _requestTokens;
  int get responseTokens => _responseTokens;
  int get maxTokens => _maxTokens;

  double get totalCost {
    // $0.00025 per 1K input tokens, $0.0005 per 1K output tokens (Gemini Pro)
    double inputCost = (_requestTokens / 1000) * 0.00025;
    double outputCost = (_responseTokens / 1000) * 0.0005;
    return inputCost + outputCost;
  }

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    // Initialize the Gemini instance
    Gemini.init(apiKey: apiKey);
    _gemini = Gemini.instance;
  }

  Future<int> _countTokens(String text) async {
    try {
      final tokenCount = await _gemini.countTokens(text);
      return tokenCount ?? 0;
    } catch (e) {
      debugPrint('Error counting tokens: $e');
      // Fallback to basic estimation if token counting fails
      return (text.length / 4).ceil();
    }
  }

  Future<TripItinerary> generateItinerary(String prompt) async {
    try {
      // Create the prompt with specific JSON schema instructions
      final fullPrompt =
          """Create a detailed travel itinerary based on this description: "$prompt".
      Return ONLY valid JSON that exactly follows this schema:
      {
        "title": "Trip title",
        "startDate": "YYYY-MM-DD",
        "endDate": "YYYY-MM-DD",
        "days": [
          {
            "date": "YYYY-MM-DD",
            "summary": "Day summary",
            "items": [
              {
                "time": "HH:MM",
                "activity": "Description of activity",
                "location": "latitude,longitude"
              }
            ]
          }
        ]
      }
      Make the itinerary realistic and detailed. 
      Do not include any text before or after the JSON. No markdown formatting.""";

      final requestTokenCount = await _countTokens(fullPrompt);
      _requestTokens += requestTokenCount;

      // Call the Gemini API
      final result = await _gemini.prompt(parts: [Part.text(fullPrompt)]);
      final output = result?.output;
      debugPrint('Gemini API raw output: $output');
      if (output == null || output.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      final responseTokenCount = await _countTokens(output);
      _responseTokens += responseTokenCount;

      String jsonStr = output
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final itineraryJson = jsonDecode(jsonStr);
      return TripItinerary.fromJson(itineraryJson);
    } on FormatException catch (_) {
      throw Exception('The response was not valid JSON. Please try again.');
    } on GeminiException catch (e) {
      if ((e.message as String).contains('401')) {
        throw Exception('Unauthorized: Please check your API key.');
      } else if ((e.message as String).contains('429')) {
        throw Exception('Too many requests. Please wait and try again.');
      } else {
        throw Exception('Gemini API error: ${e.message}');
      }
    } on SocketException catch (_) {
      throw Exception('Network error: Please check your internet connection.');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<String> refineItinerary(
    String followUpQuestion,
    TripItinerary currentItinerary,
  ) async {
    try {
      // Convert the current itinerary to a JSON string
      final currentItineraryJson = jsonEncode({
        "title": currentItinerary.title,
        "startDate": currentItinerary.startDate,
        "endDate": currentItinerary.endDate,
        "days": currentItinerary.days
            .map(
              (day) => {
                "date": day.date,
                "summary": day.summary,
                "items": day.items
                    .map(
                      (item) => {
                        "time": item.time,
                        "activity": item.activity,
                        "location": item.location,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      });

      // Create a prompt that includes the current itinerary and the follow-up question
      final prompt =
          """I have the following travel itinerary:
      $currentItineraryJson
      
      User request: "$followUpQuestion"
      
      Please update the itinerary to incorporate this request. Return the complete, revised itinerary as valid JSON following the same schema, with all the original details plus the requested changes. Make sure the response is a valid JSON that I can parse.""";

      final requestTokenCount = await _countTokens(prompt);
      _requestTokens += requestTokenCount;

      // Initialize chat if it's empty
      if (_chatHistory.isEmpty) {
        _chatHistory.add(Content(role: 'user', parts: [Part.text(prompt)]));
      } else {
        _chatHistory.add(
          Content(role: 'user', parts: [Part.text(followUpQuestion)]),
        );
      }

      // Get the response using chat history
      debugPrint('Sending follow-up to Gemini: $followUpQuestion');
      final result = await _gemini.chat(_chatHistory);
      final response = result?.output;

      debugPrint('Gemini chat response: $response');

      if (response != null && response.isNotEmpty) {
        // Update response tokens
        final responseTokenCount = await _countTokens(response);
        _responseTokens += responseTokenCount;

        // Add the AI response to chat history
        _chatHistory.add(Content(role: 'model', parts: [Part.text(response)]));
      }

      return response ?? '';
    } catch (e) {
      debugPrint('Error refining itinerary: $e');
      throw Exception('Error refining itinerary: $e');
    }
  }
}
