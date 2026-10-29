// Sunucudaki anket verisi (get_polls.php). Evde aynı anda birden fazla anket
// olabilir; liste sunucudan sıralı gelir: açık anketler (en yakında kapanan
// başta), sonra son 24 saatte biten anketler (en son biten başta).

class PollOption {
  final int id;
  final String text;
  final int votes;

  const PollOption({required this.id, required this.text, required this.votes});
}

class Poll {
  final int id;
  final String question;
  final List<PollOption> options;
  final bool isOpen;
  final int minutesLeft;
  // Biten anket bu kadar dakika sonra kendiliğinden silinir
  final int resultMinutesLeft;
  final int? creatorId;
  final String? creatorName;
  final int? votedOptionId;

  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.isOpen,
    required this.minutesLeft,
    required this.resultMinutesLeft,
    required this.creatorId,
    required this.creatorName,
    required this.votedOptionId,
  });

  bool get hasVoted => votedOptionId != null;

  // Herkesin tek oyu olduğu için toplam oy, oy veren kişi sayısıdır
  int get totalVotes => options.fold(0, (sum, o) => sum + o.votes);

  int get topVotes => options.fold(0, (top, o) => o.votes > top ? o.votes : top);

  /// Açanı belli olan anketi sadece açan kişi bitirip silebilir; belli değilse
  /// herkes. Sunucu da aynı kuralı uygular (end_poll.php, delete_poll.php).
  bool canManage(int? memberId) => creatorId == null || creatorId == memberId;

  // Sayılar sunucudan metin olarak da gelebilir
  static int _int(Object? value) => int.tryParse('${value ?? ''}') ?? 0;

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: _int(json['poll_id']),
      question: '${json['question'] ?? ''}',
      options: [
        for (final o in (json['options'] as List? ?? const []))
          PollOption(id: _int(o['id']), text: '${o['option_text'] ?? ''}', votes: _int(o['vote_count'])),
      ],
      isOpen: json['is_open'] != false,
      minutesLeft: _int(json['minutes_left']),
      resultMinutesLeft: _int(json['result_minutes_left']),
      creatorId: json['created_by'] == null ? null : _int(json['created_by']),
      creatorName: json['created_by_name'] as String?,
      votedOptionId: json['voted_option_id'] == null ? null : _int(json['voted_option_id']),
    );
  }
}

/// get_polls.php cevabı. Sunucuya ulaşılamadıysa [PollsData.fromResponse] null döner;
/// o zaman ekranlar önceki listeyi gösterir ("anket yok" demez).
class PollsData {
  final List<Poll> polls;
  final int memberCount;

  const PollsData(this.polls, this.memberCount);

  static PollsData? fromResponse(Map<String, dynamic> data) {
    if (data['status'] != 'success' || data['polls'] is! List) return null;
    return PollsData(
      [for (final p in data['polls'] as List) Poll.fromJson(p as Map<String, dynamic>)],
      Poll._int(data['member_count']),
    );
  }

  /// Panelde öne çıkan anket: oyunu bekleyen açık anket, yoksa ilk açık anket,
  /// o da yoksa en son biten (listenin sırası sayesinde ilk eleman).
  Poll? featured(int? memberId) {
    if (polls.isEmpty) return null;
    return polls.firstWhere((p) => memberId != null && p.isOpen && !p.hasVoted, orElse: () => polls.first);
  }
}

/// "3 gün", "5 saat", "12 dakika"
String pollDuration(int minutes) {
  if (minutes >= 48 * 60) return "${minutes ~/ (24 * 60)} gün";
  if (minutes >= 60) return "${minutes ~/ 60} saat";
  return "$minutes dakika";
}
