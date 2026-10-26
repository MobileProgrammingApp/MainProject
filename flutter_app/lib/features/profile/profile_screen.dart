import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _loaded = false; // sunucudan bilgiler geldi mi (internet yoksa gelmez)
  String _houseName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ApiService.getProfile();
    if (!mounted) return;
    setState(() {
      if (data['status'] == 'success') {
        _houseName = data['house_name'] ?? '';
        _email = data['email'] ?? '';
        _loaded = true;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PageHeader(
        icon: Icons.person_rounded,
        title: "Profil",
        subtitle: _isLoading ? null : (_loaded ? _email : "Bağlantı yok"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  const SectionHeader(title: "Ev hesabı"),
                  if (_loaded)
                    GroupedCard(
                      dividerIndent: 72,
                      children: [
                        _infoTile(Icons.home_outlined, "Ev adı", _houseName),
                        _infoTile(
                          Icons.email_outlined,
                          "Ortak e-posta",
                          _email,
                        ),
                      ],
                    )
                  else
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEFF3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            color: AppStyles.mutedTextColor,
                            size: 22,
                          ),
                        ),
                        title: const Text(
                          "Hesap bilgileri alınamadı",
                          style: AppStyles.listTileTitle,
                        ),
                        subtitle: const Text(
                          "İnternet bağlantını kontrol edip aşağı çekerek yenile.",
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: "Güvenlik"),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                      leading: _badge(Icons.lock_outline_rounded),
                      title: const Text(
                        'Şifre değiştir',
                        style: AppStyles.listTileTitle,
                      ),
                      subtitle: const Text(
                        "Diğer cihazlarda yeniden giriş gerekir",
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppStyles.mutedTextColor,
                      ),
                      onTap: _showChangePasswordSheet,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE6E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_forever_outlined,
                          color: AppStyles.deleteColor,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Hesabı sil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppStyles.deleteColor,
                        ),
                      ),
                      subtitle: const Text(
                        "Ev hesabı ve tüm veriler kalıcı olarak silinir",
                      ),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _DeleteAccountSheet(
                          houseName: _loaded ? _houseName : "",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _badge(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppStyles.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppStyles.primaryColor, size: 22),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      leading: _badge(icon),
      title: Text(label, style: AppStyles.listTileSubtitle),
      subtitle: Text(value, style: AppStyles.listTileTitle),
    );
  }

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (_current.text.isEmpty || _new.text.isEmpty) {
      _message("Lütfen tüm alanları doldurun");
      return;
    }
    if (_new.text != _confirm.text) {
      _message("Yeni şifreler eşleşmiyor");
      return;
    }
    if (_new.text.length < 8) {
      _message("Yeni şifre en az 8 karakter olmalı");
      return;
    }

    setState(() => _saving = true);
    final result = await ApiService.changePassword(_current.text, _new.text);
    if (!mounted) return;
    setState(() => _saving = false);

    if (result['status'] == 'success') {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Şifre güncellendi")),
      );
    } else {
      _message(result['message'] ?? "Şifre değiştirilemedi");
    }
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool last = false,
  }) {
    return TextField(
      controller: c,
      obscureText: _obscure,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onSubmitted: last ? (_) => _submit() : null,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Şifre değiştir', style: AppStyles.popupHeader),
              ),
              IconButton(
                tooltip: _obscure ? "Şifreleri göster" : "Şifreleri gizle",
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(_current, 'Mevcut şifre', Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          _field(
            _new,
            'Yeni şifre (en az 8 karakter)',
            Icons.lock_reset_rounded,
          ),
          const SizedBox(height: 12),
          _field(
            _confirm,
            'Yeni şifre (tekrar)',
            Icons.lock_reset_rounded,
            last: true,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

/// Hesap silme onayı: ne silineceğini açıkça söyler, şifre ister.
class _DeleteAccountSheet extends StatefulWidget {
  final String houseName;
  const _DeleteAccountSheet({required this.houseName});

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  final _password = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Şifreni gir")));
      return;
    }
    setState(() => _deleting = true);
    final result = await ApiService.deleteAccount(_password.text);
    if (!mounted) return;

    if (result['status'] == 'success') {
      // Oturum ApiService.deleteAccount içinde temizlendi; giriş ekranına dön
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Hesabın silindi")),
      );
    } else {
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Hesap silinemedi")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Hesabı sil', style: AppStyles.popupHeader),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE6E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${widget.houseName.isEmpty ? "Bu ev hesabı" : "\"${widget.houseName}\" ev hesabı"}; ev üyeleri, görevler, market listesi, ev bilgileri ve "
              "anketlerle birlikte kalıcı olarak silinir. Bu hesabı kullanan bütün aile üyeleri "
              "oturumdan çıkar. Bu işlem geri alınamaz.",
              style: const TextStyle(color: AppStyles.textColor),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "Onaylamak için şifren",
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            onSubmitted: (_) => _delete(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _deleting ? null : _delete,
            style: FilledButton.styleFrom(
              backgroundColor: AppStyles.deleteColor,
            ),
            child: _deleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Hesabı kalıcı olarak sil"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç"),
          ),
        ],
      ),
    );
  }
}
