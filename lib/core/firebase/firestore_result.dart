/// Dart 3 sealed class for Firestore operational state & result modeling.
/// Adheres to Clean Architecture, Flutter MVVM, and pattern matching principles.
sealed class FirestoreResult<T> {
  const FirestoreResult();
}

final class FirestoreSuccess<T> extends FirestoreResult<T> {
  final T data;
  const FirestoreSuccess(this.data);
}

final class FirestoreFailure<T> extends FirestoreResult<T> {
  final String errorMessage;
  final Object? error;
  const FirestoreFailure(this.errorMessage, [this.error]);
}
