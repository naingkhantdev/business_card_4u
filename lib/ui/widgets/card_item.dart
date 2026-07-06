import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../network/image_url.dart';
import '../../providers/card/card_provider.dart';
import '../../data/vos/business_card_model.dart';
import 'app_toast.dart';
import '../pages/card_detail_page.dart';
import '../theme/app_theme.dart';

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
    final isSaved = widget.card.cardType == 'saved_card';
    final canSendRequest = widget.card.cardType == 'user_card' &&
        !_isFriend &&
        (_friendRequestStatus == 'none' || _friendRequestStatus == 'rejected');
    final isPending = _friendRequestStatus == 'pending' || _friendRequestStatus == 'pending_sent';
    final isPendingReceived = _friendRequestStatus == 'pending_received';

    final hasImage = widget.card.profileImage?.isNotEmpty == true;
    final avatarUrl =
        hasImage ? ImageUrl.resolve(widget.card.profileImage!) : null;
    final firstLetter = widget.card.fullName.isNotEmpty
        ? widget.card.fullName[0].toUpperCase()
        : '?';

    final Color accent =
        isSaved ? const Color(0xFF7C3AED) : const Color(0xFF2563EB);
    final Color accentSoft =
        isSaved ? const Color(0xFFEDE9FE) : const Color(0xFFEFF6FF);
    final Color accentEnd =
        isSaved ? const Color(0xFFA78BFA) : const Color(0xFF60A5FA);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border.all(
          color: isDark ? accent.withOpacity(.2) : accent.withOpacity(.1),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: accent.withOpacity(.1),
                  blurRadius: 22,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: accent.withOpacity(.07),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: accent.withOpacity(.05),
          highlightColor: accent.withOpacity(.03),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CardDetailPage(card: widget.card)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(colors: [accent, accentEnd]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Hero(
                          tag:
                              'avatar_${widget.card.id}_${widget.card.fullName}',
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: accent.withOpacity(.25), width: 2),
                            ),
                            child: ClipOval(
                              child: avatarUrl != null
                                  ? Image.network(avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _CardFallback(
                                            letter: firstLetter,
                                            accent: accent,
                                            soft: accentSoft,
                                            isDark: isDark,
                                          ))
                                  : _CardFallback(
                                      letter: firstLetter,
                                      accent: accent,
                                      soft: accentSoft,
                                      isDark: isDark,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.card.fullName,
                                style: AppTheme.withFontStack(TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  height: 1.2,
                                )),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.card.position.isEmpty
                                    ? 'Professional'
                                    : widget.card.position,
                                style: AppTheme.withFontStack(TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(.45)
                                      : const Color(0xFF64748B),
                                  fontSize: 12.5,
                                )),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isSaved && widget.card.user != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Created by: ${widget.card.user!.name}',
                                  style: AppTheme.withFontStack(TextStyle(
                                    color: isDark
                                        ? Colors.white.withOpacity(.35)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 11,
                                  )),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isPendingReceived)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isProcessing
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
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
                                            if (result.isSuccess) {
                                              _showToast('Friend request declined');
                                            } else {
                                              _showToast(result.message ?? 'Failed to decline request', isError: true);
                                            }
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.red.withOpacity(isDark ? .2 : .08),
                                              border: Border.all(color: Colors.red.withOpacity(.35)),
                                            ),
                                            child: const Icon(Icons.close_rounded, size: 15, color: Colors.red),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () async {
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
                                            if (result.isSuccess) {
                                              _showToast('Friend request accepted');
                                            } else {
                                              _showToast(result.message ?? 'Failed to accept request', isError: true);
                                            }
                                          },
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.green.withOpacity(isDark ? .2 : .08),
                                              border: Border.all(color: Colors.green.withOpacity(.35)),
                                            ),
                                            child: const Icon(Icons.check_rounded, size: 15, color: Colors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          )
                        else if (canSendRequest)
                          _CardAddBtn(
                            accent: accent,
                            isDark: isDark,
                            onTap: () async {
                              final result = await ref
                                  .read(cardProvider.notifier)
                                  .addFriend(widget.card.id);
                              if (!mounted) return;
                              if (result.isSuccess) {
                                setState(
                                    () => _friendRequestStatus = 'pending_sent');
                                _showToast('Friend request sent');
                              }
                            },
                          )
                        else
                          _CardPill(
                            isFriend: _isFriend,
                            isPending: isPending,
                            isSaved: isSaved,
                            accent: accent,
                            isDark: isDark,
                          ),
                      ],
                    ),
                    if (widget.card.company != null ||
                        widget.card.phones.isNotEmpty ||
                        widget.card.emails.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(.07)
                            : const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(height: 10),
                      if (widget.card.company != null)
                        _CardInfoRow(
                          icon: Icons.business_rounded,
                          text: widget.card.company!.name,
                          accent: accent,
                          isDark: isDark,
                        ),
                      if (widget.card.phones.isNotEmpty)
                        _CardInfoRow(
                          icon: Icons.phone_rounded,
                          text: widget.card.phones.first,
                          accent: accent,
                          isDark: isDark,
                        ),
                      if (widget.card.emails.isNotEmpty)
                        _CardInfoRow(
                          icon: Icons.alternate_email_rounded,
                          text: widget.card.emails.first,
                          accent: accent,
                          isDark: isDark,
                          last: true,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _CardFallback extends StatelessWidget {
  final String letter;
  final Color accent;
  final Color soft;
  final bool isDark;
  const _CardFallback(
      {required this.letter,
      required this.accent,
      required this.soft,
      required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        color: isDark ? accent.withOpacity(.15) : soft,
        child: Center(
          child: Text(letter,
              style: AppTheme.withFontStack(TextStyle(
                  color: isDark ? soft : accent,
                  fontSize: 20,
                  fontWeight: FontWeight.w800))),
        ),
      );
}

class _CardAddBtn extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;
  const _CardAddBtn(
      {required this.accent, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withOpacity(isDark ? .15 : .08),
            border: Border.all(color: accent.withOpacity(.35)),
          ),
          child:
              Icon(Icons.person_add_alt_1_rounded, size: 16, color: accent),
        ),
      );
}

class _CardPill extends StatelessWidget {
  final bool isFriend;
  final bool isPending;
  final bool isSaved;
  final Color accent;
  final bool isDark;
  const _CardPill(
      {required this.isFriend,
      required this.isPending,
      required this.isSaved,
      required this.accent,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final Color c;
    final IconData ic;
    final String label;

    if (isPending) {
      c = const Color(0xFFF59E0B);
      ic = Icons.schedule_rounded;
      label = 'Pending';
    } else if (isFriend) {
      c = const Color(0xFF10B981);
      ic = Icons.check_rounded;
      label = 'Friend';
    } else if (isSaved) {
      c = accent;
      ic = Icons.bookmark_rounded;
      label = 'Saved';
    } else {
      c = accent;
      ic = Icons.person_rounded;
      label = 'Profile';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: c.withOpacity(isDark ? .15 : .08),
        border: Border.all(color: c.withOpacity(.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 11, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: AppTheme.withFontStack(TextStyle(
                color: c, fontSize: 11, fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  final bool isDark;
  final bool last;
  const _CardInfoRow(
      {required this.icon,
      required this.text,
      required this.accent,
      required this.isDark,
      this.last = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 7),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: accent.withOpacity(isDark ? .12 : .07),
            ),
            child: Icon(icon, size: 14, color: accent.withOpacity(.8)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.withFontStack(TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(.6)
                    : const Color(0xFF475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              )),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      );
}
