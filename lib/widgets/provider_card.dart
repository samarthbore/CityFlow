import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/provider.dart' as app_model;
import '../screens/join_queue_dialog.dart';
import '../services/location_service.dart';
import '../providers/queue_provider.dart';
import '../theme/app_theme.dart';

class ProviderCard extends StatelessWidget {
  final app_model.Provider provider;
  const ProviderCard({required this.provider, super.key});

  void _showQueueDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => JoinQueueDialog(provider: provider),
    );
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
        return Icons.content_cut;
      default:
        return Icons.store_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    final userLocation = queueProvider.currentUserLocation;
    
    String? distanceString;
    if (userLocation != null && provider.latitude != null && provider.longitude != null) {
      final distance = LocationService().calculateDistance(
        userLocation.latitude, 
        userLocation.longitude, 
        provider.latitude!, 
        provider.longitude!
      );
      distanceString = '${distance.toStringAsFixed(1)} km';
    }

    final waitTime = provider.waitingCount * provider.avgServiceTime;
    final isOpen = provider.isOpen;

    return GestureDetector(
      onTap: () => _showQueueDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(provider.category),
                size: 24,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    provider.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Category & Location
                  Text(
                    '${provider.category} • ${provider.city}${distanceString != null ? ' • $distanceString' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Stats Row
                  Row(
                    children: [
                      // Wait Time
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        waitTime > 0 ? '$waitTime min' : 'No wait',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: waitTime == 0 
                              ? AppTheme.accentGreen 
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Queue Count
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${provider.waitingCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Rating
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.warningYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.avgRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Status & Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Open Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen 
                        ? AppTheme.accentGreen.withOpacity(0.15)
                        : AppTheme.errorRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isOpen ? AppTheme.accentGreen : AppTheme.errorRed,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Arrow
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
