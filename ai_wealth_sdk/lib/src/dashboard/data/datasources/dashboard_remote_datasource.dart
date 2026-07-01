import '../../../core/network/api_client.dart';
import '../models/dashboard_dto.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardDto> fetchDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<DashboardDto> fetchDashboard() async {
    final res = await _client.get('/banking/dashboard');
    return DashboardDto.fromJson(res.asMap);
  }
}
