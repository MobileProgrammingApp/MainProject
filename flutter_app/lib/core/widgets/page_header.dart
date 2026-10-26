import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

/// Bütün sayfaların üstündeki başlık bandı: logo mavisi zemin, alt köşeleri
/// yuvarlak; ikon rozeti, kalın başlık ve sayfanın durumunu özetleyen bir satır.
/// Scaffold.appBar olarak kullanılır; durum çubuğunun altına kadar uzanır.
class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double _barHeight = 84;

  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> actions;

  /// Bandın altına yerleşen sekmeler (ör. TabBar)
  final PreferredSizeWidget? bottom;

  /// Rozet yerine gösterilecek özel öğe (ör. paneldeki profil harfi)
  final Widget? leading;

  const PageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.actions = const [],
    this.bottom,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Mavi bant üzerinde durum çubuğu ikonları beyaz
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppStyles.primaryColor, Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: Column(
          children: [
            SizedBox(
              height: _barHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(canPop ? 4 : 20, 0, 12, 4),
                child: Row(
                  children: [
                    if (canPop) const BackButton(color: Colors.white),
                    leading ??
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white),
                        ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }
}

/// Sayfa içi bölüm başlığı: başlık + sayaç rozeti + isteğe bağlı işlem.
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? action;

  const SectionHeader({super.key, required this.title, this.count, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Text(title, style: AppStyles.sectionTitle),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppStyles.primarySoft, borderRadius: BorderRadius.circular(10)),
              child: Text("$count",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppStyles.primaryColor)),
            ),
          ],
          const Spacer(),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Boş liste durumu: renkli daire içinde ikon, başlık ve açıklama.
/// RefreshIndicator içinde çalışabilmesi için kaydırılabilir.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color softColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppStyles.primaryColor,
    this.softColor = AppStyles.primarySoft,
  });

  /// Liste sunucuya ulaşılamadığı için boşsa: "liste boş" demek kullanıcıya
  /// verilerinin silindiğini düşündürür.
  const EmptyState.offline({super.key})
      : icon = Icons.cloud_off_rounded,
        title = "Bağlantı kurulamadı",
        message = "İnternet bağlantını kontrol edip\naşağı çekerek yenile.",
        color = AppStyles.mutedTextColor,
        softColor = const Color(0xFFEDEFF3);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      children: [
        const SizedBox(height: 72),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: softColor, shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: color),
          ),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: AppStyles.listTileTitle),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: AppStyles.listTileSubtitle),
      ],
    );
  }
}

/// Bir bölümdeki satırları tek kartta, aralarında ince çizgiyle gösterir.
class GroupedCard extends StatelessWidget {
  final List<Widget> children;
  final double dividerIndent;

  const GroupedCard({super.key, required this.children, this.dividerIndent = 16});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: dividerIndent),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Listenin altında, satırlarla neler yapılabileceğini hatırlatan küçük not.
class ListHint extends StatelessWidget {
  final String text;

  const ListHint(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppStyles.listTileSubtitle.copyWith(fontSize: 12),
      ),
    );
  }
}
