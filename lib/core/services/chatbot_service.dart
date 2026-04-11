import 'dart:convert';
import 'openai_service.dart';
import 'firestore_service.dart';

/// Singleton that owns the chatbot conversation state and calls OpenAI.
/// Matches the singleton pattern used by UserSession.
class ChatbotService {
  ChatbotService._();
  static final instance = ChatbotService._();

  final _openAI = OpenAIService();
  final _firestore = FirestoreService();

  final List<Map<String, String>> _history = [];

  /// Read-only snapshot of the conversation so far.
  List<Map<String, String>> get messageHistory =>
      List.unmodifiable(_history);

  /// Send [userMessage], inject today's live schedule as system context,
  /// return the assistant reply.
  Future<String> sendMessage(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});

    final scheduleContext = await _todayScheduleContext();

    final systemPrompt =
        'You are the KUET Bus assistant. You help students and staff with '
        'bus schedules, routes, timings, and app features. Only answer '
        'questions relevant to the KUET bus service. Be friendly, concise, '
        'and accurate. Here is today\'s live schedule: $scheduleContext';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      ..._history,
    ];

    final reply = await _openAI.sendMessage(messages);
    _history.add({'role': 'assistant', 'content': reply});
    return reply;
  }

  /// Wipe conversation history (e.g. when chat panel is closed).
  void clearHistory() => _history.clear();

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<String> _todayScheduleContext() async {
    try {
      final now = DateTime.now();
      final date =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final data = await _firestore.getLiveScheduleOnce(date);
      if (data != null) return jsonEncode(data);
    } catch (_) {}
    return 'No live schedule available for today.';
  }
}
