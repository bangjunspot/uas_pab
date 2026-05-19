import 'package:flutter/services.dart';

class EmojiFilter {
  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1F6FF}\u{1F600}-\u{1F64F}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  static final TextInputFormatter denyEmoji = FilteringTextInputFormatter.deny(
    _emojiRegex,
  );
}
