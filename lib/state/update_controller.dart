import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tick/domain/app_update.dart';
import 'package:tick/state/app_controller.dart';

final updateOfferProvider = NotifierProvider<UpdateController, UpdateOffer>(UpdateController.new);

class UpdateController extends Notifier<UpdateOffer> {
  var _latestBuild = 0;

  @override
  UpdateOffer build() {
    Future<void>.microtask(refresh);
    return const UpdateOffer.none();
  }

  Future<void> refresh() async {
    final deps = ref.read(depsProvider);
    final policy = await deps.updates.load();
    if (!ref.mounted || policy == null) return;
    _latestBuild = policy.latestBuild;
    state = decideUpdate(
      currentBuild: deps.installedBuild,
      minBuild: policy.minBuild,
      latestBuild: policy.latestBuild,
      dismissedBuild: deps.store.state.dismissedUpdateBuild,
      url: policy.url,
    );
  }

  void dismiss() {
    if (state.kind != UpdateKind.optional) return;
    final deps = ref.read(depsProvider);
    deps.store.state.dismissedUpdateBuild = _latestBuild;
    unawaited(deps.store.save());
    state = const UpdateOffer.none();
  }
}
