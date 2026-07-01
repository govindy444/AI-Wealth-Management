import 'package:dartz/dartz.dart';

import '../error/failures.dart';


typedef Result<T> = Either<Failure, T>;

typedef FutureResult<T> = Future<Either<Failure, T>>;

Result<T> success<T>(T value) => Right(value);
Result<T> failure<T>(Failure f) => Left(f);
