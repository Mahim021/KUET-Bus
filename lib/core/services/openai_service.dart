import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Thin wrapper around the OpenAI Chat Completions endpoint.
class OpenAIService {
  static const _endpoint =
      'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o';
  static const _timeout = Duration(seconds: 30);

  /// Send [messages] to GPT-4o and return the assistant reply string.
  /// Returns a friendly fallback on any error so callers never have to catch.
  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer ${ApiConstants.openAiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'messages': messages,
              'temperature': 0.7,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['choices'] as List).first['message']['content']
            as String;
      }

      // Surface a readable API error without crashing.
      final err = jsonDecode(response.body);
      final msg = err['error']?['message'] ?? 'Unknown API error';
      return 'Sorry, I got an error from the AI service: $msg';
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'Sorry, the request timed out. Please try again.';
      }
      return 'Sorry, I\'m having trouble connecting right now. Please try again.';
    }
  }
}
