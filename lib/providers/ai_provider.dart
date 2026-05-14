import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walt/data/models/walt_transaction.dart';
import 'package:walt/data/services/ai_service.dart';
import 'package:walt/providers/transaction_provider.dart';

class AiInsightState {
  final bool isVisible;
  final bool isLoading;
  final String? insight;

  AiInsightState({
    this.isVisible = false,
    this.isLoading = false,
    this.insight,
  });

  AiInsightState copyWith({bool? isVisible, bool? isLoading, String? insight}) {
    return AiInsightState(
      isVisible: isVisible ?? this.isVisible,
      isLoading: isLoading ?? this.isLoading,
      insight: insight ?? this.insight,
    );
  }
}

class AiInsightNotifier extends Notifier<AiInsightState> {
  @override
  AiInsightState build() {
    return AiInsightState();
  }

  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
    if (state.isVisible && state.insight == null) {
      fetchInsight();
    }
  }

  Future<void> fetchInsight() async {
    state = state.copyWith(isLoading: true);
    try {
      final transactionsAsync = ref.read(transactionProvider);
      final transactions = transactionsAsync.maybeWhen(
        data: (txs) => txs,
        orElse: () => <WaltTransaction>[],
      );
      final insight = await AiService.instance.getSpendingInsights(
        transactions,
      );
      if (ref.mounted) {
        state = state.copyWith(insight: insight, isLoading: false);
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          insight: "Error fetching insight: $e",
          isLoading: false,
        );
      }
    }
  }
}

final aiInsightProvider = NotifierProvider<AiInsightNotifier, AiInsightState>(
  () {
    return AiInsightNotifier();
  },
);
