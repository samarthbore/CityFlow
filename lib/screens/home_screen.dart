import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';
import '../models/provider.dart' as app_model;
import 'profile_screen.dart';
import 'queue_status_screen.dart';
import 'qr_scanner_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/provider_card.dart';
import '../widgets/loading_provider_card.dart';
import 'package:city_flow_app/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Hospital', 'Clinic', 'Government', 'Salon', 'Other'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      queueProvider.fetchProviders();
      queueProvider.fetchUserLocation();
    });
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<QueueProvider>(context, listen: false).filterProviders(
      query: _searchController.text,
      category: _selectedCategory,
    );
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    Provider.of<QueueProvider>(context, listen: false).filterProviders(
      query: _searchController.text,
      category: _selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final categoryLabels = {
      'All': l10n.allCategory,
      'Hospital': l10n.hospitalCategory,
      'Clinic': l10n.clinicCategory,
      'Government': l10n.governmentCategory,
      'Salon': l10n.salonCategory,
      'Other': 'Other',
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // HEADER
            // ============================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City Flow',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Queues made convenient',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ============================================
            // SEARCH BAR
            // ============================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // ============================================
            // CATEGORY CHIPS
            // ============================================
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  
                  return GestureDetector(
                    onTap: () => _onCategorySelected(category),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.transparent
                              : (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        categoryLabels[category] ?? category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                              ? (isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite)
                              : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // ============================================
            // SECTION HEADER
            // ============================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Now',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Consumer<QueueProvider>(
                    builder: (context, qp, _) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${qp.availableProviders.length} open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ============================================
            // PROVIDER LIST
            // ============================================
            Expanded(
              child: Consumer<QueueProvider>(
                builder: (context, queueProvider, child) {
                  if (queueProvider.isLoading) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 6,
                      itemBuilder: (context, index) => const LoadingProviderCard(),
                    );
                  }

                  if (queueProvider.availableProviders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 56,
                            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noProvidersFound,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: queueProvider.availableProviders.length,
                    itemBuilder: (context, index) {
                      final provider = queueProvider.availableProviders[index];
                      return ProviderCard(provider: provider)
                          .animate(delay: (60 * index).ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
      // ============================================
      // FLOATING ACTION BUTTON
      // ============================================
      floatingActionButton: Consumer<QueueProvider>(
        builder: (context, queueProvider, child) {
          if (queueProvider.currentQueueEntry != null) {
            return FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => QueueStatusScreen(
                      queueEntry: queueProvider.currentQueueEntry!,
                      providerName: queueProvider.currentProviderName ?? 'Your Queue', 
                    ),
                  ),
                );
              },
              label: Text(
                l10n.queueStatus,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.confirmation_number_outlined),
            );
          }
          // Show QR scan button when not in queue
          return FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const QRScannerScreen()),
              );
            },
            backgroundColor: isDark ? AppTheme.primaryWhite : AppTheme.primaryBlack,
            foregroundColor: isDark ? AppTheme.primaryBlack : AppTheme.primaryWhite,
            child: const Icon(Icons.qr_code_scanner),
          );
        },
      ),
    );
  }
}