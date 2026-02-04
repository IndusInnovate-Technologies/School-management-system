"""
Firebase Cloud Messaging (FCM) helpers for push notifications.
Uses firebase-admin to send to FCM HTTP v1.
"""
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

_firebase_app = None


def get_firebase_app():
    """Lazy-initialize Firebase Admin SDK. Returns None if credentials not configured."""
    global _firebase_app
    if _firebase_app is not None:
        return _firebase_app
    try:
        import firebase_admin
        from firebase_admin import credentials
        cred_path = getattr(settings, 'FIREBASE_CREDENTIALS_PATH', None)
        if not cred_path:
            logger.warning('FIREBASE_CREDENTIALS_PATH not set; push notifications disabled')
            return None
        cred = credentials.Certificate(cred_path)
        _firebase_app = firebase_admin.initialize_app(cred)
        return _firebase_app
    except Exception as e:
        logger.warning('Firebase Admin init failed: %s', e)
        return None


def send_fcm_to_tokens(tokens, title, body, data=None):
    """
    Send FCM notification to a list of registration tokens.
    tokens: list of FCM token strings
    title: notification title
    body: notification body
    data: optional dict of string key-value data payload
    """
    if not tokens:
        return
    app = get_firebase_app()
    if not app:
        return
    try:
        from firebase_admin import messaging
        if data is None:
            data = {}
        # FCM data payload must be string key-value
        data_str = {k: str(v) for k, v in data.items()}
        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data=data_str,
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)
        logger.info('FCM sent: success=%s failure=%s', response.success_count, response.failure_count)
        for idx, send_response in enumerate(response.responses):
            if not send_response.success:
                logger.warning('FCM send failed for token %s: %s', tokens[idx][:20] + '...', send_response.exception)
    except Exception as e:
        logger.exception('FCM send failed: %s', e)
