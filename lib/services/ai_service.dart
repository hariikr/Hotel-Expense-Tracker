import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Service to handle AI chat interactions
class AiService {
  final SupabaseClient _supabase;

  AiService(this._supabase);

  /// Generate rich contextual information for AI
  Map<String, dynamic> _getContextualInfo() {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE').format(now);
    final date = DateFormat('dd MMMM yyyy').format(now);
    final time = DateFormat('hh:mm a').format(now);
    final malayalamMonth = _getMalayalamMonth(now.month);
    final malayalamDay = _getMalayalamDay(now.weekday);

    // Determine time of day
    String timeOfDay;
    String malayalamTimeOfDay;
    if (now.hour < 12) {
      timeOfDay = 'Morning';
      malayalamTimeOfDay = 'രാവിലെ';
    } else if (now.hour < 17) {
      timeOfDay = 'Afternoon';
      malayalamTimeOfDay = 'ഉച്ചയ്ക്ക്';
    } else if (now.hour < 20) {
      timeOfDay = 'Evening';
      malayalamTimeOfDay = 'വൈകുന്നേരം';
    } else {
      timeOfDay = 'Night';
      malayalamTimeOfDay = 'രാത്രി';
    }

    // Check if weekend
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    // Business insights based on day
    String businessTip = '';
    if (now.weekday == DateTime.monday) {
      businessTip =
          'ആഴ്ചയുടെ തുടക്കം - വരുമാനവും ചെലവും ട്രാക്ക് ചെയ്യാൻ തുടങ്ങൂ';
    } else if (isWeekend) {
      businessTip =
          'വാരാന്ത്യം - ഈ ആഴ്ചയുടെ സാമ്പത്തിക വിശകലനം നടത്താൻ നല്ല സമയം';
    } else if (now.day <= 7) {
      businessTip = 'മാസത്തിന്റെ ആദ്യ ആഴ്ച - മാസിക ലക്ഷ്യങ്ങൾ സജ്ജീകരിക്കൂ';
    } else if (now.day >= 25) {
      businessTip = 'മാസാവസാനം - പേയ്മെന്റുകളും അക്കൗണ്ടുകളും പൂർത്തിയാക്കൂ';
    }

    return {
      'currentDateTime': now.toIso8601String(),
      'date': date,
      'time': time,
      'dayOfWeek': weekday,
      'malayalamDay': malayalamDay,
      'malayalamMonth': malayalamMonth,
      'timeOfDay': timeOfDay,
      'malayalamTimeOfDay': malayalamTimeOfDay,
      'isWeekend': isWeekend,
      'dayOfMonth': now.day,
      'monthNumber': now.month,
      'year': now.year,
      'businessTip': businessTip,
      'role': 'AI assistant for hotel expense tracking and business guidance',
      'userRole': 'Hotel/business owner entrepreneur mother',
      'tone':
          'Friendly, supportive, educational, encouraging like a business mentor',
    };
  }

  /// Get Malayalam month name
  String _getMalayalamMonth(int month) {
    const months = [
      'ജനുവരി',
      'ഫെബ്രുവരി',
      'മാർച്ച്',
      'ഏപ്രിൽ',
      'മേയ്',
      'ജൂൺ',
      'ജൂലൈ',
      'ആഗസ്റ്റ്',
      'സെപ്റ്റംബർ',
      'ഒക്ടോബർ',
      'നവംബർ',
      'ഡിസംബർ'
    ];
    return months[month - 1];
  }

  /// Get Malayalam day name
  String _getMalayalamDay(int weekday) {
    const days = ['തിങ്കൾ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'വെള്ളി', 'ശനി', 'ഞായർ'];
    return days[weekday - 1];
  }

  /// Send a message to the AI assistant and get a response
  ///
  /// [message] - The user's message in Malayalam or English
  /// [userId] - Optional user ID (can be null for no-auth scenario)
  /// [conversationHistory] - Optional list of recent messages for context
  ///
  /// Returns the AI's response text
  Future<AiChatResponse> sendMessage(
    String message, {
    String? userId,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      // Get rich contextual information
      final contextInfo = _getContextualInfo();

      // Call the Edge Function with conversation history and context
      final response = await _supabase.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'userId': userId,
          'contextInfo':
              contextInfo, // Rich context about time, date, business tips
          if (conversationHistory != null && conversationHistory.isNotEmpty)
            'conversationHistory': conversationHistory,
        },
      );

      // Check for errors
      if (response.status != 200) {
        throw Exception('Failed to get response from AI: ${response.status}');
      }

      final data = response.data;
      if (data == null) {
        throw Exception('No data received from AI');
      }

      final reply = data['reply'] as String?;
      final toolsUsed = (data['toolsUsed'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      if (reply == null || reply.isEmpty) {
        throw Exception('Empty response from AI');
      }

      return AiChatResponse(
        reply: reply,
        toolsUsed: toolsUsed ?? [],
        timestamp: DateTime.now(),
      );
    } catch (e) {
      // Return a user-friendly error message
      return AiChatResponse(
        reply: _getErrorMessage(e),
        toolsUsed: [],
        timestamp: DateTime.now(),
        hasError: true,
      );
    }
  }

  /// Get chat history from database
  ///
  /// [userId] - Optional user ID to filter by
  /// [limit] - Number of messages to fetch (default: 50)
  Future<List<ChatHistoryItem>> getChatHistory({
    String? userId,
    int limit = 50,
  }) async {
    try {
      dynamic response;

      if (userId != null) {
        response = await _supabase
            .from('chat_messages')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);
      } else {
        response = await _supabase
            .from('chat_messages')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
      }

      return (response as List)
          .map((item) => ChatHistoryItem.fromJson(item))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }

  /// Clear chat history for a specific user
  Future<bool> clearChatHistory({String? userId}) async {
    try {
      if (userId != null) {
        await _supabase.from('chat_messages').delete().eq('user_id', userId);
      } else {
        await _supabase
            .from('chat_messages')
            .delete()
            .isFilter('user_id', null);
      }
      return true;
    } catch (e) {
      print('Error clearing chat history: $e');
      return false;
    }
  }

  /// Get error message in both languages
  String _getErrorMessage(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    // Check for specific error types
    if (errorMsg.contains('network') || errorMsg.contains('connection')) {
      return 'Network error. Please check your connection.\n\nനെറ്റ്‌വർക്ക് പിശക്. നിങ്ങളുടെ കണക്ഷൻ പരിശോധിക്കുക.';
    } else if (errorMsg.contains('timeout')) {
      return 'Request timed out. Please try again.\n\nസമയം കഴിഞ്ഞു. ദയവായി വീണ്ടും ശ്രമിക്കുക.';
    } else {
      return 'AI is not available right now. Please try again later.\n\nAI ഇപ്പോൾ ലഭ്യമല്ല. ദയവായി പിന്നീട് ശ്രമിക്കുക.';
    }
  }
}

/// Response from AI chat
class AiChatResponse {
  final String reply;
  final List<String> toolsUsed;
  final DateTime timestamp;
  final bool hasError;

  AiChatResponse({
    required this.reply,
    required this.toolsUsed,
    required this.timestamp,
    this.hasError = false,
  });
}

/// Chat history item
class ChatHistoryItem {
  final String id;
  final String? userId;
  final String message;
  final String response;
  final String language;
  final DateTime createdAt;

  ChatHistoryItem({
    required this.id,
    this.userId,
    required this.message,
    required this.response,
    required this.language,
    required this.createdAt,
  });

  factory ChatHistoryItem.fromJson(Map<String, dynamic> json) {
    return ChatHistoryItem(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      message: json['message'] as String,
      response: json['response'] as String,
      language: json['language'] as String? ?? 'en',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'message': message,
      'response': response,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
