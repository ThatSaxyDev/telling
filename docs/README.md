# Telling Documentation

Welcome to the Telling project documentation! This folder contains all technical documentation organized by category.

## 📁 Documentation Structure

### Backend Documentation (`backend/`)
Backend implementation guides and API specifications.

- **[events_endpoint_guide.md](backend/events_endpoint_guide.md)** - Implementation guide for the events endpoint used in funnel analysis
- **[auth_change.md](backend/auth_change.md)** - Authentication & 2FA API specification
- **[endpoints_spec.md](backend/endpoints_spec.md)** - Settings features API endpoints specification

### Frontend Documentation (`frontend/`)
Frontend integration guides and UI implementation details.

- **[security_changes.md](frontend/security_changes.md)** - Frontend changes required for backend security hardening (OTP, rate limiting, account lockout)
- **[funnel_guide.md](frontend/funnel_guide.md)** - Funnel analysis implementation guide for frontend

### Integration Documentation (`integration/`)
Cross-platform integration guides and feature documentation.

- **[frontend_integration.md](integration/frontend_integration.md)** - User properties and performance analytics integration
- **[named_funnel_guide.md](integration/named_funnel_guide.md)** - Named funnel analysis integration guide

## 🚀 Quick Links

### For Backend Developers
- Authentication changes: [backend/auth_change.md](backend/auth_change.md)
- API endpoints reference: [backend/endpoints_spec.md](backend/endpoints_spec.md)
- Events endpoint: [backend/events_endpoint_guide.md](backend/events_endpoint_guide.md)

### For Frontend Developers
- Security updates: [frontend/security_changes.md](frontend/security_changes.md)
- Funnel visualization: [frontend/funnel_guide.md](frontend/funnel_guide.md)

### For Full-Stack Features
- User properties & performance: [integration/frontend_integration.md](integration/frontend_integration.md)
- Named funnels: [integration/named_funnel_guide.md](integration/named_funnel_guide.md)

## 📝 Contributing to Documentation

When adding new documentation:
1. Place it in the appropriate category folder (`backend/`, `frontend/`, or `integration/`)
2. Use lowercase with underscores for filenames (e.g., `new_feature_guide.md`)
3. Update this README with a link to your new document
4. Include clear examples and code snippets where applicable
