import 'package:smart_trip_planner/models/api_response.dart';

enum MessageSender { user, ai }

class Message {
  final String content;
  final MessageSender sender;
  final bool isLoading;
  final TripItinerary? itineraryPreview;

  Message({
    required this.content,
    required this.sender,
    this.isLoading = false,
    this.itineraryPreview,
  });
}
