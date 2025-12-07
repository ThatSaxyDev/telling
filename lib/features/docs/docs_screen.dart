import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  String? _markdownData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    try {
      // Load from assets
      final data = await rootBundle.loadString('assets/docs/README.md');
      if (mounted) {
        setState(() {
          _markdownData = data;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      Telling.instance.captureException(
        error: e,
        stackTrace: stack,
        context: 'load_docs',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Elements
          const Positioned.fill(
            child: IgnorePointer(
              child: GridBackground(
                color: Color(0xFF1A1A1A),
                spacing: 40,
                strokeWidth: 0.5,
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Scanline(
                color: Color(0x0AFFFFFF),
                duration: Duration(seconds: 5),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              // Header
              _buildHeader(context, isMobile),

              // Markdown Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _markdownData == null
                    ? Center(
                        child: Text(
                          'ERROR_LOADING_INTELLIGENCE_DATA',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            color: AppColors.error,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : _buildMarkdownContent(isMobile),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back Button
            IconButton(
              onPressed: () => context.go('/landing'),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 20,
              ),
              tooltip: 'RETURN_TO_BASE',
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TECHNICAL_MANUAL',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      color: AppColors.white,
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  if (!isMobile)
                    Text(
                      'CLASSIFIED // FOR_DEVELOPER_EYES_ONLY',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.primary,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 20
            : (MediaQuery.of(context).size.width > 1200 ? 200 : 80),
        vertical: 40,
      ),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        child: MarkdownBody(
          data: _markdownData!,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            h1: TextStyle(
              fontFamily: 'Syne',
              color: AppColors.white,
              fontSize: isMobile ? 32 : 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              height: 1.5,
            ),
            h2: TextStyle(
              fontFamily: 'Syne',
              color: AppColors.white,
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              height: 1.5,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
              decorationStyle: TextDecorationStyle.solid,
            ),
            h3: TextStyle(
              fontFamily: 'Syne',
              color: AppColors.primary,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              height: 1.5,
            ),
            p: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.slate,
              fontSize: 16,
              height: 1.6,
            ),
            code: TextStyle(
              fontFamily: 'JetBrains Mono', // If available, else monospace
              backgroundColor: const Color(0xFF2A2A2A),
              color: AppColors.white,
              fontSize: 14,
            ),
            codeblockPadding: const EdgeInsets.all(16),
            codeblockDecoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.zero,
            ),
            blockquote: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.white.withValues(alpha: 0.8),
              fontStyle: FontStyle.italic,
              fontSize: 16,
            ),
            blockquoteDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 4),
              ),
            ),
            tableBody: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.slate,
              fontSize: 14,
            ),
            tableHead: TextStyle(
              fontFamily: 'Urbanist',
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tableBorder: TableBorder.all(
              color: AppColors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            a: const TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.none, // specific style for links
              fontWeight: FontWeight.bold,
            ),
          ),
          onTapLink: (text, href, title) {
            // Handle link taps if necessary (e.g. open in browser)
            // You might need url_launcher here if you want to support external links
            // For now we can just log it.
            Telling.instance.log('Link tapped: $href');
          },
        ),
      ),
    );
  }
}
