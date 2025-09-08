import 'package:flutter/material.dart';

class ShippingStatusTimeline extends StatelessWidget {
  const ShippingStatusTimeline({super.key, this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final _NormalizedStatus normalized = _normalizeStatus(status);
    final List<_TimelineStep> allSteps = _defaultSteps();

    // If cancelled, show a shortened path ending with cancellation
    final List<_TimelineStep> visibleSteps = normalized == _NormalizedStatus.cancelled
        ? <_TimelineStep>[allSteps[0], allSteps[1], _TimelineStep(
            key: _NormalizedStatus.cancelled,
            label: 'Otkazano',
            icon: Icons.cancel,
          )]
        : <_TimelineStep>[for (final _TimelineStep s in allSteps.where((s) => s.key != _NormalizedStatus.cancelled)) s];

    final int currentIndex = _currentIndexForStatus(visibleSteps, normalized);

    return Column(
      children: <Widget>[
        for (int i = 0; i < visibleSteps.length; i++)
          _TimelineNode(
            label: visibleSteps[i].label,
            icon: visibleSteps[i].icon,
            state: _nodeStateFor(i, currentIndex, normalized),
            isLast: i == visibleSteps.length - 1,
          ),
      ],
    );
  }

  int _currentIndexForStatus(List<_TimelineStep> steps, _NormalizedStatus normalized) {
    final int idx = steps.indexWhere((s) => s.key == normalized);
    if (idx >= 0) return idx;
    // Default to the first step if unknown
    return 0;
  }

  _NodeState _nodeStateFor(int i, int currentIndex, _NormalizedStatus normalized) {
    if (normalized == _NormalizedStatus.cancelled && i == currentIndex) return _NodeState.activeCancelled;
    if (i < currentIndex) return _NodeState.completed;
    if (i == currentIndex) return _NodeState.active;
    return _NodeState.upcoming;
  }
}

enum _NormalizedStatus {
  pending,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  unknown,
}

class _TimelineStep {
  const _TimelineStep({required this.key, required this.label, required this.icon});

  final _NormalizedStatus key;
  final String label;
  final IconData icon;
}

List<_TimelineStep> _defaultSteps() {
  return const <_TimelineStep>[
    _TimelineStep(key: _NormalizedStatus.pending, label: 'Narudžba zaprimljena', icon: Icons.receipt_long),
    _TimelineStep(key: _NormalizedStatus.processing, label: 'Obrada narudžbe', icon: Icons.autorenew),
    _TimelineStep(key: _NormalizedStatus.shipped, label: 'Poslano', icon: Icons.local_shipping),
    _TimelineStep(key: _NormalizedStatus.outForDelivery, label: 'U dostavi', icon: Icons.delivery_dining),
    _TimelineStep(key: _NormalizedStatus.delivered, label: 'Isporučeno', icon: Icons.check_circle),
    _TimelineStep(key: _NormalizedStatus.cancelled, label: 'Otkazano', icon: Icons.cancel),
  ];
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.label,
    required this.icon,
    required this.state,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final _NodeState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color activeColor = state == _NodeState.activeCancelled ? Colors.red : scheme.primary;
    final Color completedColor = scheme.primary;
    final Color upcomingColor = Colors.grey.shade400;
    final Color lineColor = state == _NodeState.activeCancelled ? Colors.red.shade200 : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          children: <Widget>[
            _buildDot(activeColor, completedColor, upcomingColor),
            if (!isLast)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: 2,
                height: 24,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: <Widget>[
                Icon(icon, size: 18, color: _colorForState(activeColor, completedColor, upcomingColor)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: state == _NodeState.active || state == _NodeState.activeCancelled ? FontWeight.w600 : FontWeight.w400,
                      color: _colorForState(activeColor, completedColor, upcomingColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(Color activeColor, Color completedColor, Color upcomingColor) {
    switch (state) {
      case _NodeState.completed:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: completedColor, shape: BoxShape.circle),
          child: const Icon(Icons.check, size: 12, color: Colors.white),
        );
      case _NodeState.active:
      case _NodeState.activeCancelled:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: activeColor, width: 3),
            shape: BoxShape.circle,
          ),
        );
      case _NodeState.upcoming:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: upcomingColor, width: 2),
            shape: BoxShape.circle,
          ),
        );
    }
  }

  Color _colorForState(Color activeColor, Color completedColor, Color upcomingColor) {
    switch (state) {
      case _NodeState.completed:
        return completedColor;
      case _NodeState.active:
      case _NodeState.activeCancelled:
        return activeColor;
      case _NodeState.upcoming:
        return upcomingColor;
    }
  }
}

enum _NodeState { completed, active, activeCancelled, upcoming }

_NormalizedStatus _normalizeStatus(String? status) {
  if (status == null || status.trim().isEmpty) return _NormalizedStatus.unknown;
  final String s = status.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  if (<String>{'created', 'new', 'pending', 'zaprimljena', 'primljena'}.contains(s)) return _NormalizedStatus.pending;
  if (<String>{'processing', 'processed', 'inprogress', 'preparing', 'obrada', 'uobradi'}.contains(s)) return _NormalizedStatus.processing;
  if (<String>{'shipped', 'sent', 'poslano', 'otpremljeno'}.contains(s)) return _NormalizedStatus.shipped;
  if (<String>{'outfordelivery', 'udostavi', 'ontheroad'}.contains(s)) return _NormalizedStatus.outForDelivery;
  if (<String>{'delivered', 'isporuceno', 'completed', 'zavrseno'}.contains(s)) return _NormalizedStatus.delivered;
  if (<String>{'cancelled', 'canceled', 'otkazano'}.contains(s)) return _NormalizedStatus.cancelled;

  // Fallback mapping heuristics
  if (s.contains('deliver')) return _NormalizedStatus.outForDelivery;
  if (s.contains('ship') || s.contains('post')) return _NormalizedStatus.shipped;
  if (s.contains('cancel')) return _NormalizedStatus.cancelled;

  return _NormalizedStatus.unknown;
}
