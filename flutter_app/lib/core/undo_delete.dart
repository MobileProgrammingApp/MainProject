import 'package:flutter/material.dart';

/// Silmeyi geri alınabilir yapar: öğe ekrandan hemen kalkar (çağıran taraf
/// kaldırır), birkaç saniye "Geri al" seçeneği gösterilir; süre dolunca asıl
/// silme isteği ([commit]) sunucuya gönderilir.
///
/// Mesaj uygulamanın kök ScaffoldMessenger'ında gösterildiği için kullanıcı
/// başka sekmeye geçse de silme tamamlanır.
void deleteWithUndo({
  required BuildContext context,
  required String message,
  required VoidCallback onUndo,
  required Future<bool> Function() commit,
  VoidCallback? onCommitFailed,
}) {
  final messenger = ScaffoldMessenger.of(context);
  // Art arda silmede öncekinin mesajı kapanır ve o silme hemen kesinleşir
  messenger.hideCurrentSnackBar();
  messenger
      .showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        // Düğmeli SnackBar'lar varsayılan olarak kendiliğinden kapanmıyor;
        // kapanmazsa silme hiç kesinleşmez
        persist: false,
        action: SnackBarAction(label: "Geri al", onPressed: onUndo),
      ))
      .closed
      .then((reason) async {
    if (reason == SnackBarClosedReason.action) return;
    final ok = await commit();
    if (!ok) onCommitFailed?.call();
  });
}
