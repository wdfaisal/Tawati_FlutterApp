import '../../../core/api_client.dart';
import '../models/donation.dart';

class DonationService {
  final ApiClient _api;

  DonationService(this._api);

  Future<List<Campaign>> getCampaigns({String? fundId}) async {
    final params = <String, dynamic>{};
    if (fundId != null) params['fund_id'] = fundId;
    final response = await _api.get('/campaigns', params: params);
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Campaign.fromJson(e)).toList();
  }

  Future<Campaign> getCampaignDetail(String id) async {
    final response = await _api.get('/campaigns/$id');
    return Campaign.fromJson(response.data['data']);
  }

  Future<Donation> createManualDonation({
    required String campaignId,
    required double amount,
    required String paymentMethodId,
    String? referenceNumber,
    DateTime? transferDate,
    String? receiptImage,
    bool isAnonymous = false,
  }) async {
    final response = await _api.post('/donations/manual', data: {
      'campaign_id': campaignId,
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'reference_number': referenceNumber,
      'transfer_date': transferDate?.toIso8601String(),
      'receipt_image': receiptImage,
      'is_anonymous': isAnonymous,
    });
    return Donation.fromJson(response.data['data']);
  }

  Future<String> uploadReceipt({
    required String filePath,
    String? filename,
  }) async {
    return _api.uploadImage(
      path: '/donations/upload-receipt',
      filePath: filePath,
      filename: filename,
    );
  }

  Future<List<Donation>> getMyDonations() async {
    final response = await _api.get('/donations/my');
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => Donation.fromJson(e)).toList();
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _api.get('/donations/payment-methods');
    final list = response.data['data'] as List<dynamic>;
    return list.map((e) => PaymentMethod.fromJson(e)).toList();
  }
}
