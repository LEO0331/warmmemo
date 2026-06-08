import 'package:flutter/widgets.dart';

class MeaningMemoryCopy {
  const MeaningMemoryCopy._(this.isChinese);

  factory MeaningMemoryCopy.forLocale(Locale locale) {
    return MeaningMemoryCopy._(
      locale.languageCode.toLowerCase().startsWith('zh'),
    );
  }

  factory MeaningMemoryCopy.forLanguageCode(String languageCode) {
    return MeaningMemoryCopy._(languageCode.toLowerCase().startsWith('zh'));
  }

  final bool isChinese;

  String get title => isChinese ? '意義與回憶' : 'Meaning & Memory';

  String get introPrimary => isChinese
      ? '有意義的一生，不只是事件清單。它也是關係、價值、選擇、愛、工作、美好，以及苦難交織成的故事。'
      : 'A meaningful life is more than a list of events. It is a story of relationships, values, choices, love, work, beauty, and even suffering.';

  String get introSecondary => isChinese
      ? '用這個空間記錄這個人生命中真正有意義的部分。'
      : 'Use this space to record what made this person\'s life meaningful.';

  String get helper => isChinese
      ? '不用寫得完美。幾段真誠的回憶就已經足夠。'
      : 'There is no need to write perfectly. A few honest memories are enough.';

  String get publicDisclosure => isChinese
      ? '公開紀念頁發布後，這些內容會一併顯示；若只想自己留存，可以先不發布。'
      : 'After publishing the public memorial page, this content will be shown there too. If it is only for private keeping, leave the page unpublished.';

  String get copyButton => isChinese ? '複製意義與回憶' : 'Copy Meaning & Memory';

  String get copiedMessage =>
      isChinese ? '已複製意義與回憶。' : 'Meaning & Memory copied.';

  String get noContentMessage =>
      isChinese ? '目前還沒有可複製的內容。' : 'There is no content to copy yet.';

  String get storyPrompt =>
      isChinese ? '他們的人生說出什麼故事？' : 'What story did their life tell?';

  String get purposePrompt =>
      isChinese ? '什麼給了他們方向與目的？' : 'What gave them purpose?';

  String get matteredToPrompt =>
      isChinese ? '他們的人生對誰很重要？' : 'Who did their life matter to?';

  String get memoriesPrompt =>
      isChinese ? '哪些回憶不該被忘記？' : 'What memories should not be forgotten?';

  String get storyHelper => isChinese
      ? '寫下一段重要的回憶、價值或時刻。'
      : 'Write a memory, value, or moment that feels important.';

  String get purposeHelper =>
      isChinese ? '可以之後再慢慢補充。' : 'You can return to this later.';

  String get matteredToHelper =>
      isChinese ? '短短幾句也可以。' : 'Write freely. Short notes are enough.';

  String get memoriesHelper =>
      isChinese ? '小細節往往最能留下溫度。' : 'Small details often carry the most warmth.';

  String get lifeStoryLabel => isChinese ? '生命故事' : 'Life story';

  String get purposeLabel => isChinese ? '方向與目的' : 'Purpose';

  String get matteredToLabel => isChinese ? '重要的人' : 'Mattered to';

  String get memoriesLabel => isChinese ? '不想忘記的回憶' : 'Memories';

  List<String> labeledSections({
    required String lifeStory,
    required String purpose,
    required String matteredTo,
    required String memories,
  }) {
    return [
      if (lifeStory.trim().isNotEmpty) '$storyPrompt\n${lifeStory.trim()}',
      if (purpose.trim().isNotEmpty) '$purposePrompt\n${purpose.trim()}',
      if (matteredTo.trim().isNotEmpty)
        '$matteredToPrompt\n${matteredTo.trim()}',
      if (memories.trim().isNotEmpty) '$memoriesPrompt\n${memories.trim()}',
    ];
  }
}
