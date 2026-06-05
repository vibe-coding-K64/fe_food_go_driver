class WebSocketResponse<T> {
  final String type;
  final T? data;
  final String? message;
  final int timestamp;
  final String? event;
  final String? requestId;
  final String? orderId;
  final String? status;

  WebSocketResponse({
    required this.type,
    this.data,
    this.message,
    required this.timestamp,
    this.event,
    this.requestId,
    this.orderId,
    this.status,
  });

  factory WebSocketResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic rawData) dataParser,
  ) {
    return WebSocketResponse<T>(
      type: json['type']?.toString() ?? json['event']?.toString() ?? '',
      data: dataParser(json['data'] ?? json['orderId']),
      message: json['message']?.toString(),
      timestamp: _toInt(json['timestamp']) ?? 0,
      event: json['event']?.toString(),
      requestId: json['requestId']?.toString(),
      orderId: json['orderId']?.toString(),
      status: json['status']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
