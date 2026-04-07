import 'dart:math';
import 'package:flutter/material.dart';

class CommentaryManager {
  static final CommentaryManager _instance = CommentaryManager._internal();
  factory CommentaryManager() => _instance;
  CommentaryManager._internal();

  final Random _random = Random();

  // 1. Kombo Yapınca (Helal Olsun Dedirtenler)
  final List<String> _comboPhrases = [
    "Vay anam vay, ne patlattın be!",
    "Gözümle görmesem inanmazdım, helal!",
    "Şov yapma yeğenim, oyna geç.",
    "Mala anlatır gibi patlattın, tertemiz.",
    "Sen bu işin profesörü olmuşsun haberimiz yok.",
    "Gridin efendisi misin mübarek?",
    "Parmaklarına zeval gelmesin, ne biçim kombo o!",
    "Bak bak, nasıl da gidiyor satırlar tıkır tıkır.",
    "O bloğu oraya koyarken ne düşünüyordun?",
    "Yazılım mühendisliği okuyorsun bir de, yakıştı mı?",
    "Göz var nizam var, o boşluk oraya sığar mı?",
    "Ziyan ettin güzelim bloğu.",
    "Biraz mantık yeğenim, oyunun adı GridLogic!",
    "Senin koda gösterdiğin özen de mi böyle?",
    "Acele işe şeytan karışır, sakin ol.",
    "Senin üstüne GridLogic tanımam artık.",
  ];

  // 2. Kötü Hamle Yapınca (Fırça Kayanlar)
  final List<String> _badMovePhrases = [
    "O bloğu oraya koyarken ne düşünüyordun?",
    "Yazılım mühendisliği okuyorsun bir de, yakıştı mı?",
    "Göz var nizam var, o boşluk oraya sığar mı?",
    "Ziyan ettin güzelim bloğu.",
    "Biraz mantık yeğenim, oyunun adı GridLogic!",
    "Senin koda gösterdiğin özen de mi böyle?",
    "Acele işe şeytan karışır, sakin ol.",
    "Yatacak yerin kalmadı, kelimenin tam anlamıyla!",
    "Mevzu buraya kadarmış, eline sağlık.",
    "Oyun bitti ama ders çıkarmak bedava.",
    "Bir dahakine daha dikkatli, hadi koçum.",
  ];

  // 3. Oyun Bitince (Geçmiş Olsun Mesajları)
  final List<String> _gameOverPhrases = [
    "Dükkanı kapattık yeğenim, haydi geçmiş olsun.",
    "Bitti mi pilin? Çabuk pes ettin.",
    "Yatacak yerin kalmadı, kelimenin tam anlamıyla!",
    "Mevzu buraya kadarmış, eline sağlık.",
    "Oyun bitti ama ders çıkarmak bedava.",
    "Bir dahakine daha dikkatli, hadi koçum.",
  ];

  // 4. Yüksek Skor Kırınca (Gaz Verenler)
  final List<String> _highScorePhrases = [
    "Aslanım benim, rekoru paramparça ettin!",
    "Senin üstüne GridLogic tanımam artık.",
    "Maliye gelse bu skoru vergilendiremez, öyle büyük!",
    "Rekorun kokusu buraya kadar geldi.",
  ];

  // 5. Rastgele / Bekleme Anında
  final List<String> _waitingPhrases = [
    "Hadi bekletme milleti, sıradaki hamleyi yap.",
    "Düşünme o kadar, satranç oynamıyoruz.",
    "Grid seni bekler, sen neyi beklersin?",
  ];

  String getRandomPhrase(List<String> phrases) {
    return phrases[_random.nextInt(phrases.length)];
  }

  String getComboCommentary() {
    return getRandomPhrase(_comboPhrases);
  }

  String getBadMoveCommentary() {
    return getRandomPhrase(_badMovePhrases);
  }

  String getGameOverCommentary() {
    return getRandomPhrase(_gameOverPhrases);
  }

  String getHighScoreCommentary() {
    return getRandomPhrase(_highScorePhrases);
  }

  String getWaitingCommentary() {
    return getRandomPhrase(_waitingPhrases);
  }
}
