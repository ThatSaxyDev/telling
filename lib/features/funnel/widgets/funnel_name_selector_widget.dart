import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telling/core/constants/funnel_constants.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../../core/providers/analytics_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../shared/widgets/military_loader.dart';

class FunnelNameSelectorWidget extends ConsumerStatefulWidget {
  const FunnelNameSelectorWidget({super.key});

  @override
  ConsumerState<FunnelNameSelectorWidget> createState() =>
      _FunnelNameSelectorWidgetState();
}

class _FunnelNameSelectorWidgetState
    extends ConsumerState<FunnelNameSelectorWidget> {
  String _searchQuery = '';
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final funnelNamesAsync = ref.watch(availableFunnelNamesProvider);
    final selectedFunnelName = ref.watch(selectedFunnelNameProvider);

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
                const Icon(Icons.filter_alt, color: AppColors.white, size: 16),
                const SizedBox(width: 12),
                const Text(
                  'FUNNEL_SELECTION',
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

          // Selected Funnel Display
          if (selectedFunnelName != null && selectedFunnelName.isNotEmpty)
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
                        'SELECTED FUNNEL',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontFamily: 'Urbanist',
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          ref.read(selectedFunnelNameProvider.notifier).clear();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.error.withAlpha(128),
                            ),
                            color: AppColors.error.withAlpha(26),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.error.withAlpha(204),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CLEAR',
                                style: TextStyle(
                                  color: AppColors.error.withAlpha(204),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withAlpha(26),
                      border: Border.all(color: AppColors.white.withAlpha(77)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt,
                          color: AppColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFunnelName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 13,
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Funnel Picker
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
                                    hintText: 'Search funnels...',
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
                                  'Select a funnel to analyze...',
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

                // Funnel List (when expanded)
                if (_isExpanded)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark,
                      border: Border.all(color: AppColors.slate.withAlpha(77)),
                    ),
                    child: funnelNamesAsync.when(
                      loading: () => const SizedBox(
                        height: 150,
                        child: Center(
                          child: MilitaryLoader(label: 'LOADING...'),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ErrorFormatter.format(err),
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                      data: (funnelNames) {
                        final filteredFunnels = funnelNames
                            .where(
                              (funnel) =>
                                  funnel.toLowerCase().contains(_searchQuery),
                            )
                            .toList();

                        if (filteredFunnels.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? 'No funnels matching "$_searchQuery"'
                                    : 'No funnels tracked yet',
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
                          itemCount: filteredFunnels.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: AppColors.slate.withAlpha(51),
                          ),
                          itemBuilder: (context, index) {
                            final funnel = filteredFunnels[index];
                            return InkWell(
                              onTap: () {
                                ref
                                    .read(selectedFunnelNameProvider.notifier)
                                    .setFunnelName(funnel);
                                Telling.instance.trackFunnel(
                                  funnelName:
                                      FunnelConstants.funnelAnalysisFunnel,
                                  stepName: FunnelConstants.funnelNameSearched,
                                  step: 2,
                                );
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
                                      Icons.filter_alt,
                                      color: AppColors.slate.withAlpha(179),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        funnel,
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
