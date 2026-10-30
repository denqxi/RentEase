import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/app_update_cubit.dart';

/// Re-checks for an update when the app returns to the foreground.
/// The cubit throttles, so this is cheap. Needs [AppUpdateCubit] above it.
class UpdateLifecycleWatcher extends StatefulWidget {
  const UpdateLifecycleWatcher({required this.child, super.key});

  final Widget child;

  @override
  State<UpdateLifecycleWatcher> createState() => _UpdateLifecycleWatcherState();
}

class _UpdateLifecycleWatcherState extends State<UpdateLifecycleWatcher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppUpdateCubit>().checkForUpdate();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
