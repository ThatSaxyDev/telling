import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/funnel_constants.dart';
import '../../shared/widgets/military_decorations.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _floatController;
  late Animation<double> _heroFade;
  late Animation<Offset> _heroSlide;

  bool get _isMobileApp => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();

    // Step 1: Landing Screen Viewed (Onboarding Funnel Start)
    Telling.instance.trackFunnel(
      funnelName: FunnelConstants.onboardingFunnel,
      stepName: FunnelConstants.landingViewed,
      step: 1,
    );

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);

    _heroFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );

    _heroSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _heroController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    final useMobileLayout = isMobile || _isMobileApp;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Animated Grid Background
          const Positioned.fill(
            child: IgnorePointer(
              child: GridBackground(
                color: Color(0xFF1A1A1A),
                spacing: 40,
                strokeWidth: 0.5,
              ),
            ),
          ),

          // Scanline Effect
          const Positioned.fill(
            child: IgnorePointer(
              child: Scanline(
                color: Color(0x0AFFFFFF),
                duration: Duration(seconds: 5),
              ),
            ),
          ),

          // Floating particles
          ...List.generate(
            useMobileLayout ? 6 : 12,
            (index) => _buildFloatingDecoration(index, size),
          ),

          // Main Content
          useMobileLayout
              ? _buildMobileAppLayout(isMobile)
              : _buildWebLayout(isMobile),

          // Top Navigation Bar (Desktop Web only) - Placed LAST to be on TOP
          if (!useMobileLayout) _buildTopNavBar(isMobile),
        ],
      ),
    );
  }

  Widget _buildTopNavBar(bool isMobile) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 80,
              vertical: isMobile ? 16 : 20,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withAlpha(100),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.white.withAlpha(26),
                  width: 1,
                ),
              ),
            ),
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.white, width: 1.5),
                ),
                child: Text(
                  'TELLING',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    color: AppColors.white,
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // CTA Buttons
            if (!isMobile)
              Row(
                children: [
                  _TopNavButton(
                    label: 'INITIATE_ACCESS',
                    onPressed: () {
                      Telling.instance.event(
                        'Interaction: Navigate to Login from TopNav',
                        properties: {'source': 'top_nav'},
                      );
                      context.go('/login');
                    },
                    isPrimary: false,
                  ),
                  const SizedBox(width: 16),
                  _TopNavButton(
                    label: 'REQUEST_CLEARANCE',
                    onPressed: () {
                      Telling.instance.event(
                        'Interaction: Navigate to Register from TopNav',
                        properties: {'source': 'top_nav'},
                      );
                      // Step 2: Get Started Clicked (Onboarding Funnel)
                      Telling.instance.trackFunnel(
                        funnelName: FunnelConstants.onboardingFunnel,
                        stepName: FunnelConstants.getStartedClicked,
                        step: 2,
                        properties: {'source': 'top_nav'},
                      );
                      context.go('/register');
                    },
                    isPrimary: true,
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  ),
);
  }

  // Mobile App Layout - Single page, no scroll
  Widget _buildMobileAppLayout(bool isMobile) {
    return Center(
      child: FadeTransition(
        opacity: _heroFade,
        child: SlideTransition(
          position: _heroSlide,
          child: SafeArea(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
                maxHeight: MediaQuery.of(context).size.height,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 32,
                vertical: isMobile ? 16 : 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      _buildClassificationBadge(true),
                      const SizedBox(height: 20),
                      _buildHeroHeading(true),
                      const SizedBox(height: 8),
                      _buildTagline(true),
                      const SizedBox(height: 12),
                      _buildFlutterBadge(true),
                    ],
                  ),
                  _buildMissionBrief(true),
                  _buildCTASection(true),
                  _buildFooter(true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Web/Desktop Layout - Scrollable with multiple sections
  Widget _buildWebLayout(bool isMobile) {
    return FadeTransition(
      opacity: _heroFade,
      child: SlideTransition(
        position: _heroSlide,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(isMobile),

              // Features Section
              _buildFeaturesSection(isMobile),

              // Mission Brief Section
              _buildMissionSection(isMobile),

              // CTA Section
              _buildWebCTASection(isMobile),

              _buildFooter(isMobile),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isMobile) {
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildClassificationBadge(isMobile),
          SizedBox(height: isMobile ? 48 : 80),
          _buildHeroHeading(isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _buildTagline(isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          _buildFlutterBadge(isMobile),
          SizedBox(height: isMobile ? 60 : 100),
          // Scroll indicator
          if (!isMobile)
            Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 10 * sin(value * 2 * pi)),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.slate,
                        size: 32,
                      ),
                    );
                  },
                  onEnd: () => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'SCROLL_TO_EXPLORE',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.slate,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile) {
    final features = [
      {
        'icon': Icons.radar,
        'title': 'REAL-TIME_SURVEILLANCE',
        'desc': 'Monitor application behavior with millisecond precision. Track every event in real-time.',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'DATA_INTELLIGENCE',
        'desc': 'Transform raw logs into actionable insights. Visualize trends and patterns.',
      },
      {
        'icon': Icons.security,
        'title': 'SECURE_DEPLOYMENT',
        'desc': 'Military-grade encryption for all data transmission. Your logs stay private.',
      },
      {
        'icon': Icons.speed,
        'title': 'RAPID_RESPONSE',
        'desc': 'Instant alerts and notifications for critical events. Never miss an issue.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: isMobile ? 30 : 50,
                height: 2,
                color: AppColors.white,
              ),
              const SizedBox(width: 16),
              Text(
                'TACTICAL_CAPABILITIES',
                style: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
                  fontSize: isMobile ? 20 : 28,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: isMobile ? 48 : 80),

          // Features Grid
          isMobile
              ? Column(
                  children: features
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: _buildFeatureCard(
                              f['icon'] as IconData,
                              f['title'] as String,
                              f['desc'] as String,
                              isMobile,
                            ),
                          ))
                      .toList(),
                )
              : Wrap(
                  spacing: 32,
                  runSpacing: 32,
                  children: features
                      .map((f) => SizedBox(
                            width: (MediaQuery.of(context).size.width - 192) / 2,
                            child: _buildFeatureCard(
                              f['icon'] as IconData,
                              f['title'] as String,
                              f['desc'] as String,
                              isMobile,
                            ),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc, bool isMobile) {
    return MilitaryHoverContainer(
      baseColor: AppColors.slate.withAlpha(128),
      hoverColor: AppColors.white,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.slate.withAlpha(77)),
          color: AppColors.surfaceDark.withAlpha(128),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.white,
              size: isMobile ? 32 : 40,
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.white,
                fontSize: isMobile ? 16 : 18,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              desc,
              style: TextStyle(
                fontFamily: 'Urbanist',
                color: AppColors.slate,
                fontSize: isMobile ? 14 : 15,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 100,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 30 : 50,
                height: 2,
                color: AppColors.white,
              ),
              const SizedBox(width: 16),
              Text(
                'MISSION_BRIEF',
                style: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
                  fontSize: isMobile ? 20 : 28,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 32 : 48),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(isMobile ? 24 : 40),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.slate.withAlpha(77), width: 2),
              color: AppColors.surfaceDark.withAlpha(153),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time application monitoring & error tracking system built for developers '
                  'who need comprehensive insights without complexity.',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.white,
                    fontSize: isMobile ? 18 : 22,
                    height: 1.6,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 32),
                Text(
                  'Deploy tactical intelligence to track errors, analyze user behavior, '
                  'monitor performance metrics, and maintain operational superiority '
                  'across your entire application infrastructure.',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.slate,
                    fontSize: isMobile ? 15 : 16,
                    height: 1.7,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebCTASection(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 60 : 100,
      ),
      child: CornerBrackets(
        color: AppColors.white,
        length: isMobile ? 16 : 24,
        thickness: 2.5,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: EdgeInsets.all(isMobile ? 32 : 48),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withAlpha(230),
            border: Border.all(color: AppColors.white.withAlpha(102), width: 2.5),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.white, width: 2),
                    bottom: BorderSide(color: AppColors.white, width: 2),
                  ),
                ),
                child: Text(
                  'COMMENCE_OPERATIONS',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    color: AppColors.white,
                    fontSize: isMobile ? 18 : 24,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 24 : 32),
              Text(
                'Deploy your tactical logging system and gain complete operational awareness',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.slate,
                  fontSize: isMobile ? 15 : 16,
                  height: 1.6,
                ),
              ),
              SizedBox(height: isMobile ? 32 : 40),
              isMobile
                  ? Column(
                      children: [
                        _MilitaryButton(
                          label: 'INITIATE_ACCESS',
                          onPressed: () {
                            Telling.instance.event(
                              'Interaction: Navigate to Login from Landing',
                              properties: {'source': 'landing_cta'},
                            );
                            context.go('/login');
                          },
                          isPrimary: true,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 16),
                        _MilitaryButton(
                          label: 'REQUEST_CLEARANCE',
                          onPressed: () {
                            Telling.instance.event(
                              'Interaction: Navigate to Register from Landing',
                              properties: {'source': 'landing_cta'},
                            );
                            // Step 2: Get Started Clicked (Onboarding Funnel)
                            Telling.instance.trackFunnel(
                              funnelName: FunnelConstants.onboardingFunnel,
                              stepName: FunnelConstants.getStartedClicked,
                              step: 2,
                              properties: {'source': 'landing_cta'},
                            );
                            context.go('/register');
                          },
                          isPrimary: false,
                          isMobile: isMobile,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _MilitaryButton(
                            label: 'INITIATE_ACCESS',
                            onPressed: () {
                              Telling.instance.event(
                                'Interaction: Navigate to Login from Landing',
                                properties: {'source': 'landing_cta'},
                              );
                              context.go('/login');
                            },
                            isPrimary: true,
                            isMobile: isMobile,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _MilitaryButton(
                            label: 'REQUEST_CLEARANCE',
                            onPressed: () {
                              Telling.instance.event(
                                'Interaction: Navigate to Register from Landing',
                                properties: {'source': 'landing_cta'},
                              );
                              // Step 2: Get Started Clicked (Onboarding Funnel)
                              Telling.instance.trackFunnel(
                                funnelName: FunnelConstants.onboardingFunnel,
                                stepName: FunnelConstants.getStartedClicked,
                                step: 2,
                                properties: {'source': 'landing_cta'},
                              );
                              context.go('/register');
                            },
                            isPrimary: false,
                            isMobile: isMobile,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              _buildStatusIndicator(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingDecoration(int index, Size size) {
    final random = Random(index);
    final left = random.nextDouble() * size.width;
    final top = random.nextDouble() * size.height;
    
    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            final offset = sin(_floatController.value * 2 * pi + index) * 12;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: 0.12 + (0.12 * sin(_floatController.value * pi)),
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.white.withAlpha(51),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassificationBadge(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 1.5),
        color: AppColors.white.withAlpha(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Container(
                width: isMobile ? 6 : 8,
                height: isMobile ? 6 : 8,
                decoration: BoxDecoration(
                  color: AppColors.white.withAlpha((255 * ((value * 2) % 1.0)).round()),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.white.withAlpha(128),
                      blurRadius: 6 * ((value * 2) % 1.0),
                      spreadRadius: 2 * ((value * 2) % 1.0),
                    ),
                  ],
                ),
              );
            },
            onEnd: () => setState(() {}),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Text(
            'CLASSIFIED // TIER_1',
            style: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.white,
              fontSize: isMobile ? 9 : 11,
              letterSpacing: isMobile ? 2 : 2.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeading(bool isMobile) {
    return GlitchText(
      text: 'TELLING',
      style: TextStyle(
        fontFamily: 'Syne',
        color: AppColors.white,
        fontSize: isMobile ? 48 : (_isMobileApp ? 56 : 96),
        fontWeight: FontWeight.bold,
        letterSpacing: isMobile ? 6 : (_isMobileApp ? 8 : 14),
        height: 0.95,
      ),
      glitchAmount: 2.5,
    );
  }

  Widget _buildTagline(bool isMobile) {
    return TypingText(
      text: 'TACTICAL INTELLIGENCE SYSTEM',
      style: TextStyle(
        fontFamily: 'Urbanist',
        color: AppColors.slate,
        fontSize: isMobile ? 11 : (_isMobileApp ? 13 : 18),
        letterSpacing: isMobile ? 2 : (_isMobileApp ? 2.5 : 4),
        fontWeight: FontWeight.w600,
      ),
      duration: const Duration(milliseconds: 30),
      delay: const Duration(milliseconds: 400),
    );
  }

  Widget _buildMissionBrief(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.slate.withAlpha(77), width: 1.5),
        color: AppColors.surfaceDark.withAlpha(153),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'MISSION_BRIEF',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.white,
                  fontSize: isMobile ? 10 : 12,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 14 : 16),
          Text(
            'Real-time monitoring & error tracking. Deploy tactical intelligence to maintain operational superiority.',
            style: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.slate,
              fontSize: isMobile ? 13 : 14,
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(bool isMobile) {
    return CornerBrackets(
      color: AppColors.white,
      length: isMobile ? 14 : 16,
      thickness: 2,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withAlpha(230),
          border: Border.all(color: AppColors.white.withAlpha(102), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.white, width: 1.5),
                  bottom: BorderSide(color: AppColors.white, width: 1.5),
                ),
              ),
              child: Text(
                'COMMENCE_OPS',
                style: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
                  fontSize: isMobile ? 14 : 16,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 24 : 28),
            Column(
              children: [
                _MilitaryButton(
                  label: 'INITIATE_ACCESS',
                  onPressed: () {
                    Telling.instance.event(
                      'Interaction: Navigate to Login from Landing',
                      properties: {'source': 'landing_cta'},
                    );
                    context.go('/login');
                  },
                  isPrimary: true,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 14),
                _MilitaryButton(
                  label: 'REQUEST_CLEARANCE',
                  onPressed: () {
                    Telling.instance.event(
                      'Interaction: Navigate to Register from Landing',
                      properties: {'source': 'landing_cta'},
                    );
                    // Step 2: Get Started Clicked (Onboarding Funnel)
                    Telling.instance.trackFunnel(
                      funnelName: FunnelConstants.onboardingFunnel,
                      stepName: FunnelConstants.getStartedClicked,
                      step: 2,
                      properties: {'source': 'landing_cta'},
                    );
                    context.go('/register');
                  },
                  isPrimary: false,
                  isMobile: isMobile,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatusIndicator(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Container(
              width: isMobile ? 8 : 10,
              height: isMobile ? 8 : 10,
              decoration: BoxDecoration(
                color: AppColors.white.withAlpha((255 * ((value * 2) % 1.0)).round()),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.white.withAlpha(128),
                    blurRadius: 10 * ((value * 2) % 1.0),
                    spreadRadius: 2 * ((value * 2) % 1.0),
                  ),
                ],
              ),
            );
          },
          onEnd: () => setState(() {}),
        ),
        const SizedBox(width: 12),
        Text(
          'SYSTEM_OPERATIONAL',
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: AppColors.slate,
            fontSize: isMobile ? 9 : 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  Widget _buildFlutterBadge(bool isMobile) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchUrl('https://pub.dev/packages/telling_logger'),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 20,
            vertical: isMobile ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF02569B).withAlpha(26),
            border: Border.all(color: const Color(0xFF02569B), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flutter_dash,
                color: const Color(0xFF54C5F8),
                size: isMobile ? 16 : 20,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                isMobile ? 'PUB.DEV' : 'BUILT_FOR_FLUTTER',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: const Color(0xFF54C5F8),
                  fontSize: isMobile ? 11 : 13,
                  letterSpacing: isMobile ? 1.5 : 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 12,
                  color: const Color(0xFF54C5F8).withAlpha(77),
                ),
                const SizedBox(width: 12),
                Text(
                  'VIEW_ON_PUB.DEV',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: AppColors.white,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with Flutter & 💙 by ',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.slate,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _launchUrl('https://kiishi.space/'),
                  child: Text(
                    'Kiishi',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: AppColors.white,
                      fontSize: isMobile ? 12 : 14,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => context.go('/privacy'),
              child: Text(
                'PRIVACY_POLICY',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.slate,
                  fontSize: isMobile ? 10 : 12,
                  letterSpacing: 1.5,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.slate,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _MilitaryButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isMobile;

  const _MilitaryButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
    this.isMobile = false,
  });

  @override
  State<_MilitaryButton> createState() => _MilitaryButtonState();
}

class _MilitaryButtonState extends State<_MilitaryButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  AnimationController? _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scanController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          height: widget.isMobile ? 52 : 58,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? AppColors.white
                : (_isHovered ? AppColors.white.withAlpha(26) : Colors.transparent),
            border: Border.all(
              color: _isHovered ? AppColors.white : AppColors.slate,
              width: _isHovered ? 2.5 : 2,
            ),
          ),
          child: Stack(
            children: [
              if (_isHovered && _scanController != null)
                AnimatedBuilder(
                  animation: _scanController!,
                  builder: (context, child) {
                    return Positioned(
                      left: 0,
                      right: 0,
                      top: (widget.isMobile ? 52 : 58) * _scanController!.value,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              (widget.isPrimary ? AppColors.primary : AppColors.white)
                                  .withAlpha(179),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (_isHovered)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PulsingCornerPainter(
                        color: widget.isPrimary ? AppColors.primary : AppColors.white,
                      ),
                    ),
                  ),
                ),
              Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: widget.isPrimary
                        ? AppColors.primary
                        : (_isHovered ? AppColors.white : AppColors.slate),
                    fontSize: widget.isMobile ? 13 : 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingCornerPainter extends CustomPainter {
  final Color color;

  _PulsingCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final length = 14.0;
    final offset = 6.0;

    final path = Path();

    path.moveTo(offset, offset + length);
    path.lineTo(offset, offset);
    path.lineTo(offset + length, offset);

    path.moveTo(size.width - offset - length, offset);
    path.lineTo(size.width - offset, offset);
    path.lineTo(size.width - offset, offset + length);

    path.moveTo(size.width - offset, size.height - offset - length);
    path.lineTo(size.width - offset, size.height - offset);
    path.lineTo(size.width - offset - length, size.height - offset);

    path.moveTo(offset + length, size.height - offset);
    path.lineTo(offset, size.height - offset);
    path.lineTo(offset, size.height - offset - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _TopNavButton({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  State<_TopNavButton> createState() => _TopNavButtonState();
}

class _TopNavButtonState extends State<_TopNavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_isHovered ? AppColors.white : AppColors.white.withAlpha(230))
                : (_isHovered ? AppColors.white.withAlpha(26) : Colors.transparent),
            border: Border.all(
              color: _isHovered ? AppColors.white : AppColors.slate,
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Urbanist',
              color: widget.isPrimary
                  ? AppColors.primary
                  : (_isHovered ? AppColors.white : AppColors.slate),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

