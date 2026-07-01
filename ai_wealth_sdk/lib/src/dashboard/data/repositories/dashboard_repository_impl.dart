import '../../../core/data/base_repository.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/logging/sdk_logger.dart';
import '../../../core/utils/result.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';
import '../datasources/dashboard_remote_datasource.dart';


class DashboardRepositoryImpl with BaseRepository implements DashboardRepository {
  DashboardRepositoryImpl({
    required DashboardRemoteDataSource remote,
    required DashboardLocalDataSource local,
    required this.logger,
  })  : _remote = remote,
        _local = local;

  final DashboardRemoteDataSource _remote;
  final DashboardLocalDataSource _local;

  @override
  final SdkLogger logger;

  @override
  FutureResult<DashboardSummary> getDashboard({bool forceRefresh = false}) =>
      guard(() async {
        try {
          final dto = await _remote.fetchDashboard();
          await _local.cache(dto);
          return dto.toEntity();
        } on NetworkException catch (e) {
          final cached = await _readCacheOrNull();
          if (cached != null) {
            logger.warning(
              'Dashboard offline — served cached snapshot.',
              data: e.message,
            );
            return cached;
          }
          rethrow; // mapped to NetworkFailure by guard.
        }
      });

  Future<DashboardSummary?> _readCacheOrNull() async {
    try {
      return (await _local.readCached())?.toEntity();
    } on CacheException {
      return null;
    }
  }
}
