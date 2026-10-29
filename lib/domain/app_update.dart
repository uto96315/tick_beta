enum UpdateKind { none, optional, required }

class UpdateOffer {
  const UpdateOffer({required this.kind, required this.url});

  const UpdateOffer.none() : kind = UpdateKind.none, url = '';

  final UpdateKind kind;
  final String url;
}

class UpdatePolicy {
  const UpdatePolicy({required this.minBuild, required this.latestBuild, required this.url});

  final int minBuild;
  final int latestBuild;
  final String url;
}

bool canOpenUpdateLink(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) return false;
  return uri.isScheme('https') || uri.isScheme('http');
}

/// [currentBuild] of 0 means the installed build could not be read, so Tick
/// stays open rather than locking everyone out.
UpdateOffer decideUpdate({
  required int currentBuild,
  required int minBuild,
  required int latestBuild,
  required int dismissedBuild,
  required String url,
}) {
  if (currentBuild <= 0) return const UpdateOffer.none();
  final link = url.trim();
  if (minBuild > 0 && currentBuild < minBuild) {
    return UpdateOffer(kind: UpdateKind.required, url: link);
  }
  if (latestBuild > 0 &&
      currentBuild < latestBuild &&
      dismissedBuild < latestBuild &&
      canOpenUpdateLink(link)) {
    return UpdateOffer(kind: UpdateKind.optional, url: link);
  }
  return const UpdateOffer.none();
}
