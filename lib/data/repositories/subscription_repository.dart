import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/hive_service.dart';
import '../models/subscription_model.dart';

/// Riverpod provider for [SubscriptionRepository].
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepositoryImpl();
});

/// Abstract repository interface for Subscriptions.
abstract class SubscriptionRepository {
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<void> saveSubscription(SubscriptionModel subscription);
  Future<void> deleteSubscription(String id);
}

/// Hive implementation of [SubscriptionRepository].
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final box = HiveService.subscriptionsBox;
    final List<SubscriptionModel> subscriptions = [];

    for (var key in box.keys) {
      final item = box.get(key);
      if (item is Map) {
        try {
          final map = Map<String, dynamic>.from(item);
          subscriptions.add(SubscriptionModel.fromMap(map));
        } catch (e) {
          // ignore corrupted items
        }
      }
    }

    // Sort by next payment date ascending by default
    subscriptions.sort(
      (a, b) => a.nextPaymentDate.compareTo(b.nextPaymentDate),
    );
    return subscriptions;
  }

  @override
  Future<void> saveSubscription(SubscriptionModel subscription) async {
    final box = HiveService.subscriptionsBox;
    await box.put(subscription.id, subscription.toMap());
  }

  @override
  Future<void> deleteSubscription(String id) async {
    final box = HiveService.subscriptionsBox;
    await box.delete(id);
  }
}
