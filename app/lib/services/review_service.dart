import '../config/api_config.dart';
import 'api_client.dart';

class Review {
  final int id;
  final int rating;
  final String? comment;
  final String userName;
  final DateTime? createdAt;
  Review({required this.id, required this.rating, this.comment, required this.userName, this.createdAt});

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: (j['id'] as num).toInt(),
        rating: (j['rating'] as num).toInt(),
        comment: j['comment']?.toString(),
        userName: j['user_name']?.toString() ?? 'Customer',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}

class ReviewService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Review>> forBusiness(int businessId) async {
    final data = await _api.get(ApiConfig.businessReviews(businessId));
    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  /// Returns the customer's existing review for this order, or null.
  Future<Review?> forOrder(int orderId) async {
    final data = await _api.get(ApiConfig.orderReview(orderId));
    if (data == null) return null;
    final m = Map<String, dynamic>.from(data as Map);
    m['user_name'] = 'You';
    return Review.fromJson(m);
  }

  Future<void> submit({required int orderId, required int rating, String? comment}) async {
    await _api.post(ApiConfig.reviews, body: {
      'order_id': orderId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }
}
