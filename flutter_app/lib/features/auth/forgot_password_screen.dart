import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_theme.dart';
import '../../core/widgets/page_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  void _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta adresinizi girin")),
      );
      return;
    }

    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen geçerli bir e-posta adresi girin"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await ApiService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (result['status'] == 'success') {
      setState(() => _sent = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? "Bir hata oluştu")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader(
        icon: Icons.lock_reset_rounded,
        title: "Şifremi unuttum",
        subtitle: "Sıfırlama bağlantısı e-postana gelir",
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: _sent ? _buildSent() : _buildForm(),
      ),
    );
  }

  List<Widget> _buildForm() {
    return [
      Text(
        "Ev hesabına kayıtlı e-posta adresini gir, şifreni yenilemen için bir bağlantı gönderelim.",
        style: TextStyle(color: context.styles.textColor, fontSize: 15),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: "E-posta adresi", prefixIcon: Icon(Icons.email_outlined)),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: _isLoading ? null : _submit,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Text("Bağlantı gönder", style: TextStyle(fontSize: 16)),
      ),
    ];
  }

  List<Widget> _buildSent() {
    return [
      const SizedBox(height: 32),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: context.styles.successSoft, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, size: 44, color: AppStyles.successColor),
        ),
      ),
      const SizedBox(height: 20),
      Text("E-postanı kontrol et", textAlign: TextAlign.center, style: context.styles.listTileTitle),
      const SizedBox(height: 6),
      Text(
        "Adres kayıtlıysa şifre sıfırlama bağlantısını gönderdik. Birkaç dakika içinde gelmezse spam klasörüne de bak.",
        textAlign: TextAlign.center,
        style: context.styles.listTileSubtitle,
      ),
      const SizedBox(height: 28),
      FilledButton(
        onPressed: () => Navigator.pop(context),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        child: const Text("Giriş ekranına dön", style: TextStyle(fontSize: 16)),
      ),
    ];
  }
}
