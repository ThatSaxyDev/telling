class FunnelConstants {
  // Auth Funnel
  static const String authFunnel = 'auth_flow';
  static const String loginViewed = 'login_viewed';
  static const String loginSubmitted = 'login_submitted';
  static const String loginSuccess = 'login_success';

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

  // Project Creation Funnel
  static const String projectCreationFunnel = 'project_creation_flow';
  static const String projectsScreenViewed = 'projects_screen_viewed';
  static const String createProjectClicked = 'create_project_clicked';
  static const String createProjectSubmitted = 'create_project_submitted';
  static const String projectCreated = 'project_created';

  // Funnel Analysis Usage
  static const String funnelAnalysisFunnel = 'funnel_analysis_usage';
  static const String funnelScreenViewed = 'funnel_screen_viewed';
  static const String funnelNameSearched = 'funnel_name_searched';
}
