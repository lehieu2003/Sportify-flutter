class PlaybackActionCoordinator {
  final Set<String> _activeActions = <String>{};

  bool tryStart(String actionKey) {
    if (_activeActions.contains(actionKey)) {
      return false;
    }
    _activeActions.add(actionKey);
    return true;
  }

  void finish(String actionKey) {
    _activeActions.remove(actionKey);
  }

  bool get hasInFlightActions => _activeActions.isNotEmpty;
}
