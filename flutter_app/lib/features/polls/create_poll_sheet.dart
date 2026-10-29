import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';

// Anket süresi seçenekleri (saat); sunucu en fazla 1 hafta kabul eder
const _pollDurations = {1: "1 saat", 24: "1 gün", 72: "3 gün", 168: "1 hafta"};

/// Yeni anket penceresi. Anket açılırsa [onCreated] çağrılır (listeyi yenilemek için).
/// Açık ya da biten diğer anketler yerinde kalır.
void showCreatePollSheet(BuildContext context, {required int? memberId, required Future<void> Function() onCreated}) {
  final questionCtrl = TextEditingController();
  final optionCtrls = [TextEditingController(), TextEditingController()];
  var durationHours = 24;
  final messenger = ScaffoldMessenger.of(context);

  Future<void> create(String question, List<String> options) async {
    final result = await ApiService.createPoll(question, options, durationHours: durationHours, memberId: memberId);
    if (result['status'] == 'success') {
      await onCreated();
      messenger.showSnackBar(const SnackBar(content: Text("Anket oluşturuldu!")));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(result['message'] ?? "Anket oluşturulurken hata oluştu.")));
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Yeni anket", style: ctx.styles.popupHeader),
              const SizedBox(height: 4),
              Text("Evdeki herkese bildirim gider; istediğin zaman bitirebilirsin.",
                  style: ctx.styles.listTileSubtitle),
              const SizedBox(height: 16),
              TextField(
                controller: questionCtrl,
                autofocus: true,
                maxLength: 255,
                decoration: const InputDecoration(hintText: "Soru (örn: Bu akşam ne yiyelim?)", counterText: ""),
              ),
              const SizedBox(height: 12),
              ...List.generate(optionCtrls.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: optionCtrls[index],
                    maxLength: 100,
                    decoration: InputDecoration(
                      hintText: "${index + 1}. seçenek",
                      counterText: "",
                      prefixIcon: const Icon(Icons.radio_button_unchecked, size: 18),
                    ),
                  ),
                );
              }),
              if (optionCtrls.length < 10)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setSheetState(() => optionCtrls.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: const Text("Seçenek ekle"),
                  ),
                ),
              const SizedBox(height: 10),
              Text("Ne kadar açık kalsın?", style: ctx.styles.listTileSubtitle),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: durationHours,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppStyles.radius),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.timer_outlined)),
                items: [
                  for (final entry in _pollDurations.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (value) => setSheetState(() => durationHours = value ?? durationHours),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () {
                  final q = questionCtrl.text.trim();
                  final opts = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                  if (q.isEmpty || opts.length < 2) {
                    messenger.showSnackBar(const SnackBar(content: Text("Soru ve en az 2 seçenek girin")));
                    return;
                  }
                  Navigator.pop(ctx);
                  create(q, opts);
                },
                child: const Text("Anketi başlat"),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
