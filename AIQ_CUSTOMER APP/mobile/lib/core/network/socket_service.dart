import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef EventCallback = void Function(dynamic data);

class SocketService {
  static IO.Socket? _socket;
  static bool _connected = false;

  static bool get isConnected => _connected;

  static Future<void> connect() async {
    // Mock successful connection without hitting a backend
    _connected = true;
    print('🔌 Socket mocked as connected');
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _connected = false;
    print('🔌 Socket mocked as disconnected');
  }

  static void joinBookingRoom(String bookingId) {
    // No-op
  }

  static void leaveBookingRoom(String bookingId) {
    // No-op
  }

  static void on(String event, EventCallback callback) {
    // No-op
  }

  static void off(String event) {
    // No-op
  }

  static void emit(String event, dynamic data) {
    // No-op
  }
}
