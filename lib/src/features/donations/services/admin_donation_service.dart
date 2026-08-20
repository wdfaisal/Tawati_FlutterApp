import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/providers.dart';
import '../models/donation.dart';

final adminDonationServiceProvider = Provider<AdminDonationService>((ref) {
  return AdminDonationService(ref.read(apiClientProvider));
});

class AdminDonationService {
  final ApiClient _api;
  AdminDonationService(this._api);

  Future<List<Map<String, dynamic>>> getAdminDonations({
    String? status,
    String? campaignId,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (campaignId != null && campaignId.isNotEmpty) params['campaign_id'] = campaignId;
    final response = await _api.get('/admin/donations', params: params);
    final list = response.data['data'] as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<List<Fund>> getAdminFunds() async {
    final response = await _api.get('/admin/funds', params: {'limit': 200});
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Fund.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Campaign>> getAdminCampaigns({String? fundId}) async {
    final params = <String, dynamic>{'limit': 200};
    if (fundId != null) params['fund_id'] = fundId;
    final response = await _api.get('/admin/campaigns', params: params);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Campaign.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> approveDonation(String id, {String? notes}) async {
    await _api.put('/admin/donations/$id/approve', data: {
      if (notes != null) 'review_notes': notes,
    });
  }

  Future<void> rejectDonation(String id, {String? notes}) async {
    await _api.put('/admin/donations/$id/reject', data: {
      'review_notes': notes,
    });
  }

  Future<Map<String, dynamic>> getDonationReports({
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();
    final response = await _api.get('/admin/reports/donations', params: params);
    return response.data['data'] as Map<String, dynamic>;
  }
}

class Fund {
  final String id;
  final String nameAr;
  final String? description;
  final String type;
  final bool isActive;
  final double balance;

  Fund({
    required this.id,
    required this.nameAr,
    this.description,
    required this.type,
    required this.isActive,
    required this.balance,
  });

  factory Fund.fromJson(Map<String, dynamic> json) => Fund(
        id: json['_id'] ?? json['id'] ?? '',
        nameAr: json['name_ar'] ?? '',
        description: json['description'],
        type: json['type'] ?? 'permanent',
        isActive: json['is_active'] ?? true,
        balance: (json['balance'] ?? 0).toDouble(),
      );
}
