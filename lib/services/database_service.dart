import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/hive_models.dart';
import '../models/api_response.dart';

class DatabaseService {
  static const String _boxName = 'itineraries';
  late Box _box;
  bool _isInitialized = false;

  // Initialize Hive and open box
  Future<void> init() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    _isInitialized = true;
  }

  // Save an itinerary
  Future<String> saveItinerary(TripItinerary itinerary) async {
    await init(); // Ensure initialized
    
    try {
      final savedItinerary = SavedItinerary.fromApiModel(itinerary);
      final key = await _box.add(savedItinerary.toMap());
      return key.toString();
    } catch (e) {
      debugPrint('Error saving itinerary: $e');
      rethrow;
    }
  }

  // Get recent itineraries (limited by count)
  List<SavedItinerary> getRecentItineraries(int count) {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return [];
    }
    
    try {
      final values = _box.values.toList();
      final itineraries = values
          .map((map) => SavedItinerary.fromMap(Map<String, dynamic>.from(map)))
          .toList();
      
      // Sort by savedAt in descending order
      itineraries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      
      // Return only the requested number of items
      return itineraries.take(count).toList();
    } catch (e) {
      debugPrint('Error getting recent itineraries: $e');
      return [];
    }
  }

  // Get itinerary by key
  TripItinerary? getItineraryByKey(String key) {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return null;
    }
    
    try {
      final map = _box.get(int.parse(key));
      if (map == null) return null;
      
      final savedItinerary = SavedItinerary.fromMap(Map<String, dynamic>.from(map));
      return savedItinerary.toApiModel();
    } catch (e) {
      debugPrint('Error getting itinerary by key: $e');
      return null;
    }
  }

  // Delete itinerary
  Future<bool> deleteItinerary(String key) async {
    if (!_isInitialized) {
      debugPrint('Database not initialized');
      return false;
    }
    
    try {
      await _box.delete(int.parse(key));
      return true;
    } catch (e) {
      debugPrint('Error deleting itinerary: $e');
      return false;
    }
  }

  // Close the box when no longer needed
  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}
