import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ==========================================
// 🛑🛑🛑 DİKKAT: BACKEND MERKEZİ (GİRİLMEZ) 🛑🛑🛑
//
// BU DOSYA TAMAMEN SUNUCU İLE İLETİŞİMİ SAĞLAR.
// İÇERİSİNDE TASARIM VEYA RENK KODU YOKTUR.
//
// ⚠️ UYARI: Buradaki tek bir harfi silmek uygulamanın
// bozulmasına ve veri çekememesine neden olur.
// Lütfen bu dosyayı kapat ve değişiklik yapma.
// ==========================================

class ApiService {

  static const String baseUrl = "https://homepal.swordarchitecture.com";

  // Giriş sonrası kaydedilen hesap token'ı; her istekte sunucuya
  // kimliğimizi kanıtlamak için gönderilir.
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_token');
  }

  static Future<bool> addItem(int userId, String itemName) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse("$baseUrl/add_item.php"),
      body: {
        "api_token": token ?? '',
        "user_id": userId.toString(),
        "item_name": itemName,
      },
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      return data['status'] == "success";
    }
    return false;
  }


  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login.php"),
        body: {
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"status": "error", "message": "Sunucu hatası"};
      }
    } catch (e) {
      return {"status": "error", "message": "Bağlantı hatası: $e"};
    }
  }

  static Future<Map<String, dynamic>> register(String houseName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register.php"),
        body: {
          "house_name": houseName,
          "email": email,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"status": "error", "message": "Sunucu hatası"};
      }
    } catch (e) {
      return {"status": "error", "message": "Bağlantı hatası: $e"};
    }
  }


  static Future<bool> addChore(int creatorId, int assignedToId, String taskName) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/add_chore.php"),
        body: {
          "api_token": token ?? '',
          "creator_id": creatorId.toString(),
          "assigned_to_id": assignedToId.toString(),
          "task_name": taskName,
          "house_id": creatorId.toString(), // Creator ID house ID olarak kullanılıyor

        },
      );
      // --- DEBUG ---
      print("Sunucu Cevabı: ${response.body}");
      // --------------------------------

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        return data['status'] == "success";
      }
      return false;
    } catch (e) {
      print("API Hatası (addChore): $e");
      return false;
    }
  }

  static Future<List<dynamic>> getChores(int houseId) async {
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_chores.php?house_id=$houseId&api_token=${token ?? ''}"));

      if (response.statusCode == 200) {
        // Gelen veriyi önce genel (dynamic) olarak alıyoruz
        final dynamic decodedData = json.decode(response.body);

        // KONTROL 1: Gelen veri bir Liste mi? (Başarılı durum)
        if (decodedData is List) {
          return decodedData;
        }
        // KONTROL 2: Gelen veri bir Map mi? (Hata durumu veya Wrapped List olabilir)
        else if (decodedData is Map) {
          print("Sunucu Mesajı (getChores): ${decodedData['message']}");

          // EĞER "data" veya "chores" anahtarı altında liste varsa onu döndür
          if (decodedData.containsKey('data') && decodedData['data'] is List) {
             return decodedData['data'];
          }
          if (decodedData.containsKey('chores') && decodedData['chores'] is List) {
             return decodedData['chores'];
          }

          return [];
        }
      }
    } catch (e) {
      print("API Hatası (getChores): $e");
    }
    // Herhangi bir sorun olursa boş liste döndür, uygulama çökmesin
    return [];
  }

  static Future<bool> addFamilyMember(int houseId, String name) async {
    try {
      final token = await _getToken();
      print("İstek gönderiliyor... URL: $baseUrl/add_member.php");
      print("Veriler: house_id=$houseId, name=$name");

      final response = await http.post(
        Uri.parse("$baseUrl/add_member.php"),
        body: {"api_token": token ?? '', "house_id": houseId.toString(), "name": name},
      );

      print("Sunucu Cevabı (Status Code): ${response.statusCode}");
      print("Sunucu Cevabı (Body): ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      } else {
        return false;
      }
    } catch (e) {
      print("Bağlantı Hatası: $e");
      return false;
    }
  }


  static Future<List<dynamic>> getFamilyMembers(int houseId) async {
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_members.php?house_id=$houseId&api_token=${token ?? ''}"));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);

        if (decodedData is List) {
          return decodedData;
        } else if (decodedData is Map) {
           if (decodedData.containsKey('data') && decodedData['data'] is List) {
             return decodedData['data'];
           }
           if (decodedData.containsKey('members') && decodedData['members'] is List) {
             return decodedData['members'];
           }
          // Liste değilse (muhtemelen hata mesajı içeren bir Map'tir), boş liste dön
          print("Sunucudan liste gelmedi: $decodedData");
          return [];
        }
      }
    } catch (e) {
        print("Bağlantı hatası: $e");
    }
    return [];
  }

  static Future<bool> deleteFamilyMember(int id) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/delete_member.php"),
        body: {"api_token": token ?? '', "id": id.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print("Silme hatası: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> getHomeStats(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_home_stats.php?user_id=$userId&api_token=${token ?? ''}"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("İstatistik hatası: $e");
    }
    return {}; // Hata olursa boş döndür
  }

  static Future<Map<String, dynamic>> getHomeDetails(int houseId) async {
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_home_details.php?house_id=$houseId&api_token=${token ?? ''}"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Detay çekme hatası: $e");
    }
    return {};
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_profile.php?api_token=${token ?? ''}"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Profil çekme hatası: $e");
    }
    return {};
  }

  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/change_password.php"),
        body: {
          "api_token": token ?? '',
          "current_password": currentPassword,
          "new_password": newPassword,
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Şifre değiştirme hatası: $e");
    }
    return {"status": "error", "message": "Bağlantı hatası"};
  }

  // Bilgi Ekle/Sil
  static Future<bool> addInfo(int houseId, String title, String value) async {
    final token = await _getToken();
    final response = await http.post(Uri.parse("$baseUrl/add_info.php"),
      body: {"api_token": token ?? '', "house_id": houseId.toString(), "title": title, "value": value});
    return response.statusCode == 200;
  }
  static Future<bool> deleteInfo(int id) async {
    final token = await _getToken();
    final response = await http.post(Uri.parse("$baseUrl/delete_info.php"), body: {"api_token": token ?? '', "id": id.toString()});
    return response.statusCode == 200;
  }

  // Envanter Ekle/Sil
  static Future<bool> addInventory(int houseId, String itemName, String location) async {
    final token = await _getToken();
    final response = await http.post(Uri.parse("$baseUrl/add_inventory.php"),
      body: {"api_token": token ?? '', "house_id": houseId.toString(), "item_name": itemName, "location": location});
    return response.statusCode == 200;
  }
  static Future<bool> deleteInventory(int id) async {
    final token = await _getToken();
    final response = await http.post(Uri.parse("$baseUrl/delete_inventory.php"), body: {"api_token": token ?? '', "id": id.toString()});
    return response.statusCode == 200;
  }

  static Future<bool> deleteChore(int id) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/delete_chore.php"),
        body: {"api_token": token ?? '', "id": id.toString()},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['status'] == 'success';
      }
      return false;
    } catch (e) {
      print("Silme hatası: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> getActivePoll(int houseId, int memberId) async { // memberId eklendi
    try {
      final token = await _getToken();
      final response = await http.get(Uri.parse("$baseUrl/get_active_poll.php?house_id=$houseId&member_id=$memberId&api_token=${token ?? ''}"));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Anket hata: $e");
    }
    return {};
  }

  static Future<bool> votePoll(int pollId, int optionId, int houseId, int memberId) async { // Parametreler arttı
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/vote_poll.php"),
        body: {
          "api_token": token ?? '',
          "poll_id": pollId.toString(),
          "option_id": optionId.toString(),
          "house_id": houseId.toString(),
          "member_id": memberId.toString()
        },
      );
      var data = json.decode(response.body);
      return data['status'] == "success";
    } catch (e) {
      return false;
    }
  }

  // Yeni Anket Oluştur (YENİ)
  static Future<bool> createPoll(int houseId, String question, List<String> options) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse("$baseUrl/create_poll.php"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "api_token": token ?? '',
          "house_id": houseId,
          "question": question,
          "options": options
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

// ==========================================
// 🏁 BACKEND KODU SONU - TEŞEKKÜRLER
// ==========================================
