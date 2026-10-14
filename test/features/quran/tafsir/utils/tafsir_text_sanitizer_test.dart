import 'package:azkar/features/quran/tafsir/utils/tafsir_text_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TafsirTextSanitizer.clean', () {
    test('strips paragraph and heading tags into paragraph breaks', () {
      const raw = '<h2>Title</h2><p>First paragraph.</p><p>Second.</p>';

      expect(
        TafsirTextSanitizer.clean(raw),
        'Title\n\nFirst paragraph.\n\nSecond.',
      );
    });

    test('converts line breaks and list items', () {
      const raw = 'Line one<br>Line two<li>Item</li>';

      expect(
        TafsirTextSanitizer.clean(raw),
        'Line one\nLine two\n• Item',
      );
    });

    test('removes inline formatting tags but keeps their text', () {
      const raw = '<p>Allah <strong>orders</strong> having <em>perfect</em> faith.</p>';

      expect(
        TafsirTextSanitizer.clean(raw),
        'Allah orders having perfect faith.',
      );
    });

    test('cleans malformed markup like the real API returns', () {
      // Mirrors observed data: a bare `h2>`, a stray `>`, a proper `</h2>`
      // and `<p>`, plus a cut-off `</` at the end.
      const raw = 'h2>Ordering Faith and encouraging> '
          'spending</h2><p>Allah the Exalted orders faith.</p>'
          "Allah's statement,/";

      final cleaned = TafsirTextSanitizer.clean(raw);

      expect(cleaned, isNot(contains('<')));
      expect(cleaned, isNot(contains('>')));
      expect(cleaned, isNot(contains('h2')));
      expect(cleaned, contains('Ordering Faith and encouraging'));
      expect(cleaned, contains('Allah the Exalted orders faith.'));
      expect(cleaned, contains("Allah's statement,"));
      expect(cleaned.endsWith('/'), isFalse);
    });

    test('decodes common HTML entities', () {
      // Note: `&lt;tag&gt;` decodes after tag stripping, so the resulting
      // brackets are treated as debris and removed as well.
      const raw = '<p>Fish &amp; chips &lt;tag&gt; &quot;quoted&quot; '
          'it&#39;s &#x27;fine&#x27; &nbsp;done &mdash; yes</p>';

      expect(
        TafsirTextSanitizer.clean(raw),
        'Fish & chips tag "quoted" it\'s \'fine\' done — yes',
      );
    });

    test('leaves plain text untouched', () {
      const raw = '  تفسير الجلالين نص عادي.  ';

      expect(TafsirTextSanitizer.clean(raw), 'تفسير الجلالين نص عادي.');
    });

    test('collapses excessive blank lines', () {
      const raw = '<p>One.</p><br><br><br><p>Two.</p>';

      expect(TafsirTextSanitizer.clean(raw), 'One.\n\nTwo.');
    });

    test('returns empty string for empty or tag-only input', () {
      expect(TafsirTextSanitizer.clean(''), isEmpty);
      expect(TafsirTextSanitizer.clean('<p><br></p>'), isEmpty);
    });

    test('does not treat normal words as tags', () {
      const raw = '<p>They brought them to the house.</p>';

      expect(
        TafsirTextSanitizer.clean(raw),
        'They brought them to the house.',
      );
    });
  });
}
