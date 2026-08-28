class Failure {
  final String? message;
  Failure([this.message]);
}

class ServerFailure extends Failure {
  ServerFailure([super.message]);
}

class ConnectivityFailure extends Failure {
  ConnectivityFailure([super.message]);
}

class NotFoundFailure extends Failure {
  NotFoundFailure([super.message]);
}

class MaintenanceFailure extends Failure {
  MaintenanceFailure([super.message]);
}

class FormatFailure extends Failure {
  FormatFailure([super.message]);
}