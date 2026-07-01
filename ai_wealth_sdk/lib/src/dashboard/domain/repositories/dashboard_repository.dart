import '../../../core/utils/result.dart';
import '../entities/dashboard_summary.dart';


abstract interface class DashboardRepository {

  FutureResult<DashboardSummary> getDashboard({bool forceRefresh = false});
}
