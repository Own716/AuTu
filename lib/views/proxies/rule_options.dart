import 'dart:async';
import 'dart:math' as math;

import 'package:outo/common/common.dart';
import 'package:outo/database/database.dart' hide Profiles;
import 'package:outo/enum/enum.dart';
import 'package:outo/models/models.dart';
import 'package:outo/providers/providers.dart';
import 'package:outo/widgets/widgets.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showRuleOptionsSheet(BuildContext context) {
  return showSheet<void>(
    context: context,
    builder: (_) => const RuleOptionsSheet(),
  );
}

/// What the current profile offers to switch, or null when it offers nothing.
sealed class RuleSwitches {
  const RuleSwitches({required this.profileId, required this.values});

  final int profileId;

  /// Name to whether it is on. The key order is the order to show.
  final Map<String, bool> values;

  /// The options that are also policy groups.
  List<String> get groups;

  /// The icon each option draws itself with, when it has one.
  Map<String, String> get icons;

  /// Groups the build cannot do without.
  Set<String> get locked => const {};
}

final class ScriptRuleSwitches extends RuleSwitches {
  const ScriptRuleSwitches({
    required super.profileId,
    required super.values,
    required this.script,
    required this.content,
    required this.declared,
  });

  final Script script;
  final String content;
  final ScriptRuleOptions declared;

  @override
  List<String> get groups => declared.groups;

  @override
  Map<String, String> get icons => declared.icons;
}

final class GroupRuleSwitches extends RuleSwitches {
  const GroupRuleSwitches({
    required super.profileId,
    required super.values,
    required this.groups,
    required this.icons,
    required this.locked,
  });

  @override
  final List<String> groups;

  @override
  final Map<String, String> icons;

  @override
  final Set<String> locked;
}

/// Reads whichever kind of switch the profile has, and null when the menu
/// entry would have nothing to open.
Future<RuleSwitches?> loadRuleSwitches(Profile? profile) async {
  if (profile == null || profile.type == ProfileType.custom) {
    return null;
  }
  if (profile.extendType == ExtendType.script) {
    return _loadScriptSwitches(profile);
  }
  return _loadGroupSwitches(profile);
}

Future<RuleSwitches?> _loadScriptSwitches(Profile profile) async {
  final scriptId = profile.scriptId;
  if (scriptId == null) {
    return null;
  }
  final script = await database.scriptsDao.get(scriptId).getSingleOrNull();
  final content = await script?.content;
  if (script == null || content == null || content.trim().isEmpty) {
    return null;
  }
  final declared = await extractRuleOptions(content);
  if (declared.options.isEmpty) {
    return null;
  }
  return ScriptRuleSwitches(
    profileId: profile.id,
    script: script,
    content: content,
    declared: declared,
    values: {
      for (final entry in declared.options.entries)
        entry.key: script.customOptions[entry.key] ?? entry.value,
    },
  );
}

Future<RuleSwitches?> _loadGroupSwitches(Profile profile) async {
  final Map<Object?, Object?> config;
  try {
    final path = await appPath.getProfilePath(profile.id.toString());
    final source = await readTextFileTask(path);
    if (source == null) {
      return null;
    }
    final decoded = await decodeYamlTask(source);
    if (decoded is! Map) {
      return null;
    }
    config = decoded;
  } catch (error) {
    commonPrint.log('rule switches could not read the profile: $error');
    return null;
  }
  final groups = <String>[];
  final icons = <String, String>{};
  final rawGroups = config['proxy-groups'];
  if (rawGroups is List) {
    for (final group in rawGroups) {
      if (group is! Map) {
        continue;
      }
      final name = group['name'];
      if (name is! String || name.isEmpty) {
        continue;
      }
      groups.add(name);
      final icon = group['icon'];
      if (icon is String && icon.isNotEmpty) {
        icons[name] = icon;
      }
    }
  }
  if (groups.isEmpty) {
    return null;
  }
  final rawRules = config['rules'] ?? config['rule'];
  final locked = <String>{};
  if (rawRules is List) {
    final target = lastMatchTarget([
      for (final rule in rawRules)
        if (rule is String) rule,
    ]);
    if (target != null) {
      locked.add(target);
    }
  }
  return GroupRuleSwitches(
    profileId: profile.id,
    groups: groups,
    icons: icons,
    locked: locked,
    values: {
      for (final name in groups) name: !profile.disabledGroups.contains(name),
    },
  );
}

class RuleOptionsSheet extends ConsumerStatefulWidget {
  const RuleOptionsSheet({super.key});

  @override
  ConsumerState<RuleOptionsSheet> createState() => _RuleOptionsSheetState();
}

class _RuleOptionsSheetState extends ConsumerState<RuleOptionsSheet> {
  RuleSwitches? _switches;

  /// What the sheet shows, and what the profile last accepted.
  Map<String, bool> _values = {};
  Map<String, bool> _saved = {};

  String? _failure;
  bool _isLoading = true;

  /// Saves run one at a time and in order, so a burst of switches cannot have
  /// an earlier value win over a later one on its way to the database.
  Future<void> _saves = Future.value();

  /// Held here because a save started before the sheet closed still has to
  /// reach the database, and `ref` is gone by then.
  late final ScriptsAction _scriptsAction;
  late final Profiles _profilesAction;
  late final SetupAction _setupAction;

  @override
  void initState() {
    super.initState();
    _scriptsAction = ref.read(scriptsActionProvider.notifier);
    _profilesAction = ref.read(profilesProvider.notifier);
    _setupAction = ref.read(setupActionProvider.notifier);
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final switches = await loadRuleSwitches(ref.read(currentProfileProvider));
      if (!mounted) {
        return;
      }
      setState(() {
        _switches = switches;
        _values = Map<String, bool>.of(switches?.values ?? const {});
        _saved = Map<String, bool>.of(_values);
        _failure = null;
        _isLoading = false;
      });
      unawaited(
        precacheTargetIcons(
          (switches?.icons.values ?? const <String>[]).where(
            (src) => src.startsWith('http://') || src.startsWith('https://'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _failure = '$error';
        _isLoading = false;
      });
    }
  }

  void _handleChanged(String name, bool value) {
    setState(() => _values[name] = value);
    // A save that throws must not leave the queue waiting on a dead future.
    _saves = _saves.then((_) => _save()).catchError((Object error) {
      commonPrint.log('rule switches were not stored: $error');
    });
  }

  /// Proves script switches against the profile on disk before they are
  /// stored, so a script that rejects them never leaves the Core without a
  /// config. Groups need no proof: the build drops what it removes.
  Future<String?> _validateScript(
    ScriptRuleSwitches switches,
    Map<String, bool> options,
  ) async {
    final Map<Object?, Object?> config;
    try {
      final path = await appPath.getProfilePath(switches.profileId.toString());
      final source = await readTextFileTask(path);
      final decoded = source == null ? null : await decodeYamlTask(source);
      if (decoded is! Map) {
        return null;
      }
      config = decoded;
    } catch (_) {
      // An unreadable profile tells us nothing about the switches; the build
      // that follows reports it instead.
      return null;
    }
    final raw = Map<String, dynamic>.from(config);
    if (raw['rules'] == null && raw['rule'] != null) {
      raw['rules'] = raw['rule'];
      raw.remove('rule');
    }
    try {
      await handleEvaluate(switches.content, raw, customOptions: options);
      return null;
    } catch (error) {
      return '$error';
    }
  }

  Future<void> _save() async {
    final switches = _switches;
    if (switches == null) {
      return;
    }
    final next = Map<String, bool>.of(_values);
    if (mapEquals(next, _saved)) {
      return;
    }
    switch (switches) {
      case ScriptRuleSwitches():
        final failure = await _validateScript(switches, next);
        if (failure != null) {
          _handleRejected(failure);
          return;
        }
        _scriptsAction.putScript(switches.script.copyWith(customOptions: next));
        _saved = next;
      case GroupRuleSwitches():
        _profilesAction.updateProfile(
          switches.profileId,
          (profile) => profile.copyWith(
            disabledGroups: {
              for (final entry in next.entries)
                if (!entry.value) entry.key,
            },
          ),
        );
        _setupAction.applyProfileDebounce(silence: true);
        _saved = next;
    }
  }

  void _handleRejected(String failure) {
    if (!mounted) {
      return;
    }
    setState(() => _values = Map<String, bool>.of(_saved));
    unawaited(
      dialogs.showMessage(
        message: TextSpan(
          text: '${context.appLocalizations.ruleOptionsRejected}\n\n$failure',
        ),
        cancelable: false,
      ),
    );
  }

  Widget _buildIcon(Map<String, String> icons, String name) {
    final src = icons[name];
    final fallback = GroupMonogram(name);
    if (src == null ||
        !(src.startsWith('http://') ||
            src.startsWith('https://') ||
            src.startsWith('data:'))) {
      return fallback;
    }
    return CommonTargetIcon(src: src, fallback: fallback);
  }

  Widget _buildRow(RuleSwitches switches, String name, {required int index}) {
    final locked = switches.locked.contains(name);
    return _RuleOptionEntry(
      index: index,
      child: ListItem.toggle(
        leading: SizedBox.square(
          dimension: 24,
          child: Center(child: _buildIcon(switches.icons, name)),
        ),
        title: Text(name),
        subtitle: locked
            ? Text(context.appLocalizations.ruleOptionsLockedGroup)
            : null,
        value: _values[name] ?? false,
        onChanged: locked ? null : (value) => _handleChanged(name, value),
      ),
    );
  }

  Widget _buildContent() {
    final appLocalizations = context.appLocalizations;
    final switches = _switches;
    if (switches == null) {
      return NullStatus(
        illustration: NullStatusIllustration.scripts,
        label: _failure == null
            ? appLocalizations.ruleOptionsEmpty
            : appLocalizations.ruleOptionsFailed,
        description: _failure ?? appLocalizations.ruleOptionsEmptyDesc,
      );
    }
    final groups = {
      for (final name in switches.groups)
        if (_values.containsKey(name)) name,
    };
    final groupNames = [
      for (final name in _values.keys)
        if (groups.contains(name)) name,
    ];
    final otherNames = [
      for (final name in _values.keys)
        if (!groups.contains(name)) name,
    ];
    var index = 0;
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ).copyWith(top: context.contentTopPadding, bottom: 32),
      children: [
        if (groupNames.isNotEmpty)
          generateSection(
            title: appLocalizations.ruleOptionsGroups,
            items: [
              for (final name in groupNames)
                _buildRow(switches, name, index: index++),
            ],
          ),
        if (otherNames.isNotEmpty)
          generateSection(
            title: appLocalizations.ruleOptionsOthers,
            items: [
              for (final name in otherNames)
                _buildRow(switches, name, index: index++),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: context.appLocalizations.ruleOptions,
      body: NullStatusSwitcher(
        isLoading: _isLoading,
        isEmpty: false,
        child: _buildContent(),
      ),
    );
  }
}

/// Rows arrive one after another, so a long list reads as a list rather than
/// appearing all at once with the sheet.
class _RuleOptionEntry extends StatelessWidget {
  static const _duration = Duration(milliseconds: 420);
  static const _step = 0.045;
  static const _run = 0.5;

  final int index;
  final Widget child;

  const _RuleOptionEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final start = math.min(index * _step, 0.4);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.motionDuration(_duration),
      curve: Interval(
        start,
        math.min(start + _run, 1),
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
