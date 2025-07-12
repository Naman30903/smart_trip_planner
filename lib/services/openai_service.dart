import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_response.dart';
import '../models/message.dart';

class GeminiService {
  late final Gemini _gemini;
  // Store chat history
  final List<Content> _chatHistory = [];

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    // Initialize the Gemini instance
    Gemini.init(apiKey: apiKey);
    _gemini = Gemini.instance;
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

      // Call the Gemini API
      final result = await _gemini.prompt(parts: [Part.text(fullPrompt)]);
      final output = result?.output;
      debugPrint('Gemini API raw output: $output'); // <-- Debug debugPrint here
      if (output == null || output.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }
      String jsonStr = output
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final itineraryJson = jsonDecode(jsonStr);
      return TripItinerary.fromJson(itineraryJson);
    } catch (e) {
      debugPrint('Error in Gemini API call: $e');
      if (e.toString().contains('503')) {
        throw Exception(
          'Gemini API is temporarily unavailable. Please try again later.',
        );
      }
      throw Exception('Error generating itinerary: $e');
    }
    // // If execution reaches here, throw to avoid returning null
    // throw Exception('Failed to generate itinerary');
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

      // Initialize chat if it's empty
      if (_chatHistory.isEmpty) {
        _chatHistory.add(Content(role: 'user', parts: [Part.text(prompt)]));
      } else {
        // Add the new message to chat history
        _chatHistory.add(
          Content(role: 'user', parts: [Part.text(followUpQuestion)]),
        );
      }

      // Get the response using chat history
      debugPrint('Sending follow-up to Gemini: $followUpQuestion');
      final result = await _gemini.chat(_chatHistory);
      final response = result?.output;

      debugPrint('Gemini chat response: $response');

      // if (response == null || response.isEmpty) {
      //   throw Exception('Empty response from Gemini API');
      // }

      // Add the AI response to chat history
      _chatHistory.add(Content(role: 'model', parts: [Part.text(response!)]));

      return response;
    } catch (e) {
      debugPrint('Error refining itinerary: $e');
      throw Exception('Error refining itinerary: $e');
    }
  }
}
