import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_response.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_screen.dart';
import '../providers/database_provider.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  final TripItinerary itinerary;

  const ItineraryScreen({super.key, required this.itinerary});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  late TripItinerary _itinerary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _itinerary = widget.itinerary;
  }

  void _updateItinerary(TripItinerary updatedItinerary) {
    setState(() {
      _itinerary = updatedItinerary;
    });
  }

  Future<void> _saveItineraryOffline() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final key = await ref.read(saveItineraryProvider(_itinerary).future);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Itinerary saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving itinerary: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
        title: const Text("Home", style: TextStyle(color: Colors.black)),
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Itinerary Created ",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const WidgetSpan(
                  child: Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text("🏝️", style: TextStyle(fontSize: 32)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var day in _itinerary.days) _buildDayCard(context, day),
          const SizedBox(height: 24),
          _buildActionButtons(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, Day day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Day ${_getDayNumber(day.date)}: ${day.summary}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (var item in day.items)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "• ${item.time}: ",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.activity,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  if (day.items.last != item) const SizedBox(height: 12),
                ],
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _openMap(day.items.first.location),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    "Open in maps",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_calculateTripLength(day.items)} mins",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.chat),
            label: const Text("Follow up to refine"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00704A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    itinerary: _itinerary,
                    onItineraryUpdated: _updateItinerary,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(_isSaving ? "Saving..." : "Save Offline"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isSaving ? null : _saveItineraryOffline,
          ),
        ),
      ],
    );
  }

  String _getDayNumber(String date) {
    try {
      final dayNumber = int.parse(date.split('-')[2]);
      return dayNumber.toString();
    } catch (e) {
      return "1";
    }
  }

  int _calculateTripLength(List<Item> items) {
    // This is a mock function, in a real app you would calculate trip duration
    // based on locations and transportation methods
    return 11 * 60 + 5; // 11 hours 5 mins
  }

  Future<void> _openMap(String location) async {
    try {
      final coordinates = location.split(',');
      if (coordinates.length == 2) {
        final lat = double.parse(coordinates[0]);
        final lng = double.parse(coordinates[1]);
        final url = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw Exception('Could not launch map URL');
        }
      }
    } catch (e) {
      // Show a snackbar if plugin is missing or any error occurs
      // You need BuildContext, so pass it as a parameter if needed
      print('Error opening map: $e');
      // Optionally, show a snackbar or dialog to the user
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open map.')));
    }
  }
}
