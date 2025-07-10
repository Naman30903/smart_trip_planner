import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/api_response.dart';

class GeminiService {
  late final Gemini _gemini;

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
      debugPrint('Gemini API raw output: $output'); // <-- Debug print here
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
      print('Error in Gemini API call: $e');
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
}
