import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';
import '../providers/queue_provider.dart';
import '../theme/app_theme.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _canUseBiometrics = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canUse = await _biometricService.isBiometricsAvailable();
    setState(() {
      _canUseBiometrics = canUse;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Security & Privacy', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Consumer<QueueProvider>(
        builder: (context, queueProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Biometric Security
              _buildSecurityTile(
                icon: Icons.fingerprint,
                title: 'Biometric Security',
                subtitle: _canUseBiometrics 
                    ? 'Require fingerprint/face ID to join queues'
                    : 'Biometrics not available on this device',
                isEnabled: _canUseBiometrics,
                value: queueProvider.isBiometricsEnabled,
                onChanged: _canUseBiometrics ? (value) async {
                  if (value) {
                    final authenticated = await _biometricService.authenticate(
                      localizedReason: 'Authenticate to enable biometric security',
                    );
                    if (authenticated) {
                      await queueProvider.setBiometricsEnabled(true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Biometric Security Enabled'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      }
                    }
                  } else {
                    await queueProvider.setBiometricsEnabled(false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Biometric Security Disabled'),
                          backgroundColor: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      );
                    }
                  }
                } : null,
              ),
              
              const SizedBox(height: 12),
              
              // Two-Factor Authentication
              _buildSecurityTile(
                icon: Icons.security,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                isEnabled: true,
                value: _twoFactorEnabled,
                onChanged: (value) {
                  setState(() => _twoFactorEnabled = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value ? '2FA Enabled' : '2FA Disabled'),
                      backgroundColor: value ? AppTheme.accentGreen : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSecurityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : AppTheme.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEnabled 
                  ? AppTheme.accentGreen.withOpacity(0.15)
                  : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isEnabled 
                  ? AppTheme.accentGreen
                  : (isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }
}
