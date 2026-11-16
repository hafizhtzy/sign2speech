/// Dart 3 sealed class for Supabase / Data Layer operational state & result modeling.
/// Adheres to Clean Architecture, Flutter GetX, and exhaustive pattern matching principles.
sealed class SupabaseResult<T> {
  const SupabaseResult();
}

final class SupabaseSuccess<T> extends SupabaseResult<T> {
  final T data;
  const SupabaseSuccess(this.data);
}

final class SupabaseFailure<T> extends SupabaseResult<T> {
  final String errorMessage;
  final Object? error;
  const SupabaseFailure(this.errorMessage, [this.error]);
}
