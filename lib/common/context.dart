import 'package:outo/enum/enum.dart';
import 'package:outo/l10n/l10n.dart';
import 'package:outo/manager/status_manager.dart';
import 'package:outo/models/state.dart';
import 'package:material_ui/material_ui.dart';

extension AppContextExtension on BuildContext {
  void showNotifier(
    String text, {
    MessageLevel level = MessageLevel.info,
    MessageActionState? actionState,
  }) {
    return findAncestorStateOfType<StatusManagerState>()?.message(
      text,
      level: level,
      actionState: actionState,
    );
  }

  AppLocalizations get appLocalizations => AppLocalizations.of(this);
}
