import 'dart:convert';

import 'package:http/http.dart' as http;

/// EmailService class as singleton
/// Provides functionality to send emails
/// It depends on mailjet api [https://app.mailjet.com]
/// WARNING
///   [EmailService.setUp] must be called before [EmailService.instance] is accessible
///   otherwise it throws a [EmailError]
class EmailService extends Service {
  EmailService._internal();
  factory EmailService.instance() => _currentInstance;
  static const String _path = 'https://api.mailjet.com/v3.1/send';
  static final http.Client _client = http.Client();
  static final EmailService _currentInstance = EmailService._internal();
  static String _tag;

  void setUp(String mailjetPriv, String mailjetPub, String fromMail,
      String fromErrorMail,
      {String tag = 'Email_Service'}) {
    _initialized = false;
    _tag = tag;
    _mailjetPrivate = mailjetPriv;
    _mailjetPublic = mailjetPub;
    _fromErrorMail = fromErrorMail;
    _fromMail = fromMail;
  }

  bool _initialized = false;
  String _mailjetPrivate;
  String _mailjetPublic;
  String _fromMail;
  String _fromErrorMail;
  String get _emailToken =>
      base64Encode(utf8.encode('$_mailjetPrivate:$_mailjetPublic'));

  Map<String, String> get _headers => <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_emailToken'
      };

  Future<bool> sendEmail(String email, String subject,
      {String content, String htmlContent, String name}) async {
    _checkForCorrectSetUp();

    final response = await _client?.post(
      _path,
      headers: _headers,
      body: _encodeBody(_fromMail, _tag, email, name ?? '', subject,
          textPart: content ?? '', htmlPart: htmlContent ?? ''),
    );
    logMessage(
        'EmailService', 'sendEmail', 'mailjet response: ${response?.body}');

    return _handleResultOfMailService(response);
  }

  Future<bool> sendErrorReportEmail(
      String errorName, String errorMessage) async {
    _checkForCorrectSetUp();

    final response = await _client?.post(
      _path,
      headers: _headers,
      body: _encodeBody(_fromErrorMail, _tag, _fromMail, '',
          'Project dart_backend Error: $errorName',
          textPart: errorMessage ?? 'no error message transmitted',
          htmlPart: '',
          customId: 'ErrorReport'),
    );
    logMessage('EmailService', 'sendErrorReportEmail',
        'mailjet response: ${response?.body}');

    return _handleResultOfMailService(response);
  }

  void _checkForCorrectSetUp() {
    if (!_initialized) {
      throw const EmailError(
          "First call 'EmailService.setUp()'! \n"
          ' EmailService was not initialized!',
          trace: ServiceStackTrace('EmailService.instance()'));
    }
  }

  bool _handleResultOfMailService(http.Response response) {
    if (response == null) {
      return false;
    }

    if (response.statusCode < 300) {
      return true;
    } else if (response.statusCode == 401) {
      const e = EmailError('EmailService -- API KEY FAILURE',
          trace: ServiceStackTrace('EmailService.instance()'));

      logError(
          'EmailService',
          '_handleResultOfMailService API KEY FAILURE Response: ${response.body} $e',
          e);
      throw e;
    }
    return false;
  }

  String _encodeBody(String fromEmail, String fromName, String toEmail,
          String toName, String subject,
          {String textPart = '', String htmlPart = '', String customId = ''}) =>
      jsonEncode(
        <String, dynamic>{
          'Messages': [
            <String, dynamic>{
              'From': {'Email': fromEmail, 'Name': fromName},
              'To': [
                {'Email': toEmail, 'Name': toName}
              ],
              'Subject': subject,
              'TextPart': textPart,
              'HTMLPart': htmlPart,
              'CustomID': customId
            },
          ]
        },
      );

  @override
  void dispose() {
    _client?.close();
  }
}

abstract class Service {
  void logError(String s1, String s2, dynamic e) {
    print('ERROR - $s1 $s2 $e');
  }

  void logMessage(String s1, String s2, String s3) {
    print(' :: Email-Service-Log :: $s1 $s2 $s3 ');
  }

  void dispose();
}

class ServiceStackTrace implements StackTrace {
  const ServiceStackTrace(this.trace);
  final String trace;
}

class EmailError implements Error {
  const EmailError(this.error, {this.trace = const ServiceStackTrace('')});
  final String error;
  final ServiceStackTrace trace;
  @override
  StackTrace get stackTrace => trace;
}
