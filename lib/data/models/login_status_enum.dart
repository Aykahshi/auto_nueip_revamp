enum LoginStatus { initial, loading, success, error }

extension LoginStatusX on LoginStatus {
  bool get isLoading => this == LoginStatus.loading;
  bool get isSuccess => this == LoginStatus.success;
  bool get isError => this == LoginStatus.error;
}
