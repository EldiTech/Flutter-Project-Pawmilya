import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class EmailService {
  static final EmailService instance = EmailService._();

  EmailService._();

  // -------------------------------------------------------------
  // EmailJS credentials
  // -------------------------------------------------------------
  static const String _serviceId = 'service_w7fxpno';
  static const String _templateId = 'template_abkw8jb';
  static const String _publicKey = 'BgFDixP-W6iS-lgiO';

  /// Sends an actual email using the EmailJS REST API.
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    log('----------------------------------------------------');
    log('Attempting to send email to: $to');
    log('Subject: $subject');
    
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': to,
            'subject': subject,
            'message': message,
          }
        }),
      );

      if (response.statusCode == 200) {
        log('✅ EMAIL SENT SUCCESSFULLY!');
      } else {
        log('❌ FAILED TO SEND EMAIL.');
        log('Status Code: ${response.statusCode}');
        log('Body: ${response.body}');
      }
    } catch (e) {
      log('❌ ERROR SENDING EMAIL: $e');
    }
    log('----------------------------------------------------');
  }
}

