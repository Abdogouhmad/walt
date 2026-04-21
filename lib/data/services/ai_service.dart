import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:walt/data/models/walt_transaction.dart';

class AiService {
  static final AiService instance = AiService._();
  AiService._();

  GenerativeModel? _model;

  // Lazy initialization to ensure dotenv is loaded
  GenerativeModel get _getModel {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    _model ??= GenerativeModel(
      model: 'gemma-3-27b-it',
      apiKey: apiKey,
      requestOptions: const RequestOptions(apiVersion: 'v1beta'),
    );
    return _model!;
  }

  Future<String> getSpendingInsights(List<WaltTransaction> transactions) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty)
      return "API Key not found. Please check your .env file.";
    if (transactions.isEmpty)
      return "No transactions yet. Start adding some to get insights!";

    final prompt =
        """
    Analyze the following list of transactions and provide a short, helpful financial insight (max 3 sentences).
    Transactions:
    ${transactions.map((tx) => "- ${tx.type}: ${tx.amount} on ${tx.date.toString()} (${tx.note ?? 'No note'})").join('\n')}
    
    Format the response as a friendly piece of advice.
    """;

    try {
      final content = [Content.text(prompt)];
      final response = await _getModel.generateContent(content);
      return response.text ?? "Couldn't generate insights.";
    } catch (e) {
      if (kDebugMode) {
        print('DEBUG: Gemini Error: $e');
      }
      return "Error connecting to AI: $e";
    }
  }
}
