import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  List<BookingModel> _bookings = [];
  BookingModel? _activeBooking;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;

  List<BookingModel> get bookings => _bookings;
  BookingModel? get activeBooking => _activeBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _currentPage < _totalPages;

  List<BookingModel> get activeBookings => _bookings
      .where((b) =>
          b.status != BookingStatus.completed &&
          b.status != BookingStatus.cancelled)
      .toList();

  Future<BookingModel> createBooking({
    required BookingType type,
    required String addressLine,
    String? landmark,
    required double latitude,
    required double longitude,
    required String wasteType,
    required String quantity,
    String? notes,
    DateTime? scheduledAt,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.instance.post('/bookings', data: {
        'type': type == BookingType.immediate ? 'IMMEDIATE' : 'SCHEDULED',
        'addressLine': addressLine,
        if (landmark != null) 'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'wasteType': wasteType,
        'quantity': quantity,
        if (notes != null) 'notes': notes,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
      });

      final booking =
          BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
      _activeBooking = booking;
      return booking;
    } catch (e) {
      _error = ApiClient.getErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookings({int page = 1}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.instance.get('/bookings?page=$page&limit=10');
      final data = response.data['data'] as Map<String, dynamic>;
      final List items = data['bookings'] as List;
      final pagination = data['pagination'] as Map<String, dynamic>;

      final parsed = items
          .map((j) => BookingModel.fromJson(j as Map<String, dynamic>))
          .toList();

      _bookings = page == 1 ? parsed : [..._bookings, ...parsed];
      _currentPage = pagination['page'] as int;
      _totalPages = pagination['pages'] as int;
      _total = pagination['total'] as int;
    } catch (e) {
      _error = ApiClient.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BookingModel> fetchBookingById(String id) async {
    final response = await ApiClient.instance.get('/bookings/$id');
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> cancelBooking(String id) async {
    await ApiClient.instance.patch('/bookings/$id/cancel');
    _bookings = _bookings
        .map((b) => b.id == id ? b.copyWith(status: BookingStatus.cancelled) : b)
        .toList();
    if (_activeBooking?.id == id) {
      _activeBooking =
          _activeBooking!.copyWith(status: BookingStatus.cancelled);
    }
    notifyListeners();
  }

  void setActiveBooking(BookingModel? booking) {
    _activeBooking = booking;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
