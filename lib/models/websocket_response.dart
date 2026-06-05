class WebSocketResponse<T> {
  final String type;
  final T? data;
  final String? message;
  final int timestamp;

  WebSocketResponse({
    required this.type,
    this.data,
    this.message,
    required this.timestamp,
  });

  factory WebSocketResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic rawData) dataParser,
  ) {
    return WebSocketResponse<T>(
      type: json['type']?.toString() ?? '',
      data: dataParser(json['data']),
      message: json['message']?.toString(),
      timestamp: _toInt(json['timestamp']) ?? 0,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
