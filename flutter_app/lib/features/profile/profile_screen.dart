import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
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
        subtitle: _isLoading ? null : _email,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const SectionHeader(title: "Ev hesabı"),
                GroupedCard(
                  dividerIndent: 72,
                  children: [
                    _infoTile(Icons.home_outlined, "Ev adı", _houseName),
                    _infoTile(Icons.email_outlined, "Ortak e-posta", _email),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: "Güvenlik"),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                    leading: _badge(Icons.lock_outline_rounded),
                    title: const Text('Şifre değiştir', style: AppStyles.listTileTitle),
                    subtitle: const Text("Diğer cihazlarda yeniden giriş gerekir"),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppStyles.mutedTextColor),
                    onTap: _showChangePasswordSheet,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _badge(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: AppStyles.primarySoft, borderRadius: BorderRadius.circular(12)),
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

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

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

  Widget _field(TextEditingController c, String hint, IconData icon, {bool last = false}) {
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
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Şifre değiştir', style: AppStyles.popupHeader)),
              IconButton(
                tooltip: _obscure ? "Şifreleri göster" : "Şifreleri gizle",
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(_current, 'Mevcut şifre', Icons.lock_outline_rounded),
          const SizedBox(height: 12),
          _field(_new, 'Yeni şifre (en az 8 karakter)', Icons.lock_reset_rounded),
          const SizedBox(height: 12),
          _field(_confirm, 'Yeni şifre (tekrar)', Icons.lock_reset_rounded, last: true),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
