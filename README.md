# Smart Trip Planner

A Flutter application that uses Google's Gemini AI to generate and refine personalized travel itineraries based on user preferences.

## Demo

[Watch Demo Video](https://youtu.be/your-video-id) 

 

### Key Components:

1. **Presentation Layer**
   - Screens: Home, Authentication, Itinerary, Chat, Profile
   - State Management: Flutter Riverpod for dependency injection and state management

2. **Business Logic Layer**
   - Services: Authentication, Database, AI (Gemini)
   - Providers: Connect UI with services, handle state transitions

3. **Data Layer**
   - Models: API responses, local storage models
   - Repository: Local storage with Hive for offline access

4. **External Services**
   - Firebase Authentication
   - Google Gemini API for AI-powered itinerary generation
   - Maps integration

## Setup Instructions

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart 3.0.0 or higher
- Firebase project
- Google Gemini API key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Naman30903/smart_trip_planner.git
   cd smart_trip_planner
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase:**
   ```bash
   # Install Firebase CLI if needed
   brew install firebase-cli
   # OR
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Configure Firebase for Flutter
   flutterfire configure --project=your-firebase-project-id
   ```

4. **Create a .env file in the project root with your Gemini API key:**
   ```
   GEMINI_API_KEY=your-gemini-api-key
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## Agent Chain Workflow

### 1. Initial Itinerary Generation
- **Input:** User provides natural language description of their trip
- **Processing:** 
  - Text is sent to Gemini API with structured prompt
  - Prompt includes JSON schema constraints for valid output
  - Gemini generates a complete travel itinerary
- **Validation:** Application validates JSON response and parses to model
- **Output:** Structured itinerary with days, activities, locations, and timing

### 2. Itinerary Refinement via Chat
- **Input:** User provides follow-up questions or modification requests
- **Context:** Current itinerary is included in the prompt context
- **Processing:** 
  - Full context and follow-up are sent to Gemini
  - Gemini generates updated itinerary maintaining format
- **Validation:** Application parses and validates the updated JSON
- **Output:** Modified itinerary reflecting user's refinement requests

### 3. Token Management
- Token usage is tracked for both requests and responses
- Costs are calculated based on token usage
- Usage statistics are persisted locally and displayed in Profile screen

## Token Cost Analysis

Based on our testing with various itinerary types:

| Itinerary Type | Avg. Request Tokens | Avg. Response Tokens | Approximate Cost |
|----------------|---------------------|----------------------|-----------------|
| Weekend Trip   | 200-300             | 1,000-2,000          | $0.001-$0.002   |
| Week-long Trip | 300-500             | 2,500-4,000          | $0.002-$0.003   |
| Complex Trip   | 500-800             | 4,000-7,000          | $0.003-$0.005   |
| Chat Refinement| 800-1,500           | 1,000-3,000          | $0.002-$0.004   |

Pricing model: $0.00025 per 1K input tokens, $0.0005 per 1K output tokens (Gemini Pro)

## Key Features

- User authentication with Firebase
- AI-generated travel itineraries
- Itinerary refinement through natural conversation
- Offline storage for itineraries
- Google Maps integration for locations
- Voice input for trip descriptions
- Token usage tracking and cost analysis

## Technical Implementation

- **State Management:** Flutter Riverpod
- **Local Storage:** Hive for offline persistence
- **Authentication:** Firebase Auth
- **AI Integration:** Google Gemini via flutter_gemini package
- **Maps:** URL launcher for Google Maps integration 

## License

MIT License - See [LICENSE](LICENSE) file for details.