import 'package:equatable/equatable.dart';

import 'result.dart';


abstract class UseCase<Type, Params> {
  FutureResult<Type> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}
