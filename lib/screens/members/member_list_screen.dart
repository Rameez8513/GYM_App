import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../services/report_service.dart';
import '../../widgets/cards/member_grid_card.dart';
import '../../widgets/common/animated_scale_tap.dart';
import '../../widgets/common/app_error_view.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/empty_states/empty_state_view.dart';

class MemberListScreen extends StatefulWidget {
  const MemberListScreen({super.key});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final _searchController = TextEditingController();
  int _page = 0;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<MemberProvider>().searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncSearch(String query) {
    if (_searchController.text == query) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchController.text != query)
        _searchController.text = query;
    });
  }

  Future<void> _exportMembersPdf(List<MemberModel> members) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await ReportService().saveMembersListToDownloads(members);
      if (mounted) {
        showAppSnackBar(context, 'Member list ready');
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Could not create the report.',
            backgroundColor: AppColors.danger);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final wide = isWideScreen(context);
    final width = MediaQuery.of(context).size.width;
    final members = provider.filteredMembers;
    _syncSearch(provider.searchQuery);

    final chips = <(MemberQuickFilter, String, Color)>[
      (MemberQuickFilter.all, 'All', AppColors.primary),
      (MemberQuickFilter.active, 'Active', AppColors.textPrimary),
      (MemberQuickFilter.paid, 'Paid', AppColors.success),
      (MemberQuickFilter.unpaid, 'Unpaid', AppColors.danger),
      (MemberQuickFilter.inactive, 'Inactive', AppColors.textSecondary),
    ];

    Widget content;
    if (provider.error != null) {
      content = AppErrorView(message: provider.error!, onRetry: provider.retry);
    } else if (provider.isLoading) {
      content = const AppLoadingIndicator();
    } else if (members.isEmpty) {
      final filtered = provider.hasActiveFilters;
      content = EmptyStateView(
        icon: PhosphorIconsRegular.usersThree,
        title: filtered ? 'No members match' : 'No members yet',
        subtitle: filtered
            ? 'Try another filter or search'
            : 'Add your first member to get started',
        actionLabel: filtered ? 'Show All Members' : 'Add Member',
        onAction: filtered
            ? provider.resetFilters
            : () => context.push('/members/add'),
        accent: AppColors.primary,
      );
    } else {
      final perPage = (() {
        final estimatedColumns = (width / 170).floor().clamp(1, 20);
        return estimatedColumns * 3;
      })();
      final totalPages =
          members.isEmpty ? 1 : (members.length / perPage).ceil();
      final currentPage = _page.clamp(0, totalPages - 1);
      final pageStart = currentPage * perPage;
      final pageEnd = (pageStart + perPage).clamp(0, members.length);
      final pageItems = members.sublist(pageStart, pageEnd);

      content = Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(bottom: 4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 262,
              ),
              itemCount: pageItems.length,
              itemBuilder: (context, index) => MemberGridCard(
                member: pageItems[index],
                onTap: () => context.push('/members/${pageItems[index].id}'),
              ),
            ),
          ),
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: _Pagination(
                  currentPage: currentPage,
                  totalPages: totalPages,
                  onChange: (p) => setState(() => _page = p)),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: wide
          ? null
          : PremiumAppBar(
              title: 'Members',
              actions: [
                IconButton(
                  tooltip: 'Download member list',
                  onPressed: _exporting
                      ? null
                      : () => _exportMembersPdf(provider.allMembers),
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(AppColors.primary)))
                      : const Icon(PhosphorIconsBold.downloadSimple, size: 21),
                ),
              ],
            ),
      floatingActionButton: wide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/members/add'),
              backgroundColor: AppColors.primary,
              icon: const Icon(PhosphorIconsBold.plus,
                  color: Colors.white, size: 20),
              label: Text('Add Member',
                  style: AppTextStyles.button.copyWith(fontSize: 15)),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: wide ? 1200 : double.infinity),
            child: Padding(
              padding: EdgeInsets.fromLTRB(wide ? AppSpacing.xl : AppSpacing.md,
                  AppSpacing.md, wide ? AppSpacing.xl : AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wide)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Members', style: AppTextStyles.headline),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _exporting
                                    ? null
                                    : () =>
                                        _exportMembersPdf(provider.allMembers),
                                icon: const Icon(
                                    PhosphorIconsBold.downloadSimple,
                                    size: 18),
                                label: const Text('Export PDF'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/members/add'),
                                icon: const Icon(PhosphorIconsBold.plus,
                                    size: 18, color: Colors.white),
                                label: const Text('Add Member'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      provider.setSearchQuery(v);
                      setState(() => _page = 0);
                    },
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                        hintText: 'Search by name',
                        hintStyle:
                            AppTextStyles.bodyMuted.copyWith(fontSize: 14),
                        prefixIcon: const Icon(
                            PhosphorIconsRegular.magnifyingGlass,
                            size: 20)),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: chips.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final chip = chips[index];
                        return _FilterChip(
                          label: chip.$2,
                          count: provider.countFor(chip.$1),
                          color: chip.$3,
                          selected: provider.quickFilter == chip.$1,
                          onTap: () {
                            provider.setQuickFilter(chip.$1);
                            setState(() => _page = 0);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!provider.isLoading && provider.error == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                        style: AppTextStyles.label,
                      ),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onChange;
  const _Pagination(
      {required this.currentPage,
      required this.totalPages,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            onPressed: currentPage > 0 ? () => onChange(currentPage - 1) : null,
            icon: const Icon(PhosphorIconsBold.caretLeft, size: 18)),
        Text('Page ${currentPage + 1} of $totalPages',
            style: AppTextStyles.body
                .copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)),
        IconButton(
            onPressed: currentPage < totalPages - 1
                ? () => onChange(currentPage + 1)
                : null,
            icon: const Icon(PhosphorIconsBold.caretRight, size: 18)),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.count,
      required this.color,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
        decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.18) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: selected ? color : AppColors.border)),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: AppTextStyles.body.copyWith(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600)),
          const SizedBox(width: 6),
          Text('$count',
              style: AppTextStyles.body.copyWith(
                  color: selected ? color : AppColors.textDisabled,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700))
        ]),
      ),
    );
  }
}
