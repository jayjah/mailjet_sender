import 'package:mailjet_sender/mailjet_sender.dart';
import 'package:test/test.dart';

void main() async {
  EmailService emailService;

  setUp(() {
    emailService = EmailService.instance()..setUp('', '', '', '');
  });

  tearDown(() {
    emailService.dispose();
  });

  group('[EmailService]', () {
    test('[EmailService] message to email', () async {
      final result = await emailService.sendEmail(
          'movementfam.app@gmail.com', 'test 1',
          content: 'test message');
      expect(result, true);
    });

    test('[EmailService] html email', () async {
      final result = await emailService.sendEmail(
          'movementfam.app@gmail.com', 'test 1',
          content: 'test html message',
          htmlContent: '<h3>Test</h3><p> schön oder? </p>');
      expect(result, true);
    });

    test('[EmailService] Send error report email', () async {
      final result = await emailService.sendErrorReportEmail(
        'Test error',
        'Stacktrace: test',
      );
      expect(result, true);
    });
  });
}
