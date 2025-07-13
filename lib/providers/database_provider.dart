import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/hive_models.dart';
import '../models/api_response.dart';

// Provider for the database service
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  // Initialize the service
  service.init();
  return service;
});

// Provider for recent itineraries
final recentItinerariesProvider = FutureProvider<List<SavedItinerary>>((
  ref,
) async {
  final dbService = ref.watch(databaseServiceProvider);
  await dbService.init();
  return dbService.getRecentItineraries(5); // Get last 5 saved itineraries
});

// Provider for saving an itinerary
final saveItineraryProvider = FutureProvider.family<String, TripItinerary>((
  ref,
  itinerary,
) async {
  final dbService = ref.watch(databaseServiceProvider);
  final key = await dbService.saveItinerary(itinerary);

  // Refresh the recent itineraries list
  ref.invalidate(recentItinerariesProvider);

  return key;
});

// Provider for deleting an itinerary
final deleteItineraryProvider = FutureProvider.family<bool, String>((
  ref,
  key,
) async {
  final dbService = ref.watch(databaseServiceProvider);
  final result = await dbService.deleteItinerary(key);

  // Refresh the recent itineraries list
  ref.invalidate(recentItinerariesProvider);

  return result;
});

// Add this provider for a specific itinerary by key
final itineraryByKeyProvider = FutureProvider.family<TripItinerary?, String>((
  ref,
  key,
) async {
  final dbService = ref.watch(databaseServiceProvider);
  await dbService.init();
  return dbService.getItineraryByKey(key);
});
