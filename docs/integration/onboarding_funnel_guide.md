# Onboarding Funnel Tracking Guide

This guide documents the implementation of the user onboarding funnel tracking in the Telling application. The funnel tracks a user's journey from their first visit to the landing page through to reaching the main dashboard (Overview screen).

## Overview

The onboarding funnel (`user_onboarding`) consists of **9 sequential steps** that measure conversion from initial landing to successful dashboard access.

```
Landing → Get Started → Register → Submit → OTP → Verify → Projects → Select → Overview
   1          2            3          4       5       6        7         8        9
```

## Funnel Steps

| Step | Constant | Description | Properties |
|------|----------|-------------|------------|
| 1 | `landingViewed` | User lands on the welcome/landing screen | - |
| 2 | `getStartedClicked` | User clicks to begin registration | `source`: button location |
| 3 | `registerViewed` | User views the registration form | - |
| 4 | `registerSubmitted` | User submits registration details | `method`: 'email' |
| 5 | `otpVerificationViewed` | User sees OTP verification screen | - |
| 6 | `otpVerified` | User successfully verifies email via OTP | - |
| 7 | `projectsViewed` | User reaches project selection screen | - |
| 8 | `projectSelected` | User selects/enters a project | `project_name`: selected project |
| 9 | `overviewReached` | User reaches the dashboard (**Conversion!**) | - |

## Implementation Details

### Constants

All funnel constants are defined in `lib/core/constants/funnel_constants.dart`:

```dart
class FunnelConstants {
  // Onboarding Funnel (Landing → Overview)
  static const String onboardingFunnel = 'user_onboarding';
  static const String landingViewed = 'landing_viewed';
  static const String getStartedClicked = 'get_started_clicked';
  static const String registerViewed = 'register_viewed';
  static const String registerSubmitted = 'register_submitted';
  static const String otpVerificationViewed = 'otp_verification_viewed';
  static const String otpVerified = 'otp_verified';
  static const String projectsViewed = 'projects_viewed';
  static const String projectSelected = 'project_selected';
  static const String overviewReached = 'overview_reached';
}
```

### Screen Implementations

#### Step 1: Landing Screen (`landing_screen.dart`)

Tracked in `initState()` when the landing screen loads:

```dart
@override
void initState() {
  super.initState();
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.landingViewed,
    step: 1,
  );
}
```

#### Step 2: Get Started Clicked (`landing_screen.dart`)

Tracked when user clicks "REQUEST_CLEARANCE" button to navigate to register:

```dart
onPressed: () {
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.getStartedClicked,
    step: 2,
    properties: {'source': 'landing_cta'},
  );
  context.go('/register');
}
```

#### Step 3: Register Screen Viewed (`register_screen.dart`)

Tracked in `initState()` when the registration screen loads:

```dart
@override
void initState() {
  super.initState();
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.registerViewed,
    step: 3,
  );
}
```

#### Step 4: Registration Submitted (`register_screen.dart`)

Tracked when user submits the registration form:

```dart
Future<void> _register() async {
  if (_formKey.currentState!.validate()) {
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.registerSubmitted,
      step: 4,
      properties: {'method': 'email'},
    );
    // ... registration logic
  }
}
```

#### Step 5: OTP Verification Screen (`otp_verification_screen.dart`)

Tracked in `initState()` when the OTP screen loads:

```dart
@override
void initState() {
  super.initState();
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.otpVerificationViewed,
    step: 5,
  );
}
```

#### Step 6: OTP Verified (`otp_verification_screen.dart`)

Tracked after successful OTP verification:

```dart
if (success && mounted) {
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.otpVerified,
    step: 6,
  );
  context.go('/projects');
}
```

#### Step 7: Projects Screen Viewed (`projects_screen.dart`)

Tracked in `initState()` when the projects screen loads:

```dart
@override
void initState() {
  super.initState();
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.projectsViewed,
    step: 7,
  );
}
```

#### Step 8: Project Selected (`projects_screen.dart`)

Tracked when user clicks "ENTER SYSTEM" on a project:

```dart
onPressed: () {
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.projectSelected,
    step: 8,
    properties: {'project_name': project['name'] ?? 'unknown'},
  );
  ref.read(projectProvider.notifier).selectProject(project);
  context.go('/');
}
```

#### Step 9: Overview Reached (`overview_screen.dart`)

Tracked in `initState()` when the dashboard/overview screen loads:

```dart
@override
void initState() {
  super.initState();
  Telling.instance.trackFunnel(
    funnelName: FunnelConstants.onboardingFunnel,
    stepName: FunnelConstants.overviewReached,
    step: 9,
  );
}
```

## Analytics & Insights

### Key Metrics to Monitor

1. **Overall Conversion Rate**: `Step 9 / Step 1` - What percentage of landing visitors complete onboarding?
2. **Registration Drop-off**: `Step 3 / Step 2` - Are users abandoning at the registration form?
3. **OTP Completion Rate**: `Step 6 / Step 5` - Are users having trouble with email verification?
4. **Project Selection Rate**: `Step 8 / Step 7` - Are users confused at project selection?

### Common Drop-off Points

| Drop-off Point | Possible Causes | Suggested Actions |
|----------------|-----------------|-------------------|
| Step 1 → 2 | Unclear value proposition | Improve landing page copy, add social proof |
| Step 3 → 4 | Complex registration form | Simplify form, add progress indicator |
| Step 5 → 6 | OTP delivery issues | Check email deliverability, add resend option |
| Step 7 → 8 | Confusion about projects | Add onboarding tooltip, create default project |

## Viewing Funnel Data

Navigate to the **Funnel Analysis** screen in the Telling dashboard and select `user_onboarding` from the funnel name dropdown to visualize:

- Step-by-step conversion rates
- Drop-off percentages between steps
- Time-based funnel performance trends

## Best Practices

1. **Don't modify step numbers** - Changing step numbers will break historical comparisons
2. **Keep funnel name consistent** - Always use `FunnelConstants.onboardingFunnel`
3. **Add properties for context** - Include relevant metadata to help diagnose issues
4. **Track after action confirmation** - Ensure the step is tracked after the action succeeds

## Files Modified

| File | Steps Tracked |
|------|---------------|
| `lib/core/constants/funnel_constants.dart` | Constants definition |
| `lib/features/auth/landing_screen.dart` | Steps 1, 2 |
| `lib/features/auth/register_screen.dart` | Steps 3, 4 |
| `lib/features/auth/otp_verification_screen.dart` | Steps 5, 6 |
| `lib/features/projects/projects_screen.dart` | Steps 7, 8 |
| `lib/features/overview/overview_screen.dart` | Step 9 |
