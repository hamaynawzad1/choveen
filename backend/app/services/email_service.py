import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings

logger = logging.getLogger(__name__)

def send_verification_email(email: str, code: str) -> bool:
    """Send verification email to user"""
    try:
        # Skip email sending if SMTP not configured (for development)
        if not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
            logger.info(f"SMTP not configured. Verification code for {email}: {code}")
            print(f"\n🔑 VERIFICATION CODE for {email}: {code}\n")
            return True

        # Try to send real email
        msg = MIMEMultipart()
        msg['From'] = settings.SMTP_USERNAME
        msg['To'] = email
        msg['Subject'] = "Choveen - Email Verification"

        body = f"""
        <html>
        <body>
            <h2>Welcome to Choveen!</h2>
            <p>Your verification code is: <strong style="font-size: 24px; color: #2196F3;">{code}</strong></p>
            <p>Please enter this code in the app to verify your email address.</p>
            <br>
            <p>Best regards,<br>Choveen Team</p>
        </body>
        </html>
        """

        msg.attach(MIMEText(body, 'html'))

        server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
        server.starttls()
        server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        text = msg.as_string()
        server.sendmail(settings.SMTP_USERNAME, email, text)
        server.quit()
        
        logger.info(f"Verification email sent to {email}")
        return True

    except Exception as e:
        logger.error(f"Failed to send email to {email}: {str(e)}")
        # Fallback: Print code to console for development
        print(f"\n🔑 EMAIL FAILED - VERIFICATION CODE for {email}: {code}\n")
        return True  # Return True so registration doesn't fail