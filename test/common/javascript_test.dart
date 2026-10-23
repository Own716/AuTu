import 'dart:convert';

import 'package:outo/common/exception.dart';
import 'package:outo/common/javascript.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<({String script, String config})> calls;
  final engine = scriptEvaluator;

  setUp(() {
    calls = [];
  });

  tearDown(() {
    scriptEvaluator = engine;
  });

  void answerWith(String result) {
    scriptEvaluator = ({required String script, required String config}) async {
      calls.add((script: script, config: config));
      return result;
    };
  }

  test(
    'passes the profile as JSON and returns what the script produced',
    () async {
      answerWith(json.encode({'mode': 'global'}));

      final result = await handleEvaluate('main', {'mode': 'rule'});

      expect(result, {'mode': 'global'});
      expect(json.decode(calls.single.config)['mode'], 'rule');
      expect(calls.single.script, 'main');
    },
  );

  test('gives the script an empty proxy-providers map to work with', () async {
    answerWith(json.encode({'mode': 'rule'}));

    await handleEvaluate('main', {'mode': 'rule'});

    expect(json.decode(calls.single.config)['proxy-providers'], isEmpty);
  });

  test('reports what the engine threw', () async {
    scriptEvaluator = ({required String script, required String config}) async {
      throw Exception('ReferenceError: proxies is not defined');
    };

    await expectLater(
      handleEvaluate('main', {}),
      throwsA(
        isA<MessageException>().having(
          (error) => error.message,
          'message',
          contains('ReferenceError'),
        ),
      ),
    );
  });

  test('rejects a result that is not a configuration object', () async {
    answerWith(json.encode([1, 2, 3]));

    await expectLater(
      handleEvaluate('main', {}),
      throwsA(isA<MessageException>()),
    );
  });

  group('scriptWithRuleOptions', () {
    test('hands back the script untouched when nothing is switched', () {
      const script = 'function main(config) { return config }\n';

      expect(scriptWithRuleOptions(script, const {}), same(script));
    });

    test('assigns the switches after the script, so main reads them', () {
      const script = 'const ruleOptionsEnable = { Google: true };';

      final result = scriptWithRuleOptions(script, const {'Google': false});

      expect(result, startsWith(script));
      expect(
        result,
        contains('Object.assign(ruleOptionsEnable, {"Google":false})'),
      );
      expect(
        result.substring(script.length).startsWith('\n;'),
        isTrue,
        reason: 'the assignment has to survive a trailing line comment',
      );
    });

    test('escapes a name as JSON rather than as JavaScript', () {
      final result = scriptWithRuleOptions(
        'function main(config) { return config }',
        const {'a"b': true},
      );

      expect(result, contains(r'{"a\"b":true}'));
    });

    test('applies the switches through the engine', () async {
      answerWith(json.encode({'mode': 'rule'}));

      await handleEvaluate('main', {}, customOptions: const {'Google': false});

      expect(calls.single.script, contains('Object.assign'));
      expect(calls.single.script, contains('"Google":false'));
    });
  });

  group('extractRuleOptions', () {
    String envelope({
      Map<String, Object?> options = const {},
      Map<String, Object?> icons = const {},
      List<Object?> groups = const [],
    }) {
      return json.encode({
        '__flclashRuleOptions': {
          'options': options,
          'icons': icons,
          'groups': groups,
        },
      });
    }

    test('asks the script itself, with no profile to speak of', () async {
      answerWith(envelope(options: const {'Google': true}));

      await extractRuleOptions('const ruleOptionsEnable = { Google: true };');

      expect(calls, hasLength(1));
      expect(calls.single.config, '{}');
      expect(
        calls.single.script,
        contains('const ruleOptionsEnable = { Google: true };'),
      );
      expect(calls.single.script, contains('globalThis.main = function'));
    });

    test('reads the switches, their icons and their groups', () async {
      answerWith(
        envelope(
          options: const {'Google': true, '极简模式': false},
          icons: const {'Google': 'https://example.com/Google.svg', 'x': ''},
          groups: const ['Google', 3, ''],
        ),
      );

      final result = await extractRuleOptions('script-a');

      expect(result.options, {'Google': true, '极简模式': false});
      expect(result.icons, {'Google': 'https://example.com/Google.svg'});
      expect(result.groups, ['Google']);
      expect(result.error, isNull);
    });

    test('takes a switch the script gave no bool for as enabled', () async {
      answerWith(envelope(options: const {'Google': 1, 'AI': null}));

      final result = await extractRuleOptions('script-b');

      expect(result.options, {'Google': true, 'AI': true});
    });

    test('reports why a script could not be asked', () async {
      scriptEvaluator =
          ({required String script, required String config}) async {
            throw Exception('script timed out');
          };

      final result = await extractRuleOptions('script-c');

      expect(result.options, isEmpty);
      expect(result.error, contains('script timed out'));
    });

    test('answers a repeated script from memory', () async {
      answerWith(envelope(options: const {'Google': true}));

      await extractRuleOptions('script-d');
      await extractRuleOptions('script-d');

      expect(calls, hasLength(1));
    });
  });
}
