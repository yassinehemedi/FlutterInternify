import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/contract_model.dart';

/// Contract Email Notification Service using Brevo SMTP
/// Sends email notifications when new contracts are created
class ContractEmailService {
  // Brevo SMTP Configuration (same as your EmailService)
  static const String _smtpHost = 'smtp-relay.brevo.com';
  static const int _smtpPort = 587;
  static const String _smtpUsername = '996b2d001@smtp-brevo.com';
  static const String _smtpPassword = 'AZy5vzX8gCYxtDJM';

  // Your verified sender email
  static const String _senderEmail = 'yassinehemedi6@gmail.com';
  static const String _senderName = 'Internify Contract System';

  // Static recipient for all contract notifications
  static const String _notificationRecipient = 'yassinehemedi2@gmail.com';
  static const String _notificationRecipientName = 'yassine';

  /// Send new contract creation notification
  static Future<bool> sendNewContractNotification({
    required Contract contract,
    required String creatorName,
    required String creatorRole,
  }) async {
    try {
      // Configure SMTP server
      final smtpServer = SmtpServer(
        _smtpHost,
        port: _smtpPort,
        username: _smtpUsername,
        password: _smtpPassword,
        ssl: false, // TLS is used instead
        allowInsecure: false,
      );

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(_notificationRecipient)
        ..subject = '📄 New Contract Created - ${contract.title ?? "Contract #${contract.id}"}'
        ..text = '''
New Contract Created

Contract ID: ${contract.id}
Title: ${contract.title ?? 'Untitled Contract'}
Type: ${contract.contractType ?? 'Not specified'}
Status: ${contract.status}
Start Date: ${contract.startDate}
End Date: ${contract.endDate}
Created by: $creatorName ($creatorRole)

Description: ${contract.description ?? 'No description provided'}

Job Seeker ID: ${contract.jobSeekerId}
Enterprise ID: ${contract.enterpriseId}

Please review this contract in the Internify system.
        '''
        ..html = _getNewContractEmailTemplate(
          contract: contract,
          creatorName: creatorName,
          creatorRole: creatorRole,
        );

      // Send the email
      final sendReport = await send(message, smtpServer);

      print('✅ New contract notification sent successfully to $_notificationRecipient');
      print('Response: ${sendReport.toString()}');
      return true;

    } on MailerException catch (e) {
      print('❌ Failed to send contract notification: ${e.message}');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('❌ Error sending contract notification: $e');
      return false;
    }
  }

  /// HTML email template for new contract notification
  static String _getNewContractEmailTemplate({
    required Contract contract,
    required String creatorName,
    required String creatorRole,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background-color: #f5f7fa;
            padding: 20px;
        }
        .email-wrapper {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            font-size: 32px;
            margin-bottom: 10px;
            font-weight: 700;
        }
        .header p {
            font-size: 16px;
            opacity: 0.9;
        }
        .content {
            padding: 40px 30px;
        }
        .greeting {
            font-size: 18px;
            margin-bottom: 20px;
            color: #333;
        }
        .message {
            color: #666;
            margin-bottom: 25px;
            line-height: 1.8;
        }
        .contract-card {
            background: linear-gradient(135deg, #f0f4f8 0%, #e8f4f8 100%);
            border: 2px solid #667eea;
            border-radius: 12px;
            padding: 25px;
            margin: 25px 0;
        }
        .contract-id {
            font-size: 14px;
            color: #667eea;
            font-weight: 600;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .contract-title {
            font-size: 24px;
            font-weight: bold;
            color: #333;
            margin-bottom: 15px;
        }
        .status-badge {
            display: inline-block;
            background: #fbbf24;
            color: #78350f;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            font-weight: bold;
            margin-bottom: 20px;
        }
        .detail-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-top: 20px;
        }
        .detail-item {
            background: white;
            padding: 15px;
            border-radius: 8px;
            border-left: 3px solid #667eea;
        }
        .detail-label {
            font-size: 12px;
            color: #666;
            margin-bottom: 5px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .detail-value {
            font-size: 16px;
            font-weight: 600;
            color: #333;
        }
        .description-box {
            background: white;
            border: 1px dashed #667eea;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .description-label {
            font-size: 12px;
            color: #667eea;
            font-weight: 600;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .description-text {
            color: #555;
            line-height: 1.6;
        }
        .creator-info {
            background: #f9fafb;
            border-left: 4px solid #10b981;
            padding: 15px 20px;
            margin: 20px 0;
            border-radius: 6px;
        }
        .creator-info strong {
            color: #10b981;
        }
        .action-button {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 14px 30px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            margin: 20px 0;
            text-align: center;
        }
        .footer {
            background-color: #f5f7fa;
            padding: 30px;
            text-align: center;
            border-top: 1px solid #e0e0e0;
        }
        .footer p {
            font-size: 13px;
            color: #666;
            margin: 5px 0;
        }
        @media only screen and (max-width: 600px) {
            .detail-grid {
                grid-template-columns: 1fr;
            }
            .header h1 {
                font-size: 24px;
            }
            .contract-title {
                font-size: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="email-wrapper">
        <div class="header">
            <h1>📄 New Contract Created</h1>
            <p>Internify Contract Management System</p>
        </div>
        
        <div class="content">
            <div class="greeting">
                Dear <strong>$_notificationRecipientName</strong>,
            </div>
            
            <div class="message">
                <p>A new contract has been created in the Internify system and requires your attention.</p>
            </div>
            
            <div class="contract-card">
                <div class="contract-id">Contract #${contract.id}</div>
                <div class="contract-title">${contract.title ?? 'Untitled Contract'}</div>
                <span class="status-badge">⏳ ${contract.status}</span>
                
                <div class="detail-grid">
                    ${contract.contractType != null ? '''
                    <div class="detail-item">
                        <div class="detail-label">Contract Type</div>
                        <div class="detail-value">${contract.contractType}</div>
                    </div>
                    ''' : ''}
                    
                    <div class="detail-item">
                        <div class="detail-label">Start Date</div>
                        <div class="detail-value">📅 ${contract.startDate}</div>
                    </div>
                    
                    <div class="detail-item">
                        <div class="detail-label">End Date</div>
                        <div class="detail-value">📅 ${contract.endDate}</div>
                    </div>
                    
                    <div class="detail-item">
                        <div class="detail-label">Job Seeker ID</div>
                        <div class="detail-value">👤 ${contract.jobSeekerId}</div>
                    </div>
                    
                    <div class="detail-item">
                        <div class="detail-label">Enterprise ID</div>
                        <div class="detail-value">🏢 ${contract.enterpriseId}</div>
                    </div>
                </div>
            </div>
            
            ${contract.description != null && contract.description!.isNotEmpty ? '''
            <div class="description-box">
                <div class="description-label">📝 Description</div>
                <div class="description-text">${contract.description}</div>
            </div>
            ''' : ''}
            
            <div class="creator-info">
                <strong>👤 Created by:</strong> $creatorName 
                <span style="color: #666;">(${creatorRole == 'enterprise' ? 'Enterprise' : 'Job Seeker'})</span>
                <br>
                <strong>🕐 Created at:</strong> ${DateTime.now().toString().split('.')[0]}
            </div>
            
            <div class="message" style="margin-top: 30px;">
                <p><strong>Next Steps:</strong></p>
                <ul style="margin-left: 20px; color: #555; margin-top: 10px;">
                    <li>Review the contract details in the Internify admin panel</li>
                    <li>Verify all information is correct</li>
                    <li>Monitor the contract status for signatures</li>
                    <li>Download and archive the contract PDF if needed</li>
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p><strong>© ${DateTime.now().year} Internify. All rights reserved.</strong></p>
            <p>This is an automated notification from Internify Contract Management System.</p>
            <p>Please do not reply to this email.</p>
        </div>
    </div>
</body>
</html>
    ''';
  }

  /// Check if email service is configured
  static bool isConfigured() {
    return _smtpUsername.isNotEmpty &&
        _smtpPassword.isNotEmpty &&
        _senderEmail.isNotEmpty;
  }
}