Authentication & 2FA API Specification
Overview
The authentication flow has changed to enforce Two-Factor Authentication (2FA) for BOTH Sign Up and Login. The 
login
 and 
register
 endpoints NO LONGER return an authentication token. instead, they trigger an OTP email. The client must verify the OTP to receive the JWT.

Endpoints
1. Register
POST /api/v1/auth/register

Request Body:

{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe"
}
Response (200 OK):

{
  "message": "OTP sent to email",
  "userId": "uuid-string",
  "email": "user@example.com"
}
Note: Does NOT return an auth token. Client should redirect user to the OTP entry screen.

2. Login
POST /api/v1/auth/login

Request Body:

{
  "email": "user@example.com",
  "password": "securePassword123"
}
Response (200 OK):

{
  "message": "OTP sent to email",
  "userId": "uuid-string",
  "email": "user@example.com"
}
3. Verify OTP (Get Token)
POST /api/v1/auth/verify

Request Body:

{
  "userId": "uuid-string",
  "otp": "123456"
}
Response (200 OK):

{
  "token": "jwt.token.string",
  "user": {
    "id": "uuid-string",
    "email": "user@example.com",
    "name": "John Doe"
  }
}
Note: Successful verification returns the JWT, effectively logging the user in immediately.

Response (400 Bad Request):

Invalid OTP
Expired OTP
4. Resend OTP
POST /api/v1/auth/resend-otp

Request Body:

{
  "userId": "uuid-string"
}
Response (200 OK):

{
  "message": "OTP resent"
}