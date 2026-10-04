import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/cards/plan_card.dart';
import '../../widgets/common/app_error_view.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/empty_states/empty_state_view.dart';

class PlanListScreen extends StatelessWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanProvider>();
    final isDesktop =
        MediaQuery.of(context).size.width >= AppSpacing.tabletBreakpoint;

    Widget content;
    if (provider.error != null) {
      content = AppErrorView(message: provider.error!, onRetry: provider.retry);
    } else if (provider.isLoading) {
      content = const AppLoadingIndicator();
    } else if (provider.plans.isEmpty) {
      content = EmptyStateView(
        icon: PhosphorIconsRegular.tag,
        title: 'No plans yet',
        subtitle: 'Create a plan like Monthly or Yearly to assign to members',
        actionLabel: 'Add Plan',
        onAction: () => context.push('/plans/add'),
        accent: const Color(0xFF8B5CF6),
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : (constraints.maxWidth >= 600 ? 3 : 2);
          return GridView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.78),
            itemCount: provider.plans.length,
            itemBuilder: (context, index) {
              final plan = provider.plans[index];
              return PlanCard(
                  plan: plan,
                  index: index,
                  onTap: () => context.push('/plans/${plan.id}/edit'),
                  onDelete: () => _confirmDelete(context, plan.id, plan.name));
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: isDesktop ? null : const PremiumAppBar(title: 'Membership Plans'),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/plans/add'),
              backgroundColor: AppColors.primary,
              icon: const Icon(PhosphorIconsBold.plus,
                  color: Colors.white, size: 20),
              label: Text('Add Plan',
                  style: AppTextStyles.button.copyWith(fontSize: 15)),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Membership Plans', style: AppTextStyles.headline),
                      ElevatedButton.icon(
                          onPressed: () => context.push('/plans/add'),
                          icon: const Icon(PhosphorIconsBold.plus,
                              size: 18, color: Colors.white),
                          label: const Text('Add Plan')),
                    ],
                  ),
                ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String planId, String planName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Plan'),
        content: Text(
            'Delete "$planName"? Members already on this plan keep their assigned fee.'),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PlanProvider>().deletePlan(planId);
    }
  }
}
