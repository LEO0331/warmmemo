sealed class ViewState {
  const ViewState();
}

class IdleState extends ViewState {
  const IdleState();
}

class LoadingState extends ViewState {
  const LoadingState();
}

class SuccessState extends ViewState {
  const SuccessState({this.message});

  final String? message;
}

class ErrorState extends ViewState {
  const ErrorState(this.message);

  final String message;
}
