import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/core/utils/context.dart';
import 'package:walt/providers/ai_provider.dart';
import 'package:walt/shared/text_ui.dart';

class AiInsight extends ConsumerWidget {
  const AiInsight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiInsightProvider);

    if (!aiState.isVisible) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      padding: EdgeInsets.all(context.w(16)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withAlpha(50), Colors.blue.withAlpha(50)],
        ),
        borderRadius: BorderRadius.circular(context.r(24)),
        border: Border.all(color: Colors.purple.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.purple,
                size: context.w(24),
              ),
              SizedBox(width: context.w(8)),
              UiText(
                text: "AI Insight",
                type: UiTextType.titleMedium,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (aiState.isLoading)
                SizedBox(
                  width: context.w(16),
                  height: context.w(16),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: Icon(Icons.refresh, size: context.w(20)),
                  onPressed: () =>
                      ref.read(aiInsightProvider.notifier).fetchInsight(),
                ),
            ],
          ),
          SizedBox(height: context.h(8)),
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
