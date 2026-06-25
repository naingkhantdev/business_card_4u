import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/card/card_provider.dart';
import '../../network/image_url.dart';
import '../../data/vos/business_card_model.dart';
import '../widgets/app_toast.dart';
import '../widgets/loading_view.dart';
import '../widgets/theme_toggle_button.dart';

class FriendRequestsPage extends ConsumerStatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  ConsumerState<FriendRequestsPage> createState() =>
      _FriendRequestsPageState();
}

class _FriendRequestsPageState extends ConsumerState<FriendRequestsPage> {
  bool _isLoading = true;
  final Set<int> _acceptedIds = <int>{};
  final Set<int> _processingIds = <int>{};
  List<BusinessCardModel> _requests = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadRequests);
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    await ref.read(cardProvider.notifier).fetchFriendRequests();

    if (!mounted) return;

    final requests =
        ref.read(cardProvider).valueOrNull?.friendRequests ?? [];
    setState(() {
      _requests = List<BusinessCardModel>.from(requests);
      _acceptedIds.removeWhere((id) => !_requests.any((card) => card.id == id));
      _isLoading = false;
    });
  }

  Future<void> _acceptRequest(int cardId) async {
    setState(() => _processingIds.add(cardId));

    final result =
        await ref.read(cardProvider.notifier).acceptFriendRequest(cardId);

    if (!mounted) return;

    setState(() {
      _processingIds.remove(cardId);
      if (result.isSuccess) {
        _acceptedIds.add(cardId);
      }
    });

    if (result.isSuccess) {
      AppToast.show(context, 'Friend request accepted', type: AppToastType.success);
    } else {
      AppToast.show(context, result.message ?? 'Failed to accept request', type: AppToastType.error);
    }
  }

  Future<void> _rejectRequest(int cardId) async {
    setState(() => _processingIds.add(cardId));

    final result =
        await ref.read(cardProvider.notifier).rejectFriendRequest(cardId);

    if (!mounted) return;

    setState(() {
      _processingIds.remove(cardId);
      if (result.isSuccess) {
        _acceptedIds.remove(cardId);
        _requests.removeWhere((card) => card.id == cardId);
      }
    });

    if (result.isSuccess) {
      AppToast.show(context, 'Friend request rejected', type: AppToastType.destructiveSoft);
    } else {
      AppToast.show(context, result.message ?? 'Failed to reject request', type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF060B16) : const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: Text(
          'Friend Requests',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0B1220),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF060B16) : Colors.white,
        elevation: 0,
        surfaceTintColor: isDark ? const Color(0xFF060B16) : Colors.white,
        actions: [
          ThemeToggleButton(color: isDark ? Colors.white : Colors.black87),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingView(size: 90))
          : _requests.isEmpty
              ? Center(
                  child: Text(
                    'No pending friend requests',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFF98A7C2)
                          : Colors.black.withOpacity(.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final card = _requests[index];
                      return _FriendRequestCard(
                        card: card,
                        isAccepted: _acceptedIds.contains(card.id),
                        isBusy: _processingIds.contains(card.id),
                        onAccept: () => _acceptRequest(card.id),
                        onReject: () => _rejectRequest(card.id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  final BusinessCardModel card;
  final bool isAccepted;
  final bool isBusy;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _FriendRequestCard({
    required this.card,
    required this.isAccepted,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  String _relativeTime(DateTime? createdAt) {
    if (createdAt == null) return '';

    const myanmarOffset = Duration(hours: 6, minutes: 30);
    final now = DateTime.now().toUtc().add(myanmarOffset);
    final requestTime = createdAt.isUtc
        ? createdAt.add(myanmarOffset)
        : createdAt;
    final difference = now.difference(requestTime);

    if (difference.isNegative) {
      return 'Just now';
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    final days = difference.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = card.profileImage != null && card.profileImage!.isNotEmpty;
    final avatarUrl = hasImage ? ImageUrl.resolve(card.profileImage!) : null;
    final requestedAt = _relativeTime(card.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1426) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF1F2A44)
              : Colors.black.withOpacity(.06),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    isDark ? const Color(0xFF18243E) : const Color(0xFFE9EDF4),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0B1220),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.fullName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? const Color(0xFFEAF1FF) : const Color(0xFF0B1220),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.position.isEmpty ? 'Requested to add you' : card.position,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF98A7C2)
                            : Colors.black.withOpacity(.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (requestedAt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        requestedAt,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF7F90AF)
                              : Colors.black.withOpacity(.42),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isAccepted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13213A) : const Color(0xFFDCEBFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF294776) : const Color(0xFFBFDBFE),
                ),
              ),
              child: const Text(
                'You are now friends',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isBusy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF0B1220),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF2A3652)
                            : Colors.black.withOpacity(.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isBusy ? null : onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: isBusy
                        ? const LoadingView(size: 18)
                        : const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
