from smtplib import SMTPException

from flask import current_app
from flask_mail import Message

from extensions import mail


def send_otp_email(to_email: str, otp_code: str, purpose: str) -> bool:
    subject = "SkinIntel — Verify Your Email" if purpose == "verify" else "SkinIntel — Password Reset Code"
    heading = "Verify Your Email" if purpose == "verify" else "Password Reset Code"

    html_body = f"""
    <html>
      <body style="font-family: Arial, sans-serif; background: #f7f7f7; margin: 0; padding: 0;">
        <table width="100%" cellpadding="0" cellspacing="0" style="padding: 20px;">
          <tr>
            <td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="background: #ffffff; border-radius: 12px; padding: 32px;">
                <tr>
                  <td style="text-align: center; padding-bottom: 24px;">
                    <h1 style="margin: 0; color: #333333; font-size: 28px;">SkinIntel</h1>
                    <p style="margin: 8px 0 0; color: #777777; font-size: 16px;">Smart skincare guidance for your unique skin.</p>
                  </td>
                </tr>
                <tr>
                  <td>
                    <h2 style="color: #333333; font-size: 22px;">{heading}</h2>
                    <p style="color: #555555; font-size: 16px; line-height: 1.6;">Use the code below to continue. This code expires in 10 minutes.</p>
                    <div style="margin: 24px 0; padding: 24px; background: #f0f4ff; border-radius: 10px; text-align: center;">
                      <span style="display: inline-block; font-size: 32px; letter-spacing: 4px; font-weight: 700; color: #1a56db;">{otp_code}</span>
                    </div>
                    <p style="color: #555555; font-size: 14px; line-height: 1.6;">If you didn't request this, ignore this email.</p>
                    <p style="color: #999999; font-size: 12px;">Need help? Contact our support team.</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """

    message = Message(subject=subject, recipients=[to_email], html=html_body)

    try:
        mail.send(message)
        return True
    except SMTPException as exc:
        current_app.logger.error("Failed to send OTP email to %s: %s", to_email, exc)
        return False
    except Exception as exc:
        current_app.logger.error("Unexpected error sending OTP email to %s: %s", to_email, exc)
        return False
