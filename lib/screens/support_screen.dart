import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support & Info', style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Help & Support'),
          _buildSectionContainer(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                title: Text('FAQ', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor),
                title: Text('Contact Us', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Legal'),
          _buildSectionContainer(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.description_outlined, color: Theme.of(context).primaryColor),
                title: Text('Terms of Service', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).primaryColor),
                title: Text('Privacy Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                title: Text('About App', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text('Version 1.0.0', style: GoogleFonts.inter(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
