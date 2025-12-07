import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:telling_logger/telling_logger.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlighter/flutter_highlighter.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/military_decorations.dart';

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsSection {
  final String title;
  final String file;
  final IconData icon;

  const _DocsSection({
    required this.title,
    required this.file,
    required this.icon,
  });
}

class _DocsScreenState extends State<DocsScreen> {
  String? _markdownData;
  bool _isLoading = true;
  int _currentIndex = 0;

  final List<_DocsSection> _sections = const [
    _DocsSection(
      title: 'Overview',
      file: 'overview.md',
      icon: Icons.dashboard_outlined,
    ),
    _DocsSection(
      title: 'Getting Started',
      file: 'getting_started.md',
      icon: Icons.rocket_launch_outlined,
    ),
    _DocsSection(
      title: 'Core Concepts',
      file: 'core_concepts.md',
      icon: Icons.lightbulb_outline,
    ),
    _DocsSection(
      title: 'Advanced Features',
      file: 'advanced_features.md',
      icon: Icons.psychology_outlined,
    ),
    _DocsSection(
      title: 'Widget Tracking',
      file: 'widget_tracking.md',
      icon: Icons.widgets_outlined,
    ),
    _DocsSection(
      title: 'Funnel Tracking',
      file: 'funnel_tracking.md',
      icon: Icons.filter_alt_outlined,
    ),
    _DocsSection(
      title: 'Configuration',
      file: 'configuration.md',
      icon: Icons.settings_outlined,
    ),
    _DocsSection(
      title: 'Best Practices',
      file: 'best_practices.md',
      icon: Icons.verified_outlined,
    ),
    _DocsSection(
      title: 'Support',
      file: 'support.md',
      icon: Icons.help_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  Future<void> _loadMarkdown() async {
    setState(() => _isLoading = true);
    try {
      final section = _sections[_currentIndex];
      final path = 'assets/docs/sections/${section.file}';
      final data = await rootBundle.loadString(path);
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
        context: 'load_docs_section',
        metadata: {'section': _sections[_currentIndex].title},
      );
      if (mounted) {
        setState(() {
          _markdownData = '# Error Loading Section\n\nCould not load content.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSectionSelected(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _loadMarkdown();
    if (ResponsiveBreakpoints.of(context).isMobile) {
      Navigator.pop(context); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: isMobile
          ? Drawer(
              backgroundColor: AppColors.surfaceDark,
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.slate, width: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'DOCUMENTATION',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildSidebarList(isMobile: true)),
                ],
              ),
            )
          : null,
      body: Stack(
        children: [
          // Background
          const Positioned.fill(
            child: IgnorePointer(
              child: GridBackground(
                color: Color(0xFF1A1A1A),
                spacing: 40,
                strokeWidth: 0.5,
              ),
            ),
          ),
          
          Row(
            children: [
              // Desktop Sidebar
              if (!isMobile)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withValues(alpha: 0.5),
                    border: Border(
                      right: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Sidebar Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TELLING',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                color: AppColors.primary,
                                fontSize: 12,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'DOCS',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                color: AppColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // List
                      Expanded(child: _buildSidebarList(isMobile: false)),
                      // Back Button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _MilitaryButton(
                          label: 'RETURN TO BASE',
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/landing');
                            }
                          },
                          isPrimary: false,
                        ),
                      ),
                    ],
                  ),
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Mobile Header
                    if (isMobile) _buildMobileHeader(context),

                    // Content
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : _buildMarkdownContent(isMobile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
            Text(
              'DOCS / ${_sections[_currentIndex].title.toUpperCase()}',
              style: const TextStyle(
                fontFamily: 'Syne',
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/landing');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarList({required bool isMobile}) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        final isSelected = _currentIndex == index;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onSectionSelected(index),
            hoverColor: AppColors.white.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: isSelected
                    ? const Border(
                        left: BorderSide(color: AppColors.primary, width: 3),
                      )
                    : null,
                color: isSelected
                    ? AppColors.white.withValues(alpha: 0.05)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    section.icon,
                    size: 20,
                    color: isSelected ? AppColors.white : AppColors.slate,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    section.title,
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      color: isSelected ? AppColors.white : AppColors.slate,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMarkdownContent(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? 20
            : (MediaQuery.of(context).size.width > 1200 ? 120 : 60),
        vertical: 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb (Desktop)
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Docs  >  ${_sections[_currentIndex].title}',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.slate.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),

          Container(
            padding: EdgeInsets.all(
              isMobile ? 0 : 0,
            ), // Remove background container for cleaner look
            child: MarkdownBody(
              data: _markdownData!,
              selectable: true,
              builders: {
                'code': CodeElementBuilder(
                  textStyle: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 14,
                  ),
                ),
              },
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  height: 1.2,
                ),
                h2: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  height: 1.5,
                ),
                h3: TextStyle(
                  fontFamily: 'Syne',
                  color: AppColors.white,
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
                // Code block styling handled by builder now
                code: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  backgroundColor: const Color(0xFF2A2A2A),
                  color: AppColors.secondary, // Inline code color
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                codeblockPadding: const EdgeInsets.all(0),
                codeblockDecoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                blockquote: TextStyle(
                  fontFamily: 'Urbanist',
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: const Border(
                    left: BorderSide(color: AppColors.white, width: 4),
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
                  color: AppColors.white,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              onTapLink: (text, href, title) {
                Telling.instance.log('Link tapped: $href');
              },
            ),
          ),

          // Navigation Footer (Next/Prev)
          const SizedBox(height: 80),
          _buildFooterNavigation(isMobile),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentIndex > 0)
          GestureDetector(
            onTap: () => _onSectionSelected(_currentIndex - 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.slate.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PREVIOUS',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        color: AppColors.slate,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sections[_currentIndex - 1].title,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          const SizedBox(),

        if (_currentIndex < _sections.length - 1)
          GestureDetector(
            onTap: () => _onSectionSelected(_currentIndex + 1),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'NEXT',
                      style: TextStyle(
                        fontFamily: 'Syne',
                        color: AppColors.primary,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sections[_currentIndex + 1].title,
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MilitaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _MilitaryButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
          backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
          side: isPrimary
              ? null
              : BorderSide(color: AppColors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Syne',
            color: isPrimary ? Colors.black : AppColors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  CodeElementBuilder({this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.attributes['class'] == null) {
      // Inline code
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          element.textContent,
          style: textStyle?.copyWith(
            color: AppColors.secondary,
            fontFamily: 'JetBrains Mono',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Code block
    String language = '';
    final codeClass = element.attributes['class'];
    if (codeClass != null && codeClass.startsWith('language-')) {
      language = codeClass.substring(9);
    }

    return _CodeBlock(
      code: element.textContent,
      language: language,
      textStyle: textStyle,
    );
  }
}

class _CodeBlock extends StatefulWidget {
  final String code;
  final String language;
  final TextStyle? textStyle;

  const _CodeBlock({
    required this.code,
    required this.language,
    this.textStyle,
  });

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  bool _isHovering = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A), // Almost black header
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language Label
                  Row(
                    children: [
                      // Mac-style window dots for aesthetics
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F56),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFBD2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27C93F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.language.isNotEmpty)
                        Text(
                          widget.language.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            color: AppColors.slate.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  // Copy Button
                  InkWell(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: widget.code));
                      setState(() => _copied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copied = false);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _copied
                            ? AppColors.white.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _copied ? Icons.check : Icons.content_copy,
                            color: _copied
                                ? AppColors.secondary
                                : AppColors.slate,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _copied ? 'COPIED' : 'COPY',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              color: _copied
                                  ? AppColors.secondary
                                  : AppColors.slate,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Code Content
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  color: const Color(0xFF000000), // Pure black
                  child: HighlightView(
                    widget.code,
                    language: widget.language,
                    theme: _kAtomOneDarkTheme, // New custom theme
                    padding: EdgeInsets.zero,
                    textStyle: widget.textStyle?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontSize: 14,
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom High-Contrast "Military Spy" Theme
const _kAtomOneDarkTheme = {
  'root': TextStyle(
    color: Color(0xffabb2bf),
    backgroundColor: Color(0xFF000000),
  ), // Pure Black BG
  'comment': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: Color(0xff5c6370), fontStyle: FontStyle.italic),
  'doctag': TextStyle(color: Color(0xffc678dd)),
  'keyword': TextStyle(color: Color(0xffc678dd)),
  'formula': TextStyle(color: Color(0xffc678dd)),
  'section': TextStyle(color: Color(0xffe06c75)),
  'name': TextStyle(color: Color(0xffe06c75)),
  'selector-tag': TextStyle(color: Color(0xffe06c75)),
  'deletion': TextStyle(color: Color(0xffe06c75)),
  'subst': TextStyle(color: Color(0xffe06c75)),
  'literal': TextStyle(color: Color(0xff56b6c2)),
  'string': TextStyle(color: Color(0xff98c379)),
  'regexp': TextStyle(color: Color(0xff98c379)),
  'addition': TextStyle(color: Color(0xff98c379)),
  'attribute': TextStyle(color: Color(0xff98c379)),
  'meta-string': TextStyle(color: Color(0xff98c379)),
  'built_in': TextStyle(color: Color(0xffe6c07b)),
  'class .title': TextStyle(color: Color(0xffe6c07b)),
  'attr': TextStyle(color: Color(0xffd19a66)),
  'variable': TextStyle(color: Color(0xffd19a66)),
  'template-variable': TextStyle(color: Color(0xffd19a66)),
  'type': TextStyle(color: Color(0xffd19a66)),
  'selector-attr': TextStyle(color: Color(0xffd19a66)),
  'selector-pseudo': TextStyle(color: Color(0xffd19a66)),
  'number': TextStyle(color: Color(0xffd19a66)),
  'symbol': TextStyle(color: Color(0xff61aeee)),
  'bullet': TextStyle(color: Color(0xff61aeee)),
  'link': TextStyle(
    color: Color(0xff61aeee),
    decoration: TextDecoration.underline,
  ),
  'meta': TextStyle(color: Color(0xff61aeee)),
  'selector-id': TextStyle(color: Color(0xff61aeee)),
  'title': TextStyle(color: Color(0xff61aeee)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};
