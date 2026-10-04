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
import '../../models/payment_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/common/app_loading_indicator.dart';
import '../../widgets/empty_states/empty_state_view.dart';

class MemberDetailScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final member = context.watch<MemberProvider>().getById(memberId);

    if (member == null) {
      return const Scaffold(body: AppLoadingIndicator());
    }

    final isMale = member.gender == Gender.male;
    final genderColor =
        isMale ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);
    final statusColor =
        member.currentMonthPaid ? AppColors.success : AppColors.danger;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            expandedHeight: 260,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle),
                child: const Icon(PhosphorIconsBold.arrowLeft,
                    color: Colors.white, size: 18),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/members/${member.id}/edit'),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsBold.pencilSimple,
                      color: Colors.white, size: 16),
                ),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, member),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle),
                  child: const Icon(PhosphorIconsBold.trash,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    genderColor.withValues(alpha: 0.35),
                    AppColors.surface
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: isMale
                                  ? const [Color(0xFF60A5FA), Color(0xFF1E3A5F)]
                                  : const [
                                      Color(0xFFF472B6),
                                      Color(0xFF4A1E3D)
                                    ]),
                          boxShadow: [
                            BoxShadow(
                                color: genderColor.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 10))
                          ],
                          border:
                              Border.all(color: AppColors.surface, width: 3),
                        ),
                        child: Icon(isMale ? Icons.man : Icons.woman,
                            size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      Text(member.name,
                          style: AppTextStyles.headline.copyWith(fontSize: 22)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                    member.currentMonthPaid ? 'Paid' : 'Unpaid',
                                    style: AppTextStyles.label.copyWith(
                                        color: statusColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(member.planName,
                              style: AppTextStyles.bodyMuted
                                  .copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionChip(
                          icon: member.currentMonthPaid
                              ? PhosphorIconsBold.arrowCounterClockwise
                              : PhosphorIconsBold.checkCircle,
                          label: member.currentMonthPaid
                              ? 'Mark Unpaid'
                              : 'Mark Paid',
                          color: member.currentMonthPaid
                              ? AppColors.textSecondary
                              : AppColors.success,
                          filled: !member.currentMonthPaid,
                          onTap: () => _togglePaid(context, member),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CircleAction(
                          icon: PhosphorIconsBold.phone,
                          color: AppColors.textPrimary,
                          onTap: () => WhatsAppService()
                              .callMember(member.whatsappNumber)),
                      const SizedBox(width: AppSpacing.sm),
                      _CircleAction(
                        icon: PhosphorIconsBold.whatsappLogo,
                        color: AppColors.success,
                        onTap: () => member.currentMonthPaid
                            ? WhatsAppService().openChat(member.whatsappNumber)
                            : WhatsAppService().sendReminder(
                                phone: member.whatsappNumber,
                                memberName: member.name,
                                amountDue: member.feeAmount,
                                template: context
                                    .read<SettingsProvider>()
                                    .settings
                                    .reminderTemplate,
                              ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Membership'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            _InfoRow(
                                icon: PhosphorIconsFill.tag,
                                label: 'Plan',
                                value: member.planName),
                            _InfoRow(
                                icon: PhosphorIconsFill.wallet,
                                label: 'Monthly Fee',
                                value:
                                    CurrencyFormatter.format(member.feeAmount)),
                            _InfoRow(
                                icon: PhosphorIconsFill.calendarPlus,
                                label: 'Join Date',
                                value:
                                    AppDateUtils.formatDate(member.joinDate)),
                            _InfoRow(
                                icon: PhosphorIconsFill.calendarCheck,
                                label: 'Next Due',
                                value:
                                    AppDateUtils.formatDate(member.nextDueDate),
                                valueColor:
                                    member.isOverdue ? AppColors.danger : null),
                            _InfoRow(
                                icon: PhosphorIconsFill.checkCircle,
                                label: 'Status',
                                value: member.status == MemberStatus.active
                                    ? 'Active'
                                    : 'Inactive',
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionLabel('Personal Details'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: AppColors.border)),
                        child: Column(
                          children: [
                            _InfoRow(
                                icon: PhosphorIconsFill.cake,
                                label: 'Date of Birth',
                                value: AppDateUtils.formatDate(
                                    member.dateOfBirth)),
                            if (member.cnicNumber.isNotEmpty)
                              _InfoRow(
                                  icon: PhosphorIconsFill.identificationCard,
                                  label: 'CNIC',
                                  value: member.cnicNumber),
                            if (member.profession.isNotEmpty)
                              _InfoRow(
                                  icon: PhosphorIconsFill.briefcase,
                                  label: 'Profession',
                                  value: member.profession),
                            _InfoRow(
                                icon: PhosphorIconsFill.mapPin,
                                label: 'Address',
                                value: member.address.isNotEmpty
                                    ? member.address
                                    : '—',
                                isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButtonOutline(
                        label: member.status == MemberStatus.active
                            ? 'Deactivate Member'
                            : 'Activate Member',
                        icon: PhosphorIconsRegular.userSwitch,
                        onTap: () => _confirmStatusChange(context, member),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _SectionLabel('Payment History'),
                      const SizedBox(height: AppSpacing.sm),
                      StreamBuilder<List<PaymentModel>>(
                        stream: context
                            .read<PaymentProvider>()
                            .paymentsForMember(member.id),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const AppLoadingIndicator();
                          final payments = snapshot.data!;
                          if (payments.isEmpty) {
                            return const EmptyStateView(
                              icon: PhosphorIconsRegular.receipt,
                              title: 'No activity yet',
                              subtitle:
                                  'Payments and status changes for this member appear here',
                              accent: Color(0xFF3B82F6),
                            );
                          }
                          return _PaymentTimeline(payments: payments);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePaid(BuildContext context, MemberModel member) async {
    final memberProvider = context.read<MemberProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(member.currentMonthPaid
            ? 'Mark as Unpaid?'
            : 'Confirm Payment Received'),
        content: Text(
          member.currentMonthPaid
              ? 'This will undo the payment record for ${member.name} this month.'
              : 'Confirm you have received ${CurrencyFormatter.format(member.feeAmount)} from ${member.name}.',
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => context.pop(true),
            child: Text(member.currentMonthPaid ? 'Yes, Undo' : 'Confirm Paid',
                style: TextStyle(
                    color: member.currentMonthPaid
                        ? AppColors.danger
                        : AppColors.success,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (member.currentMonthPaid) {
      await memberProvider.markUnpaid(member.id);
    } else {
      await paymentProvider.recordPayment(
          memberId: member.id,
          memberName: member.name,
          amount: member.feeAmount,
          method: 'cash');
      final planDays =
          member.planDurationDays > 0 ? member.planDurationDays : 30;
      await memberProvider.markPaid(
          memberId: member.id,
          newDueDate: DateTime.now().add(Duration(days: planDays)));
    }
  }

  Future<void> _confirmStatusChange(
      BuildContext context, MemberModel member) async {
    final willActivate = member.status != MemberStatus.active;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(willActivate ? 'Activate Member?' : 'Deactivate Member?'),
        content: Text(
          willActivate
              ? '${member.name} will be marked active and included in payment tracking again.'
              : '${member.name} will be marked inactive and excluded from monthly payment tracking.',
        ),
        actions: [
          TextButton(
              onPressed: () => context.pop(false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => context.pop(true),
              child: Text(willActivate ? 'Activate' : 'Deactivate',
                  style: const TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<MemberProvider>()
          .toggleActiveStatus(member.id, willActivate);
    }
  }

  Future<void> _confirmDelete(BuildContext context, MemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Member'),
        content: Text(
            'Are you sure you want to delete ${member.name}? This cannot be undone.'),
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
      await context.read<MemberProvider>().deleteMember(member.id);
      if (context.mounted) context.pop();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTextStyles.title.copyWith(fontSize: 16)),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.filled,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
              border: filled ? null : Border.all(color: AppColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: filled ? Colors.white : color),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: filled ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleAction(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
                border: Border.all(color: AppColors.border)),
            child: Icon(icon, color: color, size: 21)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor,
      this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Icon(icon, size: 17, color: AppColors.textDisabled),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                  child: Text(label,
                      style: AppTextStyles.bodyMuted.copyWith(fontSize: 14.5))),
              Flexible(
                  child: Text(value,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: valueColor ?? AppColors.textPrimary),
                      textAlign: TextAlign.right)),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
              padding: EdgeInsets.only(left: 44), child: Divider(height: 1)),
      ],
    );
  }
}

class _PaymentTimeline extends StatelessWidget {
  final List<PaymentModel> payments;

  const _PaymentTimeline({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < payments.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: payments[i].isPaid
                              ? AppColors.successBg
                              : AppColors.dangerBg,
                          shape: BoxShape.circle),
                      child: Icon(
                          payments[i].isPaid
                              ? PhosphorIconsFill.checkCircle
                              : PhosphorIconsFill.xCircle,
                          size: 17,
                          color: payments[i].isPaid
                              ? AppColors.success
                              : AppColors.danger),
                    ),
                    if (i < payments.length - 1)
                      Expanded(
                          child: Container(width: 2, color: AppColors.border)),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: i < payments.length - 1 ? AppSpacing.md : 0,
                        top: 2),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md - 2),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm + 2),
                          border: Border.all(color: AppColors.border)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payments[i].isPaid
                                      ? CurrencyFormatter.format(
                                          payments[i].amount)
                                      : 'Marked Unpaid',
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: payments[i].isPaid
                                          ? AppColors.textPrimary
                                          : AppColors.danger),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  payments[i].isPaid
                                      ? '${AppDateUtils.formatDate(payments[i].paidDate)} · ${payments[i].method == PaymentMethod.cash ? 'Cash' : 'Online'}'
                                      : AppDateUtils.formatDate(
                                          payments[i].paidDate),
                                  style: AppTextStyles.bodyMuted
                                      .copyWith(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: payments[i].isPaid
                                    ? AppColors.successBg
                                    : AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(payments[i].isPaid ? 'Paid' : 'Unpaid',
                                style: AppTextStyles.label.copyWith(
                                    color: payments[i].isPaid
                                        ? AppColors.success
                                        : AppColors.danger,
                                    fontSize: 10.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AppButtonOutline extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const AppButtonOutline(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(label,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
