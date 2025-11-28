import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../shared/widgets/military_loader.dart';

class EventSelectorWidget extends ConsumerStatefulWidget {
  const EventSelectorWidget({super.key});

  @override
  ConsumerState<EventSelectorWidget> createState() =>
      _EventSelectorWidgetState();
}

class _EventSelectorWidgetState extends ConsumerState<EventSelectorWidget> {
  String _searchQuery = '';
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(availableEventsProvider);
    final selectedSteps = ref.watch(funnelStepsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withAlpha(204),
        border: Border.all(color: AppColors.slate.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(13),
              border: Border(
                bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, color: AppColors.white, size: 16),
                const SizedBox(width: 12),
                const Text(
                  'EVENT_SELECTION',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  color: AppColors.white.withAlpha(128),
                ),
              ],
            ),
          ),

          // Selected Steps Display
          if (selectedSteps.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.slate.withAlpha(77)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SELECTED STEPS',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${selectedSteps.length})',
                        style: TextStyle(
                          color: AppColors.slate.withAlpha(179),
                          fontSize: 11,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      const Spacer(),
                      if (selectedSteps.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            ref.read(funnelStepsProvider.notifier).clearSteps();
                          },
                          child: Text(
                            'CLEAR ALL',
                            style: TextStyle(
                              color: AppColors.error.withAlpha(204),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontFamily: 'Urbanist',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedSteps.length,
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(funnelStepsProvider.notifier)
                          .reorderSteps(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final step = selectedSteps[index];
                      return _StepChip(
                        key: ValueKey(step),
                        step: step,
                        stepNumber: index + 1,
                        onRemove: () {
                          ref
                              .read(funnelStepsProvider.notifier)
                              .removeStep(step);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

          // Event Picker
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.slate.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: AppColors.slate.withAlpha(179),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isExpanded
                              ? TextField(
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'Urbanist',
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search events...',
                                    hintStyle: TextStyle(
                                      color: AppColors.slate.withAlpha(179),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchQuery = value.toLowerCase();
                                    });
                                  },
                                )
                              : Text(
                                  'Add event to funnel...',
                                  style: TextStyle(
                                    color: AppColors.slate.withAlpha(179),
                                    fontFamily: 'Urbanist',
                                  ),
                                ),
                        ),
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: AppColors.slate.withAlpha(179),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // Event List (when expanded)
                if (_isExpanded)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.slate.withAlpha(77)),
                    ),
                    child: eventsAsync.when(
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(child: MilitaryLoader(label: 'LOADING...')),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ErrorFormatter.format(err),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (events) {
                        final filteredEvents = events
                            .where((event) =>
                                event.toLowerCase().contains(_searchQuery))
                            .where((event) => !selectedSteps.contains(event))
                            .toList();

                        if (filteredEvents.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No events matching "$_searchQuery"'
                                    : 'All events selected',
                                style: TextStyle(
                                  color: AppColors.slate.withAlpha(179),
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          itemCount: filteredEvents.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: AppColors.slate.withAlpha(51),
                          ),
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            return InkWell(
                              onTap: () {
                                ref
                                    .read(funnelStepsProvider.notifier)
                                    .addStep(event);
                                setState(() {
                                  _searchQuery = '';
                                  _isExpanded = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: AppColors.slate.withAlpha(179),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        event,
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontFamily: 'Urbanist',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  final String step;
  final int stepNumber;
  final VoidCallback onRemove;

  const _StepChip({
    required super.key,
    required this.step,
    required this.stepNumber,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withAlpha(26),
        border: Border.all(color: AppColors.white.withAlpha(77)),
      ),
      child: Row(
        children: [
          // Drag Handle
          Icon(
            Icons.drag_indicator,
            color: AppColors.slate.withAlpha(179),
            size: 16,
          ),
          const SizedBox(width: 12),
          // Step Number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.white.withAlpha(51),
              border: Border.all(color: AppColors.white.withAlpha(128)),
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Urbanist',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Event Name
          Expanded(
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
          // Remove Button
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              color: AppColors.error.withAlpha(204),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
