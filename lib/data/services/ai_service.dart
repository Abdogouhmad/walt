import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:walt/data/models/walt_transaction.dart';

class AiService {
  static final AiService instance = AiService._();

  AiService._();

  final String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  Future<String> getSpendingInsights(List<WaltTransaction> transactions) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return "OpenRouter API key missing in .env";
    }

    if (transactions.isEmpty) {
      return "No transactions yet. Start adding some to get insights!";
    }
    final prompt =
        """
You are Walt AI, a smart and modern financial coach inside an expense tracker app.

Analyze the user's transactions and generate:
- one short financial insight
- 2 to 4 concise bullet points
- one actionable advice

Rules:
- Sound natural and human
- Be supportive, not robotic
- Keep everything short and readable
- Avoid generic financial clichés
- Mention spending patterns when relevant
- Focus on practical observations
- Maximum 70 words total
- No markdown
- No JSON
- No introductions like "Here is your analysis"

Transactions:
${transactions.map((tx) => "- ${tx.type}: ${tx.amount} MAD on ${tx.date} (${tx.note ?? 'no note'})").join('\n')}
""";
    // List of free models to try in order
    const models = [
      "google/gemma-4-26b-a4b-it",
      // "google/gemini-2.0-flash-exp:free",
      // "google/gemma-2-9b-it:free",
      // "meta-llama/llama-3.1-8b-instruct:free",
    ];

    for (final model in models) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://walt.app',
            'X-Title': 'Walt',
          },
          body: jsonEncode({
            "model": model,
            "messages": [
              {"role": "user", "content": prompt},
            ],
            "max_tokens": 200,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['choices'][0]['message']['content'] ??
              "No response generated.";
        }

        // Handle specific error codes
        if (response.statusCode == 429) {
          if (model == models.last) {
            return "AI is busy (Rate Limited). Please try again in a few minutes.";
          }
          // Continue to next model if this one is rate limited
          debugPrint('⚠️ Model $model is rate limited, trying next...');
          continue;
        }

        // Try to parse error message from body
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['error']?['message'] ??
              "AI Error: ${response.statusCode}";
          return errorMessage;
        } catch (_) {
          return "AI Error: ${response.statusCode}";
        }
      } catch (e) {
        debugPrint("OpenRouter Error for $model: $e");
        if (model == models.last) {
          return "Failed to connect to AI.";
        }
      }
    }

    return "AI Service unavailable.";
  }
}
