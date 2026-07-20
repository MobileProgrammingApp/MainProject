import 'package:flutter/material.dart';
import '../../../core/app_theme.dart';
import '../../core/api_service.dart';

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
    if (mounted) {
      setState(() {
        if (data['status'] == 'success') {
          _houseName = data['house_name'] ?? '';
          _email = data['email'] ?? '';
        }
        _isLoading = false;
      });
    }
  }

  void _showChangePasswordSheet() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Şifre Değiştir', style: AppStyles.popupHeader),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mevcut Şifre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: AppStyles.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (newController.text != confirmController.text) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text("Yeni şifreler eşleşmiyor")),
                              );
                              return;
                            }
                            if (newController.text.length < 6) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text("Yeni şifre en az 6 karakter olmalı")),
                              );
                              return;
                            }

                            setSheetState(() => isSaving = true);
                            final result = await ApiService.changePassword(
                              currentController.text,
                              newController.text,
                            );
                            setSheetState(() => isSaving = false);

                            if (result['status'] == 'success') {
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Şifre güncellendi")),
                                );
                              }
                            } else if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(content: Text(result['message'] ?? "Şifre değiştirilemedi")),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kaydet'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil', style: AppStyles.appBarTitle),
        backgroundColor: AppStyles.backgroundColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🏠 Ev Bilgileri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.home_outlined, color: AppStyles.primaryColor),
                        title: const Text('Ev Adı'),
                        subtitle: Text(_houseName),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined, color: AppStyles.primaryColor),
                        title: const Text('E-posta'),
                        subtitle: Text(_email),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.lock_outline, color: AppStyles.primaryColor),
                  title: const Text('Şifre Değiştir', style: AppStyles.listTileTitle),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: _showChangePasswordSheet,
                ),
              ],
            ),
    );
  }
}
