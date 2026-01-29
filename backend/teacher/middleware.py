from urllib.parse import parse_qs
from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import UntypedToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from django.contrib.auth.models import AnonymousUser
from django.db import close_old_connections

User = get_user_model()


class JWTAuthMiddleware(BaseMiddleware):
    """
    Custom middleware to authenticate WebSocket connections using JWT tokens.
    Token can be passed as a query parameter or in the Authorization header.
    """
    
    async def __call__(self, scope, receive, send):
        # Close old database connections
        close_old_connections()
        
        # Get token from query string or headers
        token = None
        
        # Try to get token from query string
        query_string = scope.get('query_string', b'').decode()
        if query_string:
            query_params = parse_qs(query_string)
            token = query_params.get('token', [None])[0]
        
        # If not in query string, try Authorization header
        if not token:
            headers = dict(scope.get('headers', []))
            auth_header = headers.get(b'authorization', b'').decode()
            if auth_header.startswith('Bearer '):
                token = auth_header[7:]  # Remove 'Bearer ' prefix
        
        # Authenticate user with token
        if token:
            try:
                # Validate token
                UntypedToken(token)
                # Get user from token
                user = await self.get_user_from_token(token)
                scope['user'] = user
            except (InvalidToken, TokenError, Exception) as e:
                # If token is invalid, set anonymous user
                scope['user'] = AnonymousUser()
        else:
            # No token provided, set anonymous user
            scope['user'] = AnonymousUser()
        
        return await super().__call__(scope, receive, send)
    
    @database_sync_to_async
    def get_user_from_token(self, token):
        """Get user from JWT token"""
        from rest_framework_simplejwt.tokens import UntypedToken
        from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
        from django.contrib.auth import get_user_model
        
        try:
            # Decode token
            validated_token = UntypedToken(token)
            # Get user_id from token
            user_id = validated_token['user_id']
            # Get user
            user = User.objects.get(user_id=user_id)
            return user
        except (InvalidToken, TokenError, User.DoesNotExist, KeyError):
            return AnonymousUser()

