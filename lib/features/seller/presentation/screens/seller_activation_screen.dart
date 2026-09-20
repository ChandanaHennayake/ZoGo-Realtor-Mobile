import 'package:flutter/material.dart';

/// Seller activation screen.
///
/// This is the ONLY SellerActivationScreen in the app.
/// The duplicate copy previously declared at the bottom of
/// home_screen.dart must be deleted.
///
/// Pops with `true` when activation succeeded.
class SellerActivationScreen extends StatefulWidget {
  const SellerActivationScreen({
    super.key,
    required this.onActivateSeller,
  });

  /// Should call POST /api/v1/seller/activate and return true on success.
  final Future<bool> Function() onActivateSeller;

  @override
  State<SellerActivationScreen> createState() =>
      _SellerActivationScreenState();
}

class _SellerActivationScreenState extends State<SellerActivationScreen> {
  bool _isActivating = false;

  static const Color primaryCyan = Color(0xFF00C6D4);

  // ============================================================
  // ACTIVATE
  // ============================================================

  Future<void> _activateSeller() async {
    if (_isActivating) {
      return;
    }

    setState(() {
      _isActivating = true;
    });

    try {
      final activated = await widget.onActivateSeller();

      if (!mounted) {
        return;
      }

      if (activated) {
        Navigator.pop(context, true);
        return;
      }

      _showMessage('Seller activation could not be completed.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Seller activation failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Become a Seller',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.real_estate_agent_outlined,
                          size: 55,
                          color: primaryCyan,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Start Selling Your Property',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Activate your seller account to list your '
                      'properties on ZoGo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 35),

                    _buildFeature(
                      icon: Icons.home_work_outlined,
                      title: 'List your properties',
                      description: 'Create and manage your property listings.',
                    ),

                    const SizedBox(height: 16),

                    _buildFeature(
                      icon: Icons.photo_library_outlined,
                      title: 'Add property media',
                      description: 'Upload property photos and videos.',
                    ),

                    const SizedBox(height: 16),

                    _buildFeature(
                      icon: Icons.edit_location_alt_outlined,
                      title: 'Manage your listing',
                      description:
                          'Update your property information whenever needed.',
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isActivating ? null : _activateSeller,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryCyan,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primaryCyan.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isActivating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Activate Seller Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Your existing ZoGo account will be used.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
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

  // ============================================================
  // FEATURE
  // ============================================================

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryCyan),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}