import 'package:equatable/equatable.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/use_case.dart';
import '../entities/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardParams extends Equatable {
  const GetDashboardParams({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class GetDashboardUseCase implements UseCase<DashboardSummary, GetDashboardParams> {
  GetDashboardUseCase(this._repository);
  final DashboardRepository _repository;

  @override
  FutureResult<DashboardSummary> call(GetDashboardParams params) =>
      _repository.getDashboard(forceRefresh: params.forceRefresh);
}
