import '../../models/map_models.dart';

const northKoreaRegionCode = 'KP';

class NorthKoreaVisitGate {
  static const requiredConfirmations = 3;

  int _confirmedCount = 0;

  int get confirmedCount => _confirmedCount;
  bool get isUnlocked => _confirmedCount >= requiredConfirmations;

  bool requiresConfirmation(MapMode mode, String regionCode) =>
      mode == MapMode.world &&
      regionCode == northKoreaRegionCode &&
      !isUnlocked;

  bool registerDecision(bool confirmed) {
    if (!confirmed) return false;
    if (!isUnlocked) _confirmedCount += 1;
    return isUnlocked;
  }
}

String northKoreaConfirmationMessage(int attempt) => switch (attempt) {
  1 => '진짜 방문하셨다고요 ?????',
  2 => '정말 북한에 다녀오셨다고요 ?????',
  _ => '마지막 확인이에요. 진짜 방문하신 게 맞나요 ?????',
};
