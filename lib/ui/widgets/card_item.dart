import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/image_url.dart';
import '../../providers/card/card_provider.dart';
import '../../data/vos/business_card_model.dart';
import 'app_toast.dart';
import '../pages/card_detail_page.dart';
import '../theme/app_typography.dart';
import '../theme/wallet_tokens.dart';

/// A card in the list: who it is, then what you can reach them on.
///
/// The printed card photo deliberately does not appear here — it belongs to
/// the detail page, where it can be shown whole rather than cropped into a
/// thumbnail.
class CardItem extends ConsumerStatefulWidget {
  final BusinessCardModel card;
  const CardItem({super.key, required this.card});

  @override
  ConsumerState<CardItem> createState() => _CardItemState();
}

class _CardItemState extends ConsumerState<CardItem> {
  late bool _isFriend;
  late String _friendRequestStatus;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _isFriend = widget.card.isFriend;
    _friendRequestStatus = widget.card.friendRequestStatus ?? 'none';
  }

  @override
  void didUpdateWidget(covariant CardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id ||
        oldWidget.card.isFriend != widget.card.isFriend ||
        oldWidget.card.friendRequestStatus != widget.card.friendRequestStatus) {
      _isFriend = widget.card.isFriend;
      _friendRequestStatus = widget.card.friendRequestStatus ?? 'none';
      _isProcessing = false;
    }
  }

  void _showToast(String msg, {bool isError = false}) => AppToast.show(
        context, msg,
        type: isError ? AppToastType.error : AppToastType.success);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.card;
    final isSaved = card.cardType == 'saved_card';

    final canSendRequest = card.cardType == 'user_card' &&
        !_isFriend &&
        (_friendRequestStatus == 'none' || _friendRequestStatus == 'rejected');
    final isPending = _friendRequestStatus == 'pending' ||
        _friendRequestStatus == 'pending_sent';
    final isPendingReceived = _friendRequestStatus == 'pending_received';

    final company = card.company?.name;

    // Company, phone and email each get a line. This is what carried the
    // card's height before, and it is the information people scan a list for.
    final infoRows = <Widget>[
      if (company != null && company.isNotEmpty)
        _InfoRow(
            icon: Icons.business_rounded, text: company, isDark: isDark),
      if (card.phones.isNotEmpty)
        _InfoRow(
            icon: Icons.call_rounded,
            text: card.phones.first,
            isDark: isDark),
      if (card.emails.isNotEmpty)
        _InfoRow(
            icon: Icons.alternate_email_rounded,
            text: card.emails.first,
            isDark: isDark),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Wallet.radiusCard),
        color: Wallet.surfaceOf(isDark),
        border: Wallet.borderOf(isDark),
        boxShadow: Wallet.shadowOf(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Wallet.radiusCard),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CardDetailPage(card: card)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── who it belongs to ──────────────────────────
                Row(
                  children: [
                    // A person's card shows their portrait. A saved card has
                    // none — the printed photo lives on the detail page — so it
                    // takes a monogram, keeping every row the same shape.
                    _Avatar(card: card, isSaved: isSaved, isDark: isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.primary(TextStyle(
                              color: Wallet.inkOf(isDark),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            )),
                          ),
                          if (card.position.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            // The role labels the name above it rather than
                            // adding a second line of content. Tracked caps
                            // say so without spending another colour on it.
                            Text(
                              card.position.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.eyebrow(
                                color: Wallet.faintOf(isDark),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (isPendingReceived)
                      _RequestActions(
                        isProcessing: _isProcessing,
                        isDark: isDark,
                        onAccept: _accept,
                        onDecline: _decline,
                      )
                    else if (canSendRequest)
                      _AddButton(isDark: isDark, onTap: _sendRequest)
                    else
                      _StatusChip(
                        isFriend: _isFriend,
                        isPending: isPending,
                        isSaved: isSaved,
                        isDark: isDark,
                      ),
                  ],
                ),

                if (infoRows.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Divider(
                    height: Wallet.hairline,
                    thickness: Wallet.hairline,
                    color: Wallet.lineOf(isDark),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < infoRows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    infoRows[i],
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    final result =
        await ref.read(cardProvider.notifier).addFriend(widget.card.id);
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _friendRequestStatus = 'pending_sent');
      _showToast('Friend request sent');
    } else {
      _showToast(result.message ?? 'Failed to send request', isError: true);
    }
  }

  Future<void> _accept() async {
    setState(() => _isProcessing = true);
    final result = await ref
        .read(cardProvider.notifier)
        .acceptFriendRequest(widget.card.id);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (result.isSuccess) {
        _friendRequestStatus = 'accepted';
        _isFriend = true;
      }
    });
    _showToast(
      result.isSuccess
          ? 'Friend request accepted'
          : (result.message ?? 'Failed to accept request'),
      isError: !result.isSuccess,
    );
  }

  Future<void> _decline() async {
    setState(() => _isProcessing = true);
    final result = await ref
        .read(cardProvider.notifier)
        .rejectFriendRequest(widget.card.id);
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      if (result.isSuccess) {
        _friendRequestStatus = 'none';
        _isFriend = false;
      }
    });
    _showToast(
      result.isSuccess
          ? 'Friend request declined'
          : (result.message ?? 'Failed to decline request'),
      isError: !result.isSuccess,
    );
  }
}

class _Avatar extends StatelessWidget {
  final BusinessCardModel card;
  final bool isSaved;
  final bool isDark;

  const _Avatar({
    required this.card,
    required this.isSaved,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // A saved card carries no portrait of its own, so it never looks one up.
    final url = isSaved ? null : ImageUrl.resolve(card.profileImage);
    final letter =
        card.fullName.isNotEmpty ? card.fullName[0].toUpperCase() : '?';

    return Hero(
      tag: 'avatar_${card.id}_${card.fullName}',
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          // Square. The circular crop is the friendly-app convention; the
          // grid wants the portrait to align with the type block beside it,
          // and a disc gives it no edge to align to.
          borderRadius: BorderRadius.circular(Wallet.radiusTile),
          color: Wallet.tintOf(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: url != null
            ? Image(
                image: ResizeImage(NetworkImage(url),
                    width: 160, allowUpscaling: false),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _Monogram(letter: letter, isDark: isDark),
              )
            : _Monogram(letter: letter, isDark: isDark),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  final String letter;
  final bool isDark;

  const _Monogram({required this.letter, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        color: Wallet.tintOf(isDark),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: AppTypography.primary(TextStyle(
            color: Wallet.accentOf(isDark),
            fontSize: 19,
            fontWeight: FontWeight.w600,
          )),
        ),
      );
}

class _AddButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _AddButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(Wallet.radiusControl);
    return Material(
      color: Wallet.accentOf(isDark),
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            Icons.person_add_alt_1_rounded,
            size: 18,
            color: Wallet.onAccentOf(isDark),
          ),
        ),
      ),
    );
  }
}

class _RequestActions extends StatelessWidget {
  final bool isProcessing;
  final bool isDark;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestActions({
    required this.isProcessing,
    required this.isDark,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(Wallet.accentOf(isDark)),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundAction(
          icon: Icons.close_rounded,
          color: Wallet.danger,
          filled: false,
          isDark: isDark,
          onTap: onDecline,
        ),
        const SizedBox(width: 8),
        _RoundAction(
          icon: Icons.check_rounded,
          color: Wallet.success,
          filled: true,
          isDark: isDark,
          onTap: onAccept,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.filled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(Wallet.radiusControl);
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: shape,
      child: InkWell(
        onTap: onTap,
        borderRadius: shape,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: shape,
            // Decline is outlined, accept is filled: only the action being
            // recommended gets to spend a solid block of colour.
            border: filled
                ? null
                : Border.all(
                    color: color.withOpacity(.45),
                    width: Wallet.hairline,
                  ),
          ),
          child: Icon(icon, size: 17, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isFriend;
  final bool isPending;
  final bool isSaved;
  final bool isDark;

  const _StatusChip({
    required this.isFriend,
    required this.isPending,
    required this.isSaved,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final IconData ic;
    final String label;
    final Color tone;

    if (isPending) {
      tone = Wallet.pending;
      ic = Icons.schedule_rounded;
      label = 'Pending';
    } else if (isFriend) {
      tone = Wallet.success;
      ic = Icons.check_rounded;
      label = 'Friend';
    } else if (isSaved) {
      tone = Wallet.accentOf(isDark);
      ic = Icons.bookmark_rounded;
      label = 'Saved';
    } else {
      tone = Wallet.accentOf(isDark);
      ic = Icons.person_rounded;
      label = 'Profile';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Wallet.radiusTile),
        border: Border.all(
          color: tone.withOpacity(.35),
          width: Wallet.hairline,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 11, color: tone),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: AppTypography.eyebrow(
            color: tone,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }
}

/// One line of contact detail, with a tinted tile so the icons form a column
/// the eye can run down.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Wallet.radiusTile),
              color: Wallet.tintOf(isDark),
            ),
            child: Icon(icon, size: 13, color: Wallet.accentOf(isDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.secondary(TextStyle(
                color: Wallet.mutedOf(isDark),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              )),
            ),
          ),
        ],
      );
}
