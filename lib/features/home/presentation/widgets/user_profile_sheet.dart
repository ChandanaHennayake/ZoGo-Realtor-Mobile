import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/widgets/server_config_dialog.dart';
import '../../../auth/presentation/screens/get_started_screen.dart';
import '../../../seller/presentation/screens/seller_activation_screen.dart';
import '../../../admin/presentation/screens/admin_property_queue_screen.dart';

class UserProfileSheet extends StatelessWidget {
  final List<String> roles;
  final VoidCallback? onRolesUpdated;
  final Future<bool> Function()? onActivateSeller;

  const UserProfileSheet({
    super.key,
    required this.roles,
    this.onRolesUpdated,
    this.onActivateSeller,
  });

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color purpleAccent = Color(0xFF6366F1);
  static const Color darkSlate = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF131823);

  static Future<void> show(
    BuildContext context, {
    required List<String> roles,
    VoidCallback? onRolesUpdated,
    Future<bool> Function()? onActivateSeller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserProfileSheet(
        roles: roles,
        onRolesUpdated: onRolesUpdated,
        onActivateSeller: onActivateSeller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: darkSlate,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded, color: primaryCyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'User Account & Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 24),

            // Content
            Expanded(
              child: FutureBuilder<Map<String, String>>(
                future: SecureStorageService().getUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryCyan),
                    );
                  }

                  final profile = snapshot.data ?? {};
                  final firstName = profile['firstName'] ?? '';
                  final lastName = profile['lastName'] ?? '';
                  final email = profile['email'] ?? '';
                  final phone = profile['phoneNumber'] ?? profile['phone'] ?? '';
                  final fullName = ('$firstName $lastName').trim().isNotEmpty
                      ? ('$firstName $lastName').trim()
                      : 'ZoGo Member';

                  final hasSeller = roles.any((r) => r.toUpperCase() == 'SEL');
                  final isAgent = roles.any((r) => r.toUpperCase() == 'AGT');
                  final isAdmin = roles.any((r) => r.toUpperCase() == 'ADM' || r.toLowerCase() == 'admin');

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      // Avatar Card
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [primaryCyan, purpleAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryCyan.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'Z',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: darkSlate, width: 2),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],

                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: primaryCyan,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Roles Badges
                      Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: roles.map((r) {
                            final code = r.toUpperCase();
                            String label = code;
                            Color chipColor = cardDark;
                            Color textColor = Colors.white70;

                            if (code == 'ADM' || code == 'ADMIN') {
                              label = 'Admin';
                              chipColor = Colors.redAccent.withValues(alpha: 0.2);
                              textColor = Colors.redAccent;
                            } else if (code == 'AGT') {
                              label = 'Realtor Agent';
                              chipColor = primaryCyan.withValues(alpha: 0.2);
                              textColor = primaryCyan;
                            } else if (code == 'SEL') {
                              label = 'Verified Seller';
                              chipColor = purpleAccent.withValues(alpha: 0.2);
                              textColor = purpleAccent;
                            } else if (code == 'BYR') {
                              label = 'Buyer';
                              chipColor = Colors.white10;
                              textColor = Colors.white;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: textColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Seller Activation Promotion if not already seller
                      if (!hasSeller && !isAgent && !isAdmin)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                purpleAccent.withValues(alpha: 0.2),
                                primaryCyan.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: purpleAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: purpleAccent.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Become a Seller',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Publish properties and connect with certified realtors.',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purpleAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SellerActivationScreen(
                                        onActivateSeller: onActivateSeller ?? () async => false,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Activate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                      // Admin / Agent Review Queue Section
                      if (isAdmin || isAgent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF0F172A),
                                primaryCyan.withValues(alpha: 0.12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryCyan.withValues(alpha: 0.4)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.admin_panel_settings_rounded, color: primaryCyan, size: 22),
                            ),
                            title: const Text(
                              'Listing Approval Queue',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Review, approve & publish seller listings',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: primaryCyan, size: 14),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminPropertyQueueScreen(),
                                ),
                              );
                            },
                          ),
                        ),

                      // App Preferences Section
                      Container(
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.notifications_none_rounded, color: primaryCyan, size: 20),
                              title: const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Instant alerts on visits & offers', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.security_rounded, color: Color(0xFF10B981), size: 20),
                              title: const Text('Privacy & Security', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Role-based verified access', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              onTap: () {},
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.dns_rounded, color: primaryCyan, size: 20),
                              title: const Text('Server Environment', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text(ApiConstants.baseUrl, style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              onTap: () {
                                ServerConfigDialog.show(context);
                              },
                            ),
                            const Divider(color: Colors.white10, height: 1),
                            ListTile(
                              leading: const Icon(Icons.help_outline_rounded, color: Colors.amberAccent, size: 20),
                              title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Contact ZoGo concierge', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Log out button
                      Container(
                        decoration: BoxDecoration(
                          color: cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text('Securely clear session from this device', style: TextStyle(color: Colors.white38, fontSize: 11)),
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: cardDark,
                                title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                content: const Text('Are you sure you want to sign out from ZoGo Realtor?', style: TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Log Out'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await SecureStorageService().clearAll();
                              if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const GetStartedScreen()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
