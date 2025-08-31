class ErrorUtils {
  static Exception toException(Object e) {
    if (e is Exception) return e;
    return Exception(e.toString());
  }
}


