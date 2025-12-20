import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/project_config_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/military_decorations.dart';

class VersionConfigScreen extends ConsumerStatefulWidget {
  const VersionConfigScreen({super.key});

  @override
  ConsumerState<VersionConfigScreen> createState() =>
      _VersionConfigScreenState();
}

class _VersionConfigScreenState extends ConsumerState<VersionConfigScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _minIosVersionController;
  late TextEditingController _minAndroidVersionController;
  late TextEditingController _iosStoreUrlController;
  late TextEditingController _androidStoreUrlController;
  late TextEditingController _forceUpdateMessageController;

  bool _isUpdateRequired = true;
  bool _hasChanges = false;
  bool _isEditMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _minIosVersionController = TextEditingController();
    _minAndroidVersionController = TextEditingController();
    _iosStoreUrlController = TextEditingController();
    _androidStoreUrlController = TextEditingController();
    _forceUpdateMessageController = TextEditingController();

    // Load config on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectConfigProvider.notifier).loadConfig();
    });
  }

  @override
  void dispose() {
    _minIosVersionController.dispose();
    _minAndroidVersionController.dispose();
    _iosStoreUrlController.dispose();
    _androidStoreUrlController.dispose();
    _forceUpdateMessageController.dispose();
    super.dispose();
  }

  void _initializeControllers(Map<String, String> config) {
    if (_initialized) return;
    _initialized = true;

    _minIosVersionController.text = config['min_ios_version'] ?? '';
    _minAndroidVersionController.text = config['min_android_version'] ?? '';
    _iosStoreUrlController.text = config['ios_store_url'] ?? '';
    _androidStoreUrlController.text = config['android_store_url'] ?? '';
    _forceUpdateMessageController.text =
        config['force_update_message'] ??
        'Please update to continue using the app.';
    _isUpdateRequired =
        (config['is_update_required'] ?? 'true').toLowerCase() == 'true';
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    final config = <String, String>{
      'min_ios_version': _minIosVersionController.text.trim(),
      'min_android_version': _minAndroidVersionController.text.trim(),
      'ios_store_url': _iosStoreUrlController.text.trim(),
      'android_store_url': _androidStoreUrlController.text.trim(),
      'force_update_message': _forceUpdateMessageController.text.trim(),
      'is_update_required': _isUpdateRequired.toString(),
    };

    final success = await ref
        .read(projectConfigProvider.notifier)
        .updateConfig(config);

    if (success && mounted) {
      setState(() {
        _hasChanges = false;
        _isEditMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VERSION_CONFIG_SAVED'),
          backgroundColor: Color(0xFF2D5A2D),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FAILED_TO_SAVE_CONFIG'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(projectConfigProvider);
    final projectState = ref.watch(projectProvider);
    final project = projectState.selectedProject;
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('VERSION_CONFIG'),
        ),
        body: const Center(
          child: Text(
            'NO_PROJECT_SELECTED',
            style: TextStyle(fontFamily: 'Urbanist', color: AppColors.slate),
          ),
        ),
      );
    }

    if (!configState.isLoading && configState.error == null) {
      _initializeControllers(configState.config);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'VERSION_CONFIG',
          style: TextStyle(fontFamily: 'Urbanist', letterSpacing: 1.5),
        ),
        actions: [
          if (!_isEditMode)
            TextButton.icon(
              onPressed: () => setState(() => _isEditMode = true),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('EDIT'),
            ),
          if (_isEditMode)
            TextButton(
              onPressed: () {
                // Reset form values from existing config without reloading
                final config = ref.read(projectConfigProvider).config;
                _minIosVersionController.text = config['min_ios_version'] ?? '';
                _minAndroidVersionController.text =
                    config['min_android_version'] ?? '';
                _iosStoreUrlController.text = config['ios_store_url'] ?? '';
                _androidStoreUrlController.text =
                    config['android_store_url'] ?? '';
                _forceUpdateMessageController.text =
                    config['force_update_message'] ??
                    'Please update to continue using the app.';
                _isUpdateRequired =
                    (config['is_update_required'] ?? 'true').toLowerCase() ==
                    'true';
                setState(() {
                  _isEditMode = false;
                  _hasChanges = false;
                });
              },
              child: const Text('CANCEL'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initialized = false;
                _isEditMode = false;
                _hasChanges = false;
              });
              ref.read(projectConfigProvider.notifier).loadConfig();
            },
            tooltip: 'REFRESH',
          ),
        ],
      ),
      body: configState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : configState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${configState.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.slate),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.read(projectConfigProvider.notifier).loadConfig(),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 24,
                  vertical: isMobile ? 16 : 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          MilitaryHoverContainer(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.system_update,
                                    color: AppColors.secondary,
                                    size: isMobile ? 32 : 48,
                                  ),
                                  SizedBox(width: isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'FORCE_UPDATE_CONFIG',
                                          style: AppTextStyles.displaySmall
                                              .copyWith(
                                                fontSize: isMobile ? 16 : 20,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Configure minimum app versions for ${project.name}',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: AppColors.slate),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 24),

                          // Version Section
                          Text(
                            'MINIMUM_VERSIONS',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.slate,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          MilitaryHoverContainer(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _minIosVersionController,
                                    label: 'MIN_IOS_VERSION',
                                    icon: Icons.apple,
                                    hint: 'e.g., 1.0.0',
                                    onChanged: (_) => _onFieldChanged(),
                                    validator: _validateVersion,
                                    readOnly: !_isEditMode,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _minAndroidVersionController,
                                    label: 'MIN_ANDROID_VERSION',
                                    icon: Icons.android,
                                    hint: 'e.g., 1.0.0',
                                    onChanged: (_) => _onFieldChanged(),
                                    validator: _validateVersion,
                                    readOnly: !_isEditMode,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 24),

                          // Store URLs Section
                          Text(
                            'STORE_URLS',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.slate,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          MilitaryHoverContainer(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _iosStoreUrlController,
                                    label: 'IOS_STORE_URL',
                                    icon: Icons.apple,
                                    hint: 'https://apps.apple.com/...',
                                    maxLines: 2,
                                    onChanged: (_) => _onFieldChanged(),
                                    readOnly: !_isEditMode,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _androidStoreUrlController,
                                    label: 'ANDROID_STORE_URL',
                                    icon: Icons.android,
                                    hint: 'https://play.google.com/...',
                                    maxLines: 2,
                                    onChanged: (_) => _onFieldChanged(),
                                    readOnly: !_isEditMode,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 24),

                          // Message Section
                          Text(
                            'UPDATE_MESSAGE',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.slate,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          MilitaryHoverContainer(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: _buildTextField(
                                controller: _forceUpdateMessageController,
                                label: 'FORCE_UPDATE_MESSAGE',
                                icon: Icons.message,
                                hint:
                                    'Message shown to users when update is required',
                                maxLines: 3,
                                onChanged: (_) => _onFieldChanged(),
                                readOnly: !_isEditMode,
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 20 : 24),

                          // Compulsory Toggle
                          Text(
                            'UPDATE_BEHAVIOR',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.slate,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          MilitaryHoverContainer(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: Row(
                                children: [
                                  Icon(
                                    _isUpdateRequired
                                        ? Icons.block
                                        : Icons.skip_next,
                                    color: _isUpdateRequired
                                        ? AppColors.error
                                        : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'UPDATE_IS_COMPULSORY',
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(color: AppColors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isUpdateRequired
                                              ? 'Users cannot skip the update'
                                              : 'Users can choose to update later',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(color: AppColors.slate),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isUpdateRequired,
                                    onChanged: _isEditMode
                                        ? (value) {
                                            setState(
                                              () => _isUpdateRequired = value,
                                            );
                                            _onFieldChanged();
                                          }
                                        : null,
                                    activeThumbColor: AppColors.error,
                                    inactiveThumbColor: AppColors.secondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 32),

                          // Save Button
                          if (_isEditMode)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    (_hasChanges && !configState.isLoading)
                                    ? _saveConfig
                                    : null,
                                icon: configState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  configState.isLoading
                                      ? 'SAVING...'
                                      : 'SAVE_CONFIGURATION',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 14 : 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      enabled: !readOnly,
      style: TextStyle(
        fontFamily: 'Urbanist',
        color: readOnly ? AppColors.slate : AppColors.white,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Urbanist',
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.slate),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.slate.withAlpha(77)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.slate.withAlpha(50)),
        ),
      ),
    );
  }

  String? _validateVersion(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final parts = value.split('.');
    if (parts.length != 3 || parts.any((p) => int.tryParse(p) == null)) {
      return 'Use format: X.Y.Z (e.g., 1.0.0)';
    }
    return null;
  }
}
