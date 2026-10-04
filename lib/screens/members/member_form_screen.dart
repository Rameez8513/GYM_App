import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/input_formatters.dart';
import '../../models/member_model.dart';
import '../../models/plan_model.dart';
import '../../providers/member_provider.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/premium_app_bar.dart';
import '../../widgets/forms/option_selector_field.dart';
import '../../widgets/forms/plan_selector_field.dart';

class MemberFormScreen extends StatefulWidget {
  final String? memberId;

  const MemberFormScreen({super.key, this.memberId});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  int _step = 0;

  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _cnicController = TextEditingController();

  String _profession = '';
  String _address = '';

  DateTime _joinDate = DateTime.now();
  DateTime? _dateOfBirth;
  Gender _gender = Gender.male;
  MemberStatus _status = MemberStatus.active;
  bool _markPaidNow = true;

  String? _selectedPlanId;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => widget.memberId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && _isEditing) {
      final member = context.read<MemberProvider>().getById(widget.memberId!);
      if (member != null) {
        _nameController.text = member.name;
        _whatsappController.text = member.whatsappNumber;
        _cnicController.text = member.cnicNumber;
        _profession = member.profession;
        _address = member.address;
        _joinDate = member.joinDate;
        _dateOfBirth = member.dateOfBirth;
        _gender = member.gender;
        _status = member.status;
        _selectedPlanId = member.planId;
        _markPaidNow = member.currentMonthPaid;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Please enter the member\'s name');
        return false;
      }
      if (_whatsappController.text.trim().length != 11) {
        _showError('WhatsApp number must be 11 digits');
        return false;
      }
    }
    if (step == 1) {
      final cnic = _cnicController.text.replaceAll('-', '').trim();
      if (cnic.length != 13) {
        _showError('CNIC is required (13 digits)');
        return false;
      }
    }
    if (step == 2 && _selectedPlanId == null) {
      _showError('Please select a membership plan');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.danger));
  }

  void _goToStep(int step) {
    setState(() => _step = step);
  }

  void _nextStep() {
    if (!_validateStep(_step)) return;
    if (_step < 2) {
      _goToStep(_step + 1);
    } else {
      _handleSave();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      _goToStep(_step - 1);
    } else {
      context.pop();
    }
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _joinDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (picked != null) setState(() => _joinDate = picked);
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _handleSave() {
    if (_saving || !_validateStep(2)) return;

    final memberProvider = context.read<MemberProvider>();
    final plan = context.read<PlanProvider>().getById(_selectedPlanId!);
    if (plan == null) {
      _showError('Selected plan no longer exists');
      return;
    }

    final enteredName = _nameController.text.trim();
    final duplicate = memberProvider.allMembers.any(
      (m) =>
          m.name.toLowerCase() == enteredName.toLowerCase() &&
          m.id != widget.memberId,
    );
    if (duplicate) {
      _showError('A member with this name already exists');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    _saving = true;

    Future<void> task;
    if (_isEditing) {
      final existing = memberProvider.getById(widget.memberId!);
      if (existing == null) {
        _saving = false;
        return;
      }
      final planChanged = existing.planId != plan.id;
      final recalculatedDueDate = planChanged
          ? AppDateUtils.addPlanDuration(DateTime.now(), plan.durationInDays)
          : existing.nextDueDate;

      task = memberProvider.updateMember(
        existing.copyWith(
          name: enteredName,
          gender: _gender,
          whatsappNumber: _whatsappController.text.trim(),
          dateOfBirth: _dateOfBirth,
          cnicNumber: _cnicController.text.trim(),
          profession: _profession,
          address: _address,
          joinDate: _joinDate,
          planId: plan.id,
          planName: plan.name,
          planDurationDays: plan.durationInDays,
          feeAmount: plan.price,
          status: _status,
          nextDueDate: recalculatedDueDate,
        ),
      );
    } else {
      task = memberProvider.addMember(
        name: enteredName,
        gender: _gender,
        whatsappNumber: _whatsappController.text.trim(),
        dateOfBirth: _dateOfBirth ?? DateTime(2000, 1, 1),
        cnicNumber: _cnicController.text.trim(),
        profession: _profession,
        address: _address,
        joinDate: _joinDate,
        planId: plan.id,
        planName: plan.name,
        feeAmount: plan.price,
        nextDueDate:
            AppDateUtils.addPlanDuration(_joinDate, plan.durationInDays),
        initialStatus: _status,
        initialPaid: _markPaidNow,
      );
    }

    task.catchError((_) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not save member. Check your connection.'),
            backgroundColor: AppColors.danger),
      );
    });

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<PlanProvider>().activePlans;
    final width = MediaQuery.of(context).size.width;
    final formWidth = width > 560 ? 560.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PremiumAppBar(title: _isEditing ? 'Edit Member' : 'Add Member'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: List.generate(3, (index) {
                  final icons = [
                    PhosphorIconsBold.user,
                    PhosphorIconsBold.identificationCard,
                    PhosphorIconsBold.tag
                  ];
                  final isActive = index <= _step;
                  final isCurrent = index == _step;
                  return Expanded(
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: isCurrent ? 30 : 24,
                          height: isCurrent ? 30 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.surfaceAlt,
                            border: isCurrent
                                ? Border.all(
                                    color: AppColors.primaryGlow, width: 2)
                                : null,
                          ),
                          child: Icon(icons[index],
                              size: isCurrent ? 15 : 12,
                              color: isActive
                                  ? AppColors.background
                                  : AppColors.textDisabled),
                        ),
                        if (index < 2)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: index < _step
                                    ? AppColors.primary
                                    : AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ['Basic Info', 'Contact & Details', 'Plan & Status'][_step],
                  style: AppTextStyles.title.copyWith(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                          begin: const Offset(0.06, 0), end: Offset.zero)
                      .animate(animation);
                  return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child));
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _StepScroll(
                    width: formWidth,
                    child: [
                      _buildStepOne(),
                      _buildStepTwo(),
                      _buildStepThree(plans)
                    ][_step],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: formWidth,
                  child: Row(
                    children: [
                      Expanded(
                          child: AppButton(
                              label: _step == 0 ? 'Cancel' : 'Back',
                              onPressed: _prevStep,
                              variant: AppButtonVariant.outline)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                            label: _step < 2
                                ? 'Next'
                                : (_isEditing ? 'Save Changes' : 'Add Member'),
                            onPressed: _nextStep),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
            label: 'Full Name',
            hint: 'e.g. Ali Raza',
            controller: _nameController,
            prefixIcon: PhosphorIconsRegular.user),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'WhatsApp Number (11 digits)',
          hint: '03001234567',
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          prefixIcon: PhosphorIconsBold.whatsappLogo,
          inputFormatters: [PhoneInputFormatter()],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Gender', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ChoiceCard(
                label: 'Male',
                icon: Icons.man,
                selected: _gender == Gender.male,
                onTap: () => setState(() => _gender = Gender.male),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ChoiceCard(
                label: 'Female',
                icon: Icons.woman,
                selected: _gender == Gender.female,
                onTap: () => setState(() => _gender = Gender.female),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateField(
            label: 'Date of Birth',
            value: _dateOfBirth,
            onTap: _pickDateOfBirth),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'CNIC Number (13 digits)',
          hint: '35202-1234567-1',
          controller: _cnicController,
          keyboardType: TextInputType.number,
          prefixIcon: PhosphorIconsRegular.identificationCard,
          inputFormatters: [CnicInputFormatter()],
          validator: (v) {
            final digits = (v ?? '').replaceAll('-', '');
            if (digits.length != 13) return 'CNIC must be 13 digits';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        OptionSelectorField(
          label: 'Profession',
          icon: PhosphorIconsRegular.briefcase,
          options: AppConstants.professions,
          value: _profession,
          onChanged: (value) => setState(() => _profession = value),
        ),
        const SizedBox(height: AppSpacing.lg),
        OptionSelectorField(
          label: 'Address / Area',
          icon: PhosphorIconsRegular.mapPin,
          options: AppConstants.addressAreas,
          value: _address,
          onChanged: (value) => setState(() => _address = value),
        ),
      ],
    );
  }

  Widget _buildStepThree(List<PlanModel> plans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DateField(label: 'Join Date', value: _joinDate, onTap: _pickJoinDate),
        const SizedBox(height: AppSpacing.lg),
        PlanSelectorField(
            plans: plans,
            selectedPlanId: _selectedPlanId,
            onChanged: (plan) => setState(() => _selectedPlanId = plan.id)),
        const SizedBox(height: AppSpacing.lg),
        Text('Membership Status', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _ChoiceCard(
                    label: 'Active',
                    selected: _status == MemberStatus.active,
                    onTap: () =>
                        setState(() => _status = MemberStatus.active))),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _ChoiceCard(
                    label: 'Inactive',
                    selected: _status == MemberStatus.inactive,
                    onTap: () =>
                        setState(() => _status = MemberStatus.inactive))),
          ],
        ),
        if (!_isEditing) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Payment Status', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: _ChoiceCard(
                      label: 'Paid',
                      selected: _markPaidNow,
                      isPaidChip: true,
                      onTap: () => setState(() => _markPaidNow = true))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _ChoiceCard(
                      label: 'Unpaid',
                      selected: !_markPaidNow,
                      onTap: () => setState(() => _markPaidNow = false))),
            ],
          ),
        ],
      ],
    );
  }
}

class _StepScroll extends StatelessWidget {
  final double width;
  final Widget child;

  const _StepScroll({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Center(child: SizedBox(width: width, child: child)),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool isPaidChip;
  final VoidCallback onTap;

  const _ChoiceCard(
      {required this.label,
      this.icon,
      required this.selected,
      this.isPaidChip = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = isPaidChip ? AppColors.infoBlue : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color:
              selected ? accent.withValues(alpha: 0.14) : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 2 : 1),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 20,
                    color: selected ? accent : AppColors.textSecondary),
                const SizedBox(width: 8)
              ],
              Text(label,
                  style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? AppDateUtils.formatDate(value!)
                        : 'Select date',
                    style: value != null
                        ? AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600)
                        : AppTextStyles.bodyMuted.copyWith(fontSize: 13.5),
                  ),
                ),
                const Icon(PhosphorIconsRegular.calendar,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
