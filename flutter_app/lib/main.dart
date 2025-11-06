import 'package:flutter/material.dart';
import 'core/app_scaffold.dart'; // Ana iskeletimizi import et

void main() {
  // TODO: Firebase.initializeApp() gibi kurulumlar buraya gelecek
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evim Projesi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Temamızı yavaş yavaş buraya taşıyabiliriz
        // Şimdilik en temeli:
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFFBF6), // Krem arka plan
        fontFamily: 'Inter', // (Eğer 'pubspec.yaml'a eklerseniz)
      ),
      // Uygulamanın başladığı yer:
      home: const AppScaffold(),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:flutter_app/navbars/home_info_screen.dart';
// // core klasöründeki ana iskeletimizi import ediyoruz
// import 'core/app_scaffold.dart'; 

// void main() {
//   // TODO: Firebase kurulum kodları (initializeApp) buraya gelecek
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Ev Yönetim Uygulaması',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       debugShowCheckedModeBanner: false,
//       // BURASI ÇOK ÖNEMLİ:
//       // 'home:' kısmının 'AppScaffold()' olduğundan emin ol.
//       // Eğer burada 'MyHomePage()' gibi eski bir şey yazıyorsa,
//       // eski projenin çalışması normaldir.
//       //home: const X()
//       home: const HomeInfoScreen(), 
//     );
//   }
// }