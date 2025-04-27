import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<void> openWhatsApp(String phoneNumber) async {
    String phone = phoneNumber.replaceAll(' ', '').replaceAll('+', '');

    if (!phone.startsWith('91') && phone.length == 10) {
      phone = '91$phone';
    }

    final Uri whatsapp = Uri.parse("whatsapp://send?phone=$phone");

    if (await canLaunchUrl(whatsapp)) {
      await launchUrl(whatsapp, mode: LaunchMode.externalApplication);
    } else {
      // fallback to wa.me link if whatsapp:// not working
      final Uri fallbackWhatsapp = Uri.parse("https://wa.me/$phone");
      if (await canLaunchUrl(fallbackWhatsapp)) {
        await launchUrl(fallbackWhatsapp, mode: LaunchMode.externalApplication);
      } else {
        // WhatsApp not installed
        throw Exception('WhatsApp is not installed');
      }
    }
  }
}
