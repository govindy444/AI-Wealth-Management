import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/use_case.dart';
import '../../domain/usecases/fraud_usecases.dart';
import 'fraud_state.dart';

class FraudController extends StateNotifier<FraudState> {
  FraudController({
    required GetFraudAlertsUseCase getAlerts,
    required CheckMessageUseCase checkMessage,
  })  : _getAlerts = getAlerts,
        _checkMessage = checkMessage,
        super(const FraudState.initial());

  final GetFraudAlertsUseCase _getAlerts;
  final CheckMessageUseCase _checkMessage;

  Future<void> loadAlerts() async {
    state = state.copyWith(status: FraudStatus.loading, clearError: true);
    final result = await _getAlerts(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(
        status: FraudStatus.error,
        errorMessage: failure.message,
      ),
      (report) => state.copyWith(status: FraudStatus.ready, report: report),
    );
  }

  /// Scans [text] for scam/phishing risk and stores the result.
  Future<void> checkMessage(String text) async {
    if (text.trim().isEmpty || state.checking) return;
    state = state.copyWith(checking: true, clearMessageCheck: true, clearError: true);
    final result = await _checkMessage(text.trim());
    state = result.fold(
      (failure) =>
          state.copyWith(checking: false, errorMessage: failure.message),
      (check) => state.copyWith(checking: false, messageCheck: check),
    );
  }

  void clearMessageCheck() => state = state.copyWith(clearMessageCheck: true);

  Future<void> refresh() => loadAlerts();
}
