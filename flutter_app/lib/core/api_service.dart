import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'session.dart';

// ==========================================
// 🛑🛑🛑 DİKKAT: BACKEND MERKEZİ (GİRİLMEZ) 🛑🛑🛑
//
// BU DOSYA TAMAMEN SUNUCU İLE İLETİŞİMİ SAĞLAR.
// İÇERİSİNDE TASARIM VEYA RENK KODU YOKTUR.
//
// Sunucuya giden TÜM istekler buradan geçmeli: oturum token'ı burada
// (Authorization başlığında) eklenir ve oturum düşünce (HTTP 401)
// kullanıcı otomatik olarak giriş ekranına yönlendirilir. Ekranlarda
// doğrudan http.get/post kullanmayın.
// ==========================================

class ApiService {
  static const String baseUrl = "https://homepal.swordarchitecture.com";
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, dynamic> _connectionError() => {
        "status": "error",
        "message": "Sunucuya ulaşılamadı, internet bağlantınızı kontrol edin.",
      };

  // ---------- Ortak istek yardımcıları ----------

  // Token URL'de değil başlıkta gider: sunucu loglarına ve geçmişe yazılmaz.
  static Future<Map<String, String>> _headers([Map<String, String>? extra]) async {
    final token = await Session.getToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  static http.Response _checkAuth(http.Response response) {
    if (response.statusCode == 401) {
      Session.expire();
    }
    return response;
  }

  static Future<http.Response> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse("$baseUrl/$path").replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers()).timeout(_timeout);
    return _checkAuth(response);
  }

  static Future<http.Response> _post(String path, Map<String, String> body) async {
    final response = await http
        .post(Uri.parse("$baseUrl/$path"), headers: await _headers(), body: body)
        .timeout(_timeout);
    return _checkAuth(response);
  }

  static Future<http.Response> _postJson(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse("$baseUrl/$path"),
          headers: await _headers({"Content-Type": "application/json"}),
          body: json.encode(body),
        )
        .timeout(_timeout);
    return _checkAuth(response);
  }

  static Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode != 200) return {};
    try {
      final data = json.decode(response.body);
      return data is Map<String, dynamic> ? data : {};
    } catch (_) {
      return {};
    }
  }

  static List<dynamic> _decodeList(http.Response response) {
    if (response.statusCode != 200) return [];
    try {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } catch (_) {
      return [];
    }
  }

  /// Sunucu {"status": "success"} döndürdü mü? (Hatalar da HTTP 200 ile gelir.)
  static bool _isSuccess(http.Response response) => _decodeMap(response)['status'] == 'success';

  // Ekrana mesaj gösteren çağrılar için: hata durumunda da "message" alanı dolu döner.
  static Future<Map<String, dynamic>> _postForMessage(String path, Map<String, String> body) async {
    try {
      final data = _decodeMap(await _post(path, body));
      return data.isNotEmpty ? data : {"status": "error", "message": "Sunucu hatası"};
    } catch (e) {
      debugPrint("$path hatası: $e");
      return _connectionError();
    }
  }

  static Future<bool> _postForSuccess(String path, Map<String, String> body) async {
    try {
      return _isSuccess(await _post(path, body));
    } catch (e) {
      debugPrint("$path hatası: $e");
      return false;
    }
  }

  static Future<List<dynamic>> _getList(String path, [Map<String, String>? query]) async {
    try {
      return _decodeList(await _get(path, query));
    } catch (e) {
      debugPrint("$path hatası: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> _getMap(String path, [Map<String, String>? query]) async {
    try {
      return _decodeMap(await _get(path, query));
    } catch (e) {
      debugPrint("$path hatası: $e");
      return {};
    }
  }

  // ---------- Hesap ----------

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _postForMessage("login.php", {"email": email, "password": password});
    if (data['status'] == 'success' && data['api_token'] is String) {
      await Session.saveToken(data['api_token']);
    }
    return data;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) =>
      _postForMessage("forgot_password.php", {"email": email});

  static Future<Map<String, dynamic>> register(String houseName, String email, String password) =>
      _postForMessage("register.php", {"house_name": houseName, "email": email, "password": password});

  static Future<Map<String, dynamic>> getProfile() => _getMap("get_profile.php");

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) =>
      _postForMessage("change_password.php", {
        "current_password": currentPassword,
        "new_password": newPassword,
      });

  /// 1.0.2 ve öncesinde evdeki tüm cihazlar tek bir token paylaşıyordu.
  /// Güncellemeden sonra ilk açılışta bu cihaz kendine özel bir token alır;
  /// böylece buradan çıkış yapmak eski sürümdeki aile üyelerini etkilemez.
  /// Başarısız olursa (ör. internet yok) bir sonraki açılışta tekrar denenir.
  static Future<void> renewSharedToken() async {
    if (!await Session.hasSharedToken()) return;
    try {
      final data = _decodeMap(await _post("renew_token.php", {}));
      if (data['status'] == 'success' && data['api_token'] is String) {
        await Session.saveToken(data['api_token']);
      }
    } catch (e) {
      debugPrint("Token yenilenemedi: $e");
    }
  }

  /// Çıkış: bu cihaza artık bildirim gelmesin, sunucudaki oturum kapansın ve
  /// cihazdaki veriler silinsin. İnternet yoksa da yerelde çıkış yapılır.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final memberId = prefs.getInt('saved_member_id');
      if (memberId != null) {
        await updateMemberToken(memberId, '');
      }
      // Ortak (eski sürümden kalma) token sunucuda iptal edilmez: aynı evdeki
      // diğer cihazlar hâlâ onu kullanıyor olabilir.
      if (!await Session.hasSharedToken()) {
        await _post("logout.php", {});
      }
    } catch (e) {
      debugPrint("Çıkış isteği gönderilemedi: $e");
    }
    await Session.clear();
  }

  // ---------- Görevler ----------
  // Not: houseId/creatorId gibi parametreler sunucuya gönderilmiyor; sunucu
  // evi token'dan buluyor. Ekranlar değişmesin diye imzalarda duruyorlar.

  static Future<List<dynamic>> getChores(int houseId) => _getList("get_chores.php");

  static Future<bool> addChore(int creatorId, int assignedToId, String taskName) =>
      _postForSuccess("add_chore.php", {
        "assigned_to_id": assignedToId.toString(),
        "task_name": taskName,
      });

  static Future<bool> completeChore(int id) => _postForSuccess("update_chore.php", {"id": id.toString()});

  static Future<bool> deleteChore(int id) => _postForSuccess("delete_chore.php", {"id": id.toString()});

  // ---------- Market listesi ----------

  static Future<List<dynamic>> getItems() => _getList("get_items.php");

  static Future<bool> addItem(String itemName, int? memberId) => _postForSuccess("add_item.php", {
        "item_name": itemName,
        if (memberId != null) "member_id": memberId.toString(),
      });

  static Future<bool> setItemBought(int id, bool bought) =>
      _postForSuccess("update_item.php", {"id": id.toString(), "is_bought": bought ? "1" : "0"});

  static Future<bool> deleteItem(int id) => _postForSuccess("delete_item.php", {"id": id.toString()});

  // ---------- Ev üyeleri ----------

  static Future<List<dynamic>> getFamilyMembers(int houseId) => _getList("get_members.php");

  static Future<bool> addFamilyMember(int houseId, String name) => _postForSuccess("add_member.php", {"name": name});

  static Future<bool> deleteFamilyMember(int id) => _postForSuccess("delete_member.php", {"id": id.toString()});

  /// Boş token: bu üyeye bildirim gönderilmesin.
  static Future<bool> updateMemberToken(int memberId, String fcmToken) =>
      _postForSuccess("update_member_token.php", {
        "member_id": memberId.toString(),
        "fcm_token": fcmToken,
      });

  // ---------- Ev bilgileri / envanter ----------

  static Future<Map<String, dynamic>> getHomeStats(int userId) => _getMap("get_home_stats.php");

  static Future<Map<String, dynamic>> getHomeDetails(int houseId) => _getMap("get_home_details.php");

  static Future<bool> addInfo(int houseId, String title, String value) =>
      _postForSuccess("add_info.php", {"title": title, "value": value});

  static Future<bool> deleteInfo(int id) => _postForSuccess("delete_info.php", {"id": id.toString()});

  static Future<bool> addInventory(int houseId, String itemName, String location) =>
      _postForSuccess("add_inventory.php", {"item_name": itemName, "location": location});

  static Future<bool> deleteInventory(int id) => _postForSuccess("delete_inventory.php", {"id": id.toString()});

  // ---------- Anket ----------

  static Future<Map<String, dynamic>> getActivePoll(int houseId, int memberId) =>
      _getMap("get_active_poll.php", {"member_id": memberId.toString()});

  static Future<bool> votePoll(int pollId, int optionId, int houseId, int memberId) =>
      _postForSuccess("vote_poll.php", {
        "poll_id": pollId.toString(),
        "option_id": optionId.toString(),
        "member_id": memberId.toString(),
      });

  static Future<bool> createPoll(int houseId, String question, List<String> options) async {
    try {
      return _isSuccess(await _postJson("create_poll.php", {"question": question, "options": options}));
    } catch (e) {
      debugPrint("create_poll.php hatası: $e");
      return false;
    }
  }
}

// ==========================================
// 🏁 BACKEND KODU SONU - TEŞEKKÜRLER
// ==========================================
