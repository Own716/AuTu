import 'dart:async';

import 'package:outo/common/common.dart';
import 'package:outo/enum/enum.dart';
import 'package:outo/models/models.dart';
import 'package:outo/providers/providers.dart';
import 'package:outo/ui/icons/icons.dart';
import 'package:outo/views/proxies/list.dart';
import 'package:outo/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rule_options.dart';
import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key, this.picker = false});

  /// Leaves the bar only its search and delay test, for picking a proxy from a
  /// sheet.
  final bool picker;

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();

  // The same instance on every build, so the bar changing with the current
  // group or its delay test leaves the page alone.
  late final _tabView = ProxiesTabView(key: _proxiesTabKey);
  bool _isTab = false;

  /// Decided off the profile: a script must be asked, a YAML parsed.
  bool _hasRuleSwitches = false;

  List<CommonPopupMenuItem> _buildMenuItems(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return [
      if (_hasRuleSwitches)
        CommonPopupMenuItem(
          glyph: AppGlyphs.toggle,
          label: appLocalizations.ruleOptions,
          onPressed: () {
            showRuleOptionsSheet(context);
          },
        ),
      CommonPopupMenuItem(
        glyph: AppGlyphs.sliders,
        label: appLocalizations.settings,
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return CommonScaffold(
                body: const ProxiesSetting(),
                title: appLocalizations.settings,
              );
            },
          );
        },
      ),
    ];
  }

  IconButtonData? _buildPrimaryAction() {
    if (!_isTab) {
      return null;
    }
    final isDelayTesting = ref.watch(currentGroupDelayTestingProvider);
    return IconButtonData(
      glyph: AppGlyphs.bolt,
      onPressed: () {
        _proxiesTabKey.currentState?.delayTestCurrentGroup();
      },
      tooltip: context.appLocalizations.delayTest,
      isLoading: isDelayTesting,
    );
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
    ref.listenManual(
      currentProfileProvider,
      (_, profile) => unawaited(_resolveRuleSwitches(profile)),
      fireImmediately: true,
    );
  }

  Future<void> _resolveRuleSwitches(Profile? profile) async {
    final bool available;
    try {
      available = await loadRuleSwitches(profile) != null;
    } catch (error) {
      commonPrint.log('rule switches could not be resolved: $error');
      return;
    }
    if (!mounted || available == _hasRuleSwitches) {
      return;
    }
    setState(() => _hasRuleSwitches = available);
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final picker = widget.picker;
    final primaryAction = _buildPrimaryAction();
    return CommonScaffold(
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      primaryAction: primaryAction,
      searchActions: [?primaryAction],
      iconActions: [
        if (_isTab && !picker)
          IconButtonData(
            glyph: AppGlyphs.locate,
            onPressed: () {
              _proxiesTabKey.currentState?.scrollToGroupSelected();
            },
            tooltip: context.appLocalizations.scrollToSelected,
          ),
      ],
      menuItems: picker ? const [] : _buildMenuItems(context),
      title: context.appLocalizations.proxies,
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: switch (proxiesType) {
        ProxiesType.tab => _tabView,
        ProxiesType.list => const ProxiesListView(),
      },
    );
  }
}
