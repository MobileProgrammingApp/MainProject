import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import 'poll.dart';

/// Tek bir anketin kartı: oylama, sonuçlar ve (açan kişi için) bitirme/silme.
/// Panelde ve Anketler ekranında aynı kart kullanılır.
class PollCard extends StatefulWidget {
  final Poll poll;
  final int? memberId; // "Ben kimim?"; seçilmediyse null
  final int memberCount;

  /// Oy, bitirme ya da silmeden sonra listeyi yeniden çekmek için
  final Future<void> Function() onChanged;

  /// Profil seçilmeden oy verilmeye çalışılınca (Ayarlar'a götürür)
  final VoidCallback onNeedMember;

  const PollCard({
    super.key,
    required this.poll,
    required this.memberId,
    required this.memberCount,
    required this.onChanged,
    required this.onNeedMember,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  bool _busy = false; // istek sürerken art arda dokunulmasın

  Poll get poll => widget.poll;

  Future<void> _vote(int optionId) async {
    final memberId = widget.memberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oy vermek için lütfen Ayarlar'dan kim olduğunuzu seçin.")),
      );
      widget.onNeedMember();
      return;
    }

    // Anket açıkken oy değiştirilebilir; aynı seçeneğe tekrar dokunmak bir şey yapmaz
    if (!poll.isOpen || optionId == poll.votedOptionId || _busy) return;
    final changing = poll.hasVoted;

    final messenger = ScaffoldMessenger.of(context);
    _busy = true;
    final success = await ApiService.votePoll(poll.id, optionId, 0, memberId);
    // Başarısızsa anket bu arada bitmiş olabilir: güncel hâli gösterilsin
    await widget.onChanged();
    _busy = false;

    messenger.showSnackBar(SnackBar(
      content: Text(success ? (changing ? "Oyunuz değiştirildi" : "Oyunuz kaydedildi!") : "Oy kaydedilemedi."),
    ));
  }

  Future<void> _end() async {
    final confirmed = await _confirm(
      title: "Anket bitirilsin mi?",
      message: "Oylama kapanır, sonuç herkese görünür ve evdekilere bildirim gider.",
      action: "Bitir",
    );
    if (!confirmed || _busy || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    _busy = true;
    final success = await ApiService.endPoll(poll.id, widget.memberId ?? 0);
    await widget.onChanged();
    _busy = false;

    messenger.showSnackBar(SnackBar(content: Text(success ? "Anket bitirildi" : "Anket bitirilemedi.")));
  }

  Future<void> _delete() async {
    final confirmed = await _confirm(
      title: "Anket silinsin mi?",
      message: "\"${poll.question}\" anketi ve verilen oylar kalıcı olarak silinir.",
      action: "Sil",
      destructive: true,
    );
    if (!confirmed || _busy || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    _busy = true;
    final success = await ApiService.deletePoll(poll.id, widget.memberId ?? 0);
    await widget.onChanged();
    _busy = false;

    messenger.showSnackBar(SnackBar(content: Text(success ? "Anket silindi" : "Anket silinemedi.")));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Vazgeç")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive ? TextButton.styleFrom(foregroundColor: context.styles.deleteColor) : null,
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;
    final topVotes = poll.topVotes;
    // Sonuçlar oy verince veya anket bitince görünür
    final showResult = poll.hasVoted || !poll.isOpen;
    final canManage = poll.canManage(widget.memberId);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: context.styles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(poll.question,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.styles.textColor)),
              ),
              if (!poll.isOpen)
                _badge("Bitti", context.styles.mutedTextColor, context.styles.neutralSoft)
              else if (poll.hasVoted)
                _badge("Oy verildi", AppStyles.successColor, context.styles.successSoft),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (poll.creatorName != null) "${poll.creatorName} sordu",
              if (poll.isOpen)
                poll.minutesLeft > 0 ? "${pollDuration(poll.minutesLeft)} kaldı" : "kapanmak üzere"
              else ...[
                "Sona erdi",
                // Biten anket bir gün sonra kendiliğinden silinir
                if (poll.resultMinutesLeft > 0) "${pollDuration(poll.resultMinutesLeft)} sonra silinir",
              ],
            ].join(" • "),
            style: context.styles.listTileSubtitle,
          ),
          const SizedBox(height: 16),
          for (final option in poll.options)
            _PollOptionBar(
              text: option.text,
              percent: totalVotes == 0 ? 0.0 : option.votes / totalVotes,
              showResult: showResult,
              isMyChoice: poll.votedOptionId == option.id,
              isWinner: !poll.isOpen && topVotes > 0 && option.votes == topVotes,
              onTap: poll.isOpen ? () => _vote(option.id) : null,
            ),
          const SizedBox(height: 2),
          Text(_hint(totalVotes, canManage), style: context.styles.listTileSubtitle),
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (poll.isOpen)
                    OutlinedButton.icon(
                      onPressed: _end,
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text("Anketi bitir"),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: context.styles.deleteColor),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Sil"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // Seçeneklerin altındaki kısa açıklama: katılım ve ne yapılabileceği
  String _hint(int voters, bool canManage) {
    final turnout = voters == 0
        ? (poll.isOpen ? "Henüz oy veren yok" : "Kimse oy vermedi")
        : (widget.memberCount > 0 ? "$voters/${widget.memberCount} kişi oy verdi" : "$voters kişi oy verdi");
    if (!poll.isOpen) return turnout;
    return [
      poll.hasVoted ? turnout : "Oy vermek için bir seçeneğe dokunun • $turnout",
      if (poll.hasVoted) "Fikrin değişirse başka seçeneğe dokun",
      if (!canManage && poll.creatorName != null) "Anketi ${poll.creatorName} bitirebilir",
    ].join(" • ");
  }
}

class _PollOptionBar extends StatelessWidget {
  final String text;
  final double percent;
  final bool showResult;
  final bool isMyChoice;
  final bool isWinner; // biten ankette en çok oyu alan (berabere ise hepsi)
  final VoidCallback? onTap;

  const _PollOptionBar({
    required this.text,
    required this.percent,
    required this.showResult,
    required this.isMyChoice,
    required this.isWinner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = context.styles.primaryColor.withValues(alpha: isMyChoice ? 0.22 : 0.10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.styles.trackColor,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Oy oranı çubuğu (kartın genişliğine göre; yatay ekranda da doğru)
              if (showResult)
                Positioned.fill(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percent,
                    child: AnimatedContainer(duration: const Duration(milliseconds: 400), color: fill),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    if (isWinner) ...[
                      const Icon(Icons.emoji_events_rounded, size: 18, color: AppStyles.accentColor),
                      const SizedBox(width: 8),
                    ],
                    if (isMyChoice) ...[
                      Icon(Icons.check_circle_rounded, size: 18, color: context.styles.primaryColor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontWeight: isMyChoice || isWinner ? FontWeight.w700 : FontWeight.w500,
                          color: context.styles.textColor,
                        ),
                      ),
                    ),
                    if (showResult)
                      Text("%${(percent * 100).round()}",
                          style: TextStyle(fontWeight: FontWeight.w700, color: context.styles.textColor)),
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
