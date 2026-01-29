import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_email():
    sender_email = "python.nexnoratech@gmail.com"
    receiver_email = "python.nexnoratech@gmail.com" # Sending to yourself for testing
    password = "aazm gwze vplo kehg"

    message = MIMEMultipart("alternative")
    message["Subject"] = "Email SMTP Test"
    message["From"] = sender_email
    message["To"] = receiver_email

    text = "If you see this, your SMTP settings are working correctly!"
    part1 = MIMEText(text, "plain")
    message.attach(part1)

    print(f"Attempting to connect to smtp.gmail.com...")
    try:
        # Create a secure SSL context and connect
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls() # Secure the connection
        print("Connected and TLS started.")
        
        server.login(sender_email, password)
        print("Login successful!")
        
        server.sendmail(sender_email, receiver_email, message.as_string())
        print(f"Email sent successfully to {receiver_email}!")
        
        server.quit()
    except Exception as e:
        print(f"\nERROR: {str(e)}")
        print("\nPossible solutions:")
        print("1. Ensure 'Vidhya_Rambh@gmail.com' is correct.")
        print("2. Use a Google 'App Password' instead of your regular password.")
        print("   - Go to Google Account Settings -> Security")
        print("   - Enable 2-Step Verification")
        print("   - Search for 'App Passwords' and generate one for 'Mail'")
        print("   - Use that 16-character code as the password.")

if __name__ == "__main__":
    test_email()
