import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/providers/ai_provider.dart';
import 'package:walt/shared/text_ui.dart';

class AiInsight extends ConsumerWidget {
  const AiInsight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiInsightProvider);

    if (!aiState.isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withAlpha(50), Colors.blue.withAlpha(50)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.purple.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.purple),
              const SizedBox(width: 8),
              UiText(
                text: "AI Insight",
                type: UiTextType.titleMedium,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (aiState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () =>
                      ref.read(aiInsightProvider.notifier).fetchInsight(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (aiState.isLoading && aiState.insight == null)
            const UiText(text: "Thinking...", type: UiTextType.bodyMedium)
          else
            UiText(
              text: aiState.insight ?? "No insight available.",
              type: UiTextType.bodyMedium,
            ),
        ],
      ),
    );
  }
}
