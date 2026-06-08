import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warmmemo/core/utils/meaning_memory_copy.dart';

void main() {
  test('MeaningMemoryCopy uses Chinese copy for zh locales', () {
    final copy = MeaningMemoryCopy.forLocale(const Locale('zh', 'TW'));

    expect(copy.title, '意義與回憶');
    expect(copy.storyPrompt, '他們的人生說出什麼故事？');
    expect(copy.copyButton, '複製意義與回憶');
    expect(
      copy.labeledSections(
        lifeStory: '溫柔照顧家人',
        purpose: '',
        matteredTo: '家人',
        memories: '',
      ),
      ['他們的人生說出什麼故事？\n溫柔照顧家人', '他們的人生對誰很重要？\n家人'],
    );
  });

  test('MeaningMemoryCopy uses English copy for non-zh locales', () {
    final copy = MeaningMemoryCopy.forLanguageCode('en');

    expect(copy.title, 'Meaning & Memory');
    expect(copy.storyPrompt, 'What story did their life tell?');
    expect(copy.copyButton, 'Copy Meaning & Memory');
    expect(
      copy.labeledSections(
        lifeStory: 'A steady life',
        purpose: 'Family',
        matteredTo: '',
        memories: 'Sunday breakfast',
      ),
      [
        'What story did their life tell?\nA steady life',
        'What gave them purpose?\nFamily',
        'What memories should not be forgotten?\nSunday breakfast',
      ],
    );
  });
}
