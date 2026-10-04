import 'package:url_launcher/url_launcher.dart';
import '../core/utils/currency_formatter.dart';
import '../models/gym_settings_model.dart';

class WhatsAppService {
  Future<bool> sendReminder({
    required String phone,
    required String memberName,
    required double amountDue,
    String? template,
  }) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final base = (template != null && template.trim().isNotEmpty)
        ? template
        : GymSettingsModel.defaultReminderTemplate;
    final filled = base
        .replaceAll('{name}', memberName)
        .replaceAll('{amount}', CurrencyFormatter.format(amountDue));
    final message = Uri.encodeComponent(filled);
    final uri = Uri.parse('https://wa.me/$cleanedPhone?text=$message');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> callMember(String phone) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:+$cleanedPhone');
    return launchUrl(uri);
  }

  Future<bool> openChat(String phone) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanedPhone');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
