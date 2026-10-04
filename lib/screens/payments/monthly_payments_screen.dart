import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_utils.dart';
import '../../models/member_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/report_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/cards/payment_grid_card.dart';
import '../../widgets/common/app_error_view.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/common/gender_icon.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/empty_states/empty_state_view.dart';

class MonthlyPaymentsScreen extends StatefulWidget {
  const MonthlyPaymentsScreen({super.key});

  @override
  State<MonthlyPaymentsScreen> createState() => _MonthlyPaymentsScreenState();
}

class _MonthlyPaymentsScreenState extends State<MonthlyPaymentsScreen> {
  bool _unpaidTab = true;
  bool _exporting = false;

  Future<void> _exportPdf(List<MemberModel> active) async {
    if (_exporting) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _exporting = true);
    try {
      await ReportService().saveToDownloads(active);
      const shortPath = 'Downloads folder';
      messenger.showSnackBar(
        SnackBar(
          content: Text('Report saved to $shortPath'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
              label: 'Share',
              onPressed: () => ReportService().sharePaymentReport(active)),
        ),
      );
    } catch (_) {
      try {
        await ReportService().sharePaymentReport(active);
      } catch (_) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not create the report. Please try again.'),
            backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemberProvider>();
    final template =
        context.watch<SettingsProvider>().settings.reminderTemplate;
    final active = provider.allMembers
        .where((m) => m.status == MemberStatus.active)
        .toList();
    final unpaid = active.where((m) => !m.currentMonthPaid).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final paid = active.where((m) => m.currentMonthPaid).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final visible = _unpaidTab ? unpaid : paid;

    Widget body;
    if (provider.error != null) {
      body = AppErrorView(message: provider.error!, onRetry: provider.retry);
    } else if (provider.isLoading) {
      body = const AppLoadingIndicator();
    } else if (active.isEmpty) {
      body = const EmptyStateView(
        icon: PhosphorIconsRegular.creditCard,
        title: 'No active members',
        subtitle: 'Add members to start tracking payments',
        accent: AppColors.primary,
      );
    } else {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border)),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TabButton(
                                icon: PhosphorIconsBold.xCircle,
                                label: 'Unpaid',
                                count: unpaid.length,
                                selected: _unpaidTab,
                                color: AppColors.danger,
                                onTap: () => setState(() => _unpaidTab = true),
                              ),
                            ),
                            Expanded(
                              child: _TabButton(
                                icon: PhosphorIconsBold.checkCircle,
                                label: 'Paid',
                                count: paid.length,
                                selected: !_unpaidTab,
                                color: AppColors.success,
                                onTap: () => setState(() => _unpaidTab = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_unpaidTab && unpaid.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _RemindAllButton(
                          onTap: () => _showBulkReminderSheet(
                              context, unpaid, template)),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, 0.03),
                                  end: Offset.zero)
                              .animate(animation),
                          child: child)),
                  child: visible.isEmpty
                      ? EmptyStateView(
                          key: const ValueKey('empty'),
                          icon: _unpaidTab
                              ? PhosphorIconsRegular.checkCircle
                              : PhosphorIconsRegular.receipt,
                          title:
                              _unpaidTab ? 'All caught up' : 'No payments yet',
                          subtitle: _unpaidTab
                              ? 'Every active member has paid'
                              : 'Paid members will appear here',
                          accent: _unpaidTab
                              ? AppColors.success
                              : AppColors.textSecondary,
                        )
                      : GridView.builder(
                          key: ValueKey(_unpaidTab),
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                            mainAxisExtent: 260,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (context, index) => PaymentGridCard(
                            member: visible[index],
                            isPaidTab: !_unpaidTab,
                            onTap: () => _showMemberActionsSheet(
                                context, visible[index], !_unpaidTab, template),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Payments',
        actions: [
          IconButton(
            tooltip: 'Save PDF report',
            onPressed: _exporting ? null : () => _exportPdf(active),
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                : const Icon(PhosphorIconsBold.downloadSimple, size: 23),
          ),
          IconButton(
              tooltip: 'History',
              onPressed: () => context.push('/payment-history'),
              icon: const Icon(PhosphorIconsRegular.clockCounterClockwise,
                  size: 23)),
        ],
      ),
      body: SafeArea(child: body),
    );
  }

  void _showMemberActionsSheet(BuildContext context, MemberModel member,
      bool isPaidTab, String template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4))),
              Row(
                children: [
                  GenderIcon(gender: member.gender, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(member.name,
                            style: AppTextStyles.title.copyWith(fontSize: 17)),
                        Text(
                            '${CurrencyFormatter.format(member.feeAmount)} · Due ${AppDateUtils.formatDate(member.nextDueDate)}',
                            style:
                                AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isPaidTab)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmUndo(context, member);
                    },
                    icon: const Icon(PhosphorIconsBold.arrowCounterClockwise,
                        size: 18),
                    label: const Text('Undo Payment'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.textSecondary),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmPay(context, member);
                    },
                    icon: const Icon(PhosphorIconsBold.checkCircle,
                        size: 18, color: Colors.white),
                    label: const Text('Mark Paid'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.success),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      WhatsAppService().sendReminder(
                          phone: member.whatsappNumber,
                          memberName: member.name,
                          amountDue: member.feeAmount,
                          template: template);
                    },
                    icon: const Icon(PhosphorIconsBold.whatsappLogo,
                        size: 18, color: AppColors.success),
                    label: const Text('Send Reminder'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success)),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    WhatsAppService().callMember(member.whatsappNumber);
                  },
                  icon: const Icon(PhosphorIconsBold.phone, size: 18),
                  label: const Text('Call Member'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBulkReminderSheet(
      BuildContext context, List<MemberModel> unpaidMembers, String template) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4)))),
              Text('Send Reminders',
                  style: AppTextStyles.title.copyWith(fontSize: 20)),
              const SizedBox(height: AppSpacing.xs),
              Text('Tap a member to open WhatsApp with the reminder ready',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: unpaidMembers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = unpaidMembers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(member.name,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      subtitle: Text(member.whatsappNumber,
                          style:
                              AppTextStyles.bodyMuted.copyWith(fontSize: 13.5)),
                      trailing: const Icon(PhosphorIconsBold.whatsappLogo,
                          color: AppColors.success, size: 26),
                      onTap: () => WhatsAppService().sendReminder(
                          phone: member.whatsappNumber,
                          memberName: member.name,
                          amountDue: member.feeAmount,
                          template: template),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TabButton(
      {required this.icon,
      required this.label,
      required this.count,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
        decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2)),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: selected ? color : AppColors.textDisabled),
            const SizedBox(width: 6),
            Text('$label ($count)',
                style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: selected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RemindAllButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemindAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.successBg,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.35))),
          child: const Icon(PhosphorIconsBold.whatsappLogo,
              color: AppColors.success, size: 22),
        ),
      ),
    );
  }
}

Future<void> _confirmPay(BuildContext context, MemberModel member) async {
  final provider = context.read<MemberProvider>();
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Confirm Payment'),
      content: Text(
          'Received ${CurrencyFormatter.format(member.feeAmount)} from ${member.name}?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Paid',
                style: TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  if (confirmed != true) return;

  provider.confirmPayment(member).catchError((_) {
    messenger.showSnackBar(const SnackBar(
        content: Text('Payment could not be saved. Check your connection.'),
        backgroundColor: AppColors.danger));
  });
  messenger.showSnackBar(SnackBar(
      content: Text('Payment recorded for ${member.name}'),
      behavior: SnackBarBehavior.floating));
}

Future<void> _confirmUndo(BuildContext context, MemberModel member) async {
  final provider = context.read<MemberProvider>();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Undo Payment?'),
      content: Text('${member.name} will move back to Unpaid for this month.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Undo',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700))),
      ],
    ),
  );
  if (confirmed == true) {
    provider.markUnpaid(member.id);
  }
}
