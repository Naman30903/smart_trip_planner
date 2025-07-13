import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/openai_service.dart';
import '../models/api_response.dart';

// Provider for GeminiService singleton
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(ref: ref);
});

// Async provider for generating itinerary
final itineraryProvider = FutureProvider.family<TripItinerary, String>((
  ref,
  prompt,
) async {
  final geminiService = ref.watch(geminiServiceProvider);
  return await geminiService.generateItinerary(prompt);
});

// Async provider for refining itinerary via chat
final refineItineraryProvider = FutureProvider.family<String, RefineParams>((
  ref,
  params,
) async {
  final geminiService = ref.watch(geminiServiceProvider);
  return await geminiService.refineItinerary(
    params.followUp,
    params.currentItinerary,
  );
});

// Helper class for passing params to refineItineraryProvider
class RefineParams {
  final String followUp;
  final TripItinerary currentItinerary;
  RefineParams({required this.followUp, required this.currentItinerary});
}
