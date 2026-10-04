import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/plan_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/premium_app_bar.dart';

class _Preset {
  final String label;
  final int days;
  const _Preset(this.label, this.days);
}

const List<_Preset> _presets = [
  _Preset('Monthly', 30),
  _Preset('3 Months', 90),
  _Preset('6 Months', 180),
  _Preset('Yearly', 365),
];

class PlanFormScreen extends StatefulWidget {
  final String? planId;

  const PlanFormScreen({super.key, this.planId});

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _daysController = TextEditingController();

  int _selected = 0;
  bool _nameEdited = false;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => widget.planId != null;
  bool get _isCustom => _selected == _presets.length;

  int get _days {
    if (_isCustom) return int.tryParse(_daysController.text.trim()) ?? 0;
    return _presets[_selected].days;
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = _presets[0].label;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized && _isEditing) {
      final plan = context.read<PlanProvider>().getById(widget.planId!);
      if (plan != null) {
        _nameController.text = plan.name;
        _priceController.text = plan.price.toStringAsFixed(0);
        _nameEdited = true;
        final index = _presets.indexWhere((p) => p.days == plan.durationInDays);
        if (index >= 0) {
          _selected = index;
        } else {
          _selected = _presets.length;
          _daysController.text = plan.durationInDays.toString();
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  String _durationLabel(int days) {
    final index = _presets.indexWhere((p) => p.days == days);
    if (index >= 0) return '${_presets[index].label} · $days days';
    return days > 0 ? '$days days' : 'Set duration';
  }

  void _selectPreset(int index) {
    setState(() {
      _selected = index;
      if (index < _presets.length && !_nameEdited) {
        _nameController.text = _presets[index].label;
      }
    });
  }

  void _handleSave() {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid number of days'),
            backgroundColor: AppColors.primary),
      );
      return;
    }

    final provider = context.read<PlanProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    _saving = true;

    Future<void> task;
    if (_isEditing) {
      final existing = provider.getById(widget.planId!);
      if (existing == null) {
        _saving = false;
        return;
      }
      task = provider.updatePlan(
          existing.copyWith(name: name, price: price, durationInDays: _days));
    } else {
      task =
          provider.createPlan(name: name, price: price, durationInDays: _days);
    }

    task.catchError((_) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not save plan. Check your connection.'),
            backgroundColor: AppColors.primary),
      );
    });

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final formWidth = width > 520 ? 480.0 : double.infinity;
    final price = double.tryParse(_priceController.text.trim()) ?? 0;

    return Scaffold(
      appBar: PremiumAppBar(title: _isEditing ? 'Edit Plan' : 'New Plan'),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: formWidth,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(PhosphorIconsFill.tag,
                                        color: Colors.white70, size: 18),
                                    const SizedBox(width: 6),
                                    Text('PLAN PREVIEW',
                                        style: AppTextStyles.label.copyWith(
                                            color: Colors.white70,
                                            letterSpacing: 1.2)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  _nameController.text.trim().isEmpty
                                      ? 'Plan name'
                                      : _nameController.text.trim(),
                                  style: AppTextStyles.title.copyWith(
                                      color: Colors.white, fontSize: 22),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(price),
                                  style: AppTextStyles.displayLarge.copyWith(
                                      color: Colors.white, fontSize: 34),
                                ),
                                const SizedBox(height: 4),
                                Text(_durationLabel(_days),
                                    style: AppTextStyles.body
                                        .copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text('Duration', style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (int i = 0; i < _presets.length; i++)
                                _DurationChip(
                                    label: _presets[i].label,
                                    selected: _selected == i,
                                    onTap: () => _selectPreset(i)),
                              _DurationChip(
                                  label: 'Custom',
                                  selected: _isCustom,
                                  onTap: () => _selectPreset(_presets.length)),
                            ],
                          ),
                          if (_isCustom) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Number of days',
                              hint: 'e.g. 45',
                              controller: _daysController,
                              keyboardType: TextInputType.number,
                              prefixIcon: PhosphorIconsRegular.clockCountdown,
                              onChanged: (_) => setState(() {}),
                              validator: (v) {
                                if (!_isCustom) return null;
                                final days = int.tryParse((v ?? '').trim());
                                return (days == null || days <= 0)
                                    ? 'Enter a valid number of days'
                                    : null;
                              },
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Plan Name',
                            hint: 'e.g. Monthly',
                            controller: _nameController,
                            prefixIcon: PhosphorIconsRegular.tag,
                            onChanged: (_) =>
                                setState(() => _nameEdited = true),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Price (PKR)',
                            hint: 'e.g. 3000',
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            prefixIcon: PhosphorIconsRegular.money,
                            onChanged: (_) => setState(() {}),
                            validator: (v) {
                              final value = double.tryParse((v ?? '').trim());
                              return (value == null || value <= 0)
                                  ? 'Enter a valid price'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppButton(
                      label: _isEditing ? 'Save Changes' : 'Create Plan',
                      onPressed: _handleSave,
                      fullWidth: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md + 2, vertical: AppSpacing.md - 2),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.16)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
