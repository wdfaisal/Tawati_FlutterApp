import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'package:tawati_mobile/src/core/providers.dart';
import 'package:tawati_mobile/src/core/widgets/skeleton.dart';
import 'package:tawati_mobile/src/features/family/models/family.dart' as family_model;

class FamilyTreeScreen extends ConsumerStatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _head;
  List<dynamic> _children = [];
  family_model.FamilyMember? _selectedMember;
  final Set<String> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTree());
  }

  Future<void> _loadTree() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/families/my');
      final data = response.data['data'] as Map<String, dynamic>;
      final members = (data['members'] as List<dynamic>?) ?? [];
      final edges = (data['edges'] as List<dynamic>?) ?? [];
      final family = data['family'] as Map<String, dynamic>?;

      final rootUserId = family?['root_user_id'] as String?;
      final membersById = <String, Map<String, dynamic>>{};
      Map<String, dynamic>? rootUser;

      for (final m in members) {
        final mMap = m as Map<String, dynamic>;
        final id = mMap['_id'] as String? ?? '';
        membersById[id] = mMap;
        if (id == rootUserId) rootUser = mMap;
      }

      final childrenMap = <String, List<Map<String, dynamic>>>{};
      for (final e in edges) {
        final eMap = e as Map<String, dynamic>;
        final ancestorId = eMap['ancestor_id'] as String? ?? '';
        final descendantId = eMap['descendant_id'] as String? ?? '';
        if (ancestorId != descendantId) {
          childrenMap.putIfAbsent(ancestorId, () => []);
          final descendant = membersById[descendantId];
          if (descendant != null) {
            childrenMap[ancestorId]!.add(descendant);
          }
        }
      }

      final root = rootUser ?? (members.isNotEmpty ? members[0] as Map<String, dynamic> : null);

      setState(() {
        if (root != null) {
          _head = {
            'id': root['_id'],
            'name': root['full_name'] ?? root['full_name_ar'] ?? '',
            'children': _buildSubTree(root['_id'] as String?, childrenMap, membersById),
          };
        }
        _children = _head?['children'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = e.message ?? 'حدث خطأ في تحميل الشجرة';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _buildSubTree(
    String? parentId,
    Map<String, List<Map<String, dynamic>>> childrenMap,
    Map<String, Map<String, dynamic>> membersById,
  ) {
    if (parentId == null) return [];
    final directChildren = childrenMap[parentId] ?? [];
    return directChildren.map((child) {
      final childId = child['_id'] as String? ?? '';
      final grandChildren = _buildSubTree(childId, childrenMap, membersById);
      final gender = child['gender'] as String?;
      final maritalStatus = child['marital_status'] as String?;

      final node = <String, dynamic>{
        'id': childId,
        'name': child['full_name'] ?? child['full_name_ar'] ?? '',
        'gender': gender,
        'is_married': maritalStatus == 'married',
        'marital_status': maritalStatus,
        'children': grandChildren,
      };

      if (gender == 'male' && maritalStatus == 'married' && child['spouse_name'] != null) {
        node['spouse'] = {
          'id': '${childId}_spouse',
          'name': child['spouse_name'],
          'gender': 'female',
          'marital_status': 'married',
        };
      }
      return node;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        title: const Text(
          'شجرة العائلة',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                skeletonCard(),
                skeletonListItem(),
                skeletonListItem(),
                skeletonListItem(),
              ],
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadTree();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'IBMPlexSansArabic'),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildTreeContent(),
    );
  }

  Widget _buildTreeContent() {
    if (_head == null) {
      return const Center(
        child: Text(
          'لا يوجد أفراد',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontSize: 16,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeadNode(_head!),
              const SizedBox(height: 8),
              ..._children.map((child) => _buildChildNode(child, 1)),
            ],
          ),
        ),
        if (_selectedMember != null) _buildSelectedMemberCard(),
      ],
    );
  }

  Widget _buildHeadNode(Map<String, dynamic> head) {
    final name = head['name'] as String? ?? '';
    final id = head['id'] as String? ?? '';
    final isExpanded = _expandedNodes.contains(id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey(id),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedNodes.add(id);
            } else {
              _expandedNodes.remove(id);
            }
          });
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF0D9488),
          child: Text(
            _getInitials(name),
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'رب الأسرة',
          style: TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            color: const Color(0xFF0D9488),
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: const Color(0xFF0D9488),
        ),
        children: (_head?['children'] as List<dynamic>?)
                ?.map((c) => _buildChildNode(c, 1))
                .toList() ??
            [],
      ),
    );
  }

  Widget _buildChildNode(dynamic child, int level) {
    final name = child['name'] as String? ?? '';
    final id = child['id'] as String? ?? '';
    final gender = child['gender'] as String? ?? '';
    final isMarried = child['is_married'] as bool? ?? false;
    final isExpanded = _expandedNodes.contains(id);
    final childrenList = (child['children'] as List<dynamic>?) ?? [];
    final spouse = child['spouse'] as Map<String, dynamic>?;
    final relationship = gender == 'male' ? 'الابن' : 'الابنة';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        key: ValueKey(id),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            if (expanded) {
              _expandedNodes.add(id);
            } else {
              _expandedNodes.remove(id);
            }
          });
        },
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFCCFBF1),
          child: Text(
            _getInitials(name),
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              color: Color(0xFF0D9488),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'IBMPlexSansArabic',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              relationship,
              style: TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
            if (isMarried) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'متزوج',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    color: Color(0xFF22C55E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: (childrenList.isNotEmpty || spouse != null)
            ? Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF64748B),
              )
            : null,
        children: [
          if (spouse != null) _buildSpouseNode(spouse),
          ...childrenList.map((c) => _buildChildNode(c, level + 1)),
        ],
      ),
    );
  }

  Widget _buildSpouseNode(Map<String, dynamic> spouse) {
    final name = spouse['name'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(right: 48),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        color: const Color(0xFFF8FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: ListTile(
          onTap: () => _selectMember(spouse),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            child: Text(
              _getInitials(name),
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                color: Color(0xFFF59E0B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            'الزوجة',
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              color: const Color(0xFFF59E0B),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _selectMember(Map<String, dynamic> memberData) {
    setState(() {
      _selectedMember = family_model.FamilyMember(
        id: memberData['id'] as String? ?? '',
        fullNameAr: memberData['name'] as String? ?? memberData['full_name_ar'] as String? ?? '',
        role: memberData['role'] as String? ?? '',
        gender: memberData['gender'] as String?,
        maritalStatus: memberData['marital_status'] as String?,
        relation: memberData['relation'] as String?,
      );
    });
  }

  Widget _buildSelectedMemberCard() {
    final member = _selectedMember!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF0D9488),
                  child: Text(
                    _getInitials(member.fullNameAr),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullNameAr,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.role,
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedMember = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (member.relation != null && member.relation!.isNotEmpty)
              _buildInfoRow('صلة القرابة', member.relation!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBMPlexSansArabic',
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return parts.first[0];
  }
}