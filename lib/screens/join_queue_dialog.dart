import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';
import '../models/provider.dart' as app_model;
import '../theme/app_theme.dart';
import 'queue_status_screen.dart';
import 'provider_map_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/biometric_service.dart';

class JoinQueueDialog extends StatefulWidget {
  final app_model.Provider provider;

  const JoinQueueDialog({required this.provider, super.key});

  @override
  State<JoinQueueDialog> createState() => _JoinQueueDialogState();
}

class _JoinQueueDialogState extends State<JoinQueueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QueueProvider>(context, listen: false)
          .fetchQueueStatus(widget.provider.id);
    });
    
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    if (queueProvider.currentUserName != null) {
      _nameController.text = queueProvider.currentUserName!;
    }
    if (queueProvider.currentUserPhone != null) {
      _phoneController.text = queueProvider.currentUserPhone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  final BiometricService _biometricService = BiometricService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final queueProvider = Provider.of<QueueProvider>(context, listen: false);

    if (queueProvider.isBiometricsEnabled) {
      bool isAuthenticated = false;
      isAuthenticated = await _biometricService.authenticate(
        localizedReason: 'Please authenticate to join the queue',
      );

      if (!isAuthenticated) {
        if (!mounted) return;
        final passwordVerified = await _showPasswordDialog(context);
        if (!passwordVerified) return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final queueEntry = await queueProvider.joinQueue(
        providerId: widget.provider.id,
        userName: _nameController.text.trim(),
        userPhone: _phoneController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QueueStatusScreen(
              queueEntry: queueEntry,
              providerName: widget.provider.name,
              avgServiceTime: widget.provider.avgServiceTime,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join queue: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Authentication Required',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Biometrics failed. Please enter your password.',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
              ),
              child: TextField(
                controller: passwordController,
                obscureText: true,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final queueProvider = Provider.of<QueueProvider>(context, listen: false);
              final isValid = await queueProvider.verifyPassword(passwordController.text);
              if (isValid) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Invalid Password'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
              foregroundColor: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final status = queueProvider.queueStatus;
    final isOpen = widget.provider.isOpen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final waitTime = (status != null ? (status['totalWaiting'] ?? 0) : widget.provider.waitingCount) * widget.provider.avgServiceTime;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  
                  // Provider Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(widget.provider.category),
                      size: 32,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    widget.provider.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOpen 
                          ? AppTheme.accentGreen.withOpacity(0.15)
                          : AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? 'Open Now' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOpen ? AppTheme.accentGreen : AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Stats
                    if (isOpen) ...[
                      Row(
                        children: [
                          _buildStatCard(
                            icon: Icons.people_outline,
                            value: status?['totalWaiting']?.toString() ?? '0',
                            label: 'Waiting',
                            color: AppTheme.warningYellow,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.person_outline,
                            value: status?['servingNumber']?.toString() ?? '-',
                            label: 'Serving',
                            color: AppTheme.accentBlue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.schedule,
                            value: '${waitTime}m',
                            label: 'Est. Wait',
                            color: AppTheme.accentGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // About
                    if (widget.provider.description != null) ...[
                      Text(
                        widget.provider.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Address & Phone
                    _buildInfoRow(Icons.location_on_outlined, widget.provider.address),
                    if (widget.provider.phone != null)
                      _buildInfoRow(Icons.phone_outlined, widget.provider.phone!),

                    // Services
                    if (widget.provider.services.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.provider.services.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              service,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Map Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProviderMapScreen(provider: widget.provider),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('View on Map'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Join Queue Form
                    if (isOpen) ...[
                      const SizedBox(height: 24),
                      
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildInputField(
                              controller: _nameController,
                              hint: 'Your name',
                              icon: Icons.person_outline,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              controller: _phoneController,
                              hint: 'Phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
                            foregroundColor: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
                                  ),
                                )
                              : const Text(
                                  'Get Ticket',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Queue is currently closed',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 50.ms)
     .fadeIn(duration: 300.ms)
     .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms, curve: Curves.easeOut);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'clinic':
        return Icons.medical_services_outlined;
      case 'government':
        return Icons.account_balance_outlined;
      case 'salon':
        return Icons.content_cut_outlined;
      default:
        return Icons.store_outlined;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          prefixIcon: Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
