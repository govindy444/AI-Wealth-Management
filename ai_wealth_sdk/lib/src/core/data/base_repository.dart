import '../error/exceptions.dart';
import '../error/failures.dart';
import '../logging/sdk_logger.dart';
import '../utils/result.dart';

mixin BaseRepository {
  SdkLogger get logger;


  Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return success(await action());
    } on AuthException catch (e) {
      logger.warning('Auth failure', data: e.message);
      return failure(AuthFailure(e.message, code: e.code));
    } on ServerException catch (e) {
      logger.warning('Server failure (${e.statusCode})', data: e.message);
      return failure(
        ServerFailure(e.message, code: e.code, statusCode: e.statusCode),
      );
    } on NetworkException catch (e) {
      logger.warning('Network failure', data: e.message);
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      logger.warning('Cache failure', data: e.message);
      return failure(CacheFailure(e.message));
    } catch (e, st) {
      logger.error('Unexpected repository error', error: e, stackTrace: st);
      return failure(UnexpectedFailure(e.toString()));
    }
  }
}
