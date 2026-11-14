import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/services/admin_property_service.dart';
import '../../models/admin_property_model.dart';
import '../../../chat/presentation/screens/chat_screen.dart';

class AdminPropertyReviewDetailScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const AdminPropertyReviewDetailScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<AdminPropertyReviewDetailScreen> createState() =>
      _AdminPropertyReviewDetailScreenState();
}

class _AdminPropertyReviewDetailScreenState
    extends State<AdminPropertyReviewDetailScreen> {
  static const Color slateBg = Color(0xFF0A0D14);
  static const Color cardDark = Color(0xFF161B26);
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color purpleAccent = Color(0xFF6366F1);

  final AdminPropertyService _adminService = AdminPropertyService();

  AdminPropertyReviewDetailsModel? _details;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _adminService.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _adminService.getPropertyReviewDetails(widget.propertyId);
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _details = res;
          _isLoading = false;
        });

        // Automatically transition status to Under Review if pending approval
        if (res.status == AdminPropertySummaryModel.statusPendingApproval) {
          _adminService.startReview(widget.propertyId);
        }
      } else {
        setState(() {
          _errorMessage = 'Could not load property review details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleApprove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Approve & Publish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Text(
          'Are you sure you want to approve "${_details?.title ?? widget.propertyTitle}"? It will immediately be published and visible to all buyers and territory agents.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _adminService.approveProperty(widget.propertyId);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Property approved and published live!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Approval failed. Please check server logs.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRequestChanges() async {
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: purpleAccent, size: 24),
            SizedBox(width: 8),
            Text('Request Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explain what details, legal documents, or photos the seller needs to update before approval:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Please upload clear survey plan with local authority seal...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: slateBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: purpleAccent)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter instructions for the seller';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send to Seller'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _adminService.requestChanges(
        widget.propertyId,
        adminNotes: notesController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes requested. Seller notified.'),
            backgroundColor: purpleAccent,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to request changes.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject() async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Decline Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Provide reason for outright listing rejection (e.g. fraudulent title, duplicate entry):',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter reason for rejection...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: slateBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter rejection reason';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (shouldReject != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await _adminService.rejectProperty(
        widget.propertyId,
        reason: reasonController.text.trim(),
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing has been declined.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to reject listing.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _callOwner(String phone) async {
    if (phone.isEmpty) return;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  String _formatPrice(double val) {
    if (val >= 10000000) {
      return 'LKR ${(val / 10000000).toStringAsFixed(2)} Cr';
    } else if (val >= 100000) {
      return 'LKR ${(val / 100000).toStringAsFixed(2)} Lakhs';
    }
    return 'LKR ${val.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slateBg,
      appBar: AppBar(
        backgroundColor: cardDark,
        elevation: 0,
        title: Text(
          _details?.title ?? widget.propertyTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Refresh Review',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDetails,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _details != null ? _buildDecisionBar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: primaryCyan),
            SizedBox(height: 14),
            Text('Loading review package & legal documents...', style: TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetails,
                style: ElevatedButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.black),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final d = _details!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Status & Reference Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryCyan.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      d.referenceNo,
                      style: const TextStyle(color: primaryCyan, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      d.statusName.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                d.title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '${d.addressLine1}, ${d.cityName}, ${d.districtName}',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                _formatPrice(d.askingPrice),
                style: const TextStyle(color: primaryCyan, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Seller Contact Information Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_pin_rounded, color: purpleAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Seller / Lister Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: purpleAccent.withValues(alpha: 0.2),
                    child: Text(
                      d.ownerName.isNotEmpty ? d.ownerName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: purpleAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.ownerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        if (d.ownerEmail.isNotEmpty)
                          Text(d.ownerEmail, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                        if (d.ownerPhone.isNotEmpty)
                          Text(d.ownerPhone, style: const TextStyle(color: primaryCyan, fontSize: 12, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  if (d.ownerPhone.isNotEmpty)
                    IconButton.filled(
                      tooltip: 'Direct Call Seller',
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      onPressed: () => _callOwner(d.ownerPhone),
                    ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Chat Seller',
                    style: IconButton.styleFrom(backgroundColor: primaryCyan, foregroundColor: Colors.black),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            propertyId: d.propertyId,
                            propertyTitle: d.title,
                            recipientId: d.ownerUserId,
                            recipientName: d.ownerName,
                            recipientRole: 'seller',
                            currentUserRole: 'admin',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Property Specifications
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.home_work_rounded, color: primaryCyan, size: 20),
                  SizedBox(width: 8),
                  Text('Listing Specifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (d.bedrooms != null) _buildSpecBadge(Icons.bed_rounded, '${d.bedrooms} Beds'),
                  if (d.bathrooms != null) _buildSpecBadge(Icons.bathtub_rounded, '${d.bathrooms} Baths'),
                  if (d.floorAreaSqFt != null) _buildSpecBadge(Icons.square_foot_rounded, '${d.floorAreaSqFt!.toStringAsFixed(0)} sqft'),
                  if (d.landAreaPerches != null) _buildSpecBadge(Icons.landscape_rounded, '${d.landAreaPerches!.toStringAsFixed(1)} Perches'),
                  if (d.parkingSpaces != null) _buildSpecBadge(Icons.local_parking_rounded, '${d.parkingSpaces} Parking'),
                  _buildSpecBadge(Icons.category_rounded, d.propertyTypeName),
                  _buildSpecBadge(Icons.sell_rounded, d.listingTypeName),
                ],
              ),
              if (d.description != null && d.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 12),
                Text(d.description!.trim(), style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Legal Verification Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 20),
                  SizedBox(width: 8),
                  Text('Legal & Title Check', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              _buildLegalRow('Ownership Type', d.ownershipTypeName ?? 'Freehold'),
              _buildLegalRow('Active Mortgage', d.hasMortgage ? 'Yes (${d.mortgageProvider ?? "Not specified"})' : 'No Mortgage'),
              _buildLegalRow('Disputes / Legal Issues', d.hasLegalIssues ? '⚠️ Reported: ${d.legalIssueDescription ?? ""}' : 'Clean Title (No disputes reported)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Uploaded Verification Documents
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_shared_rounded, color: primaryCyan, size: 20),
                  const SizedBox(width: 8),
                  Text('Official Documents (${d.documents.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              if (d.documents.isEmpty)
                const Text('No legal files uploaded by lister yet.', style: TextStyle(color: Colors.white38, fontSize: 12))
              else
                ...d.documents.map((doc) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, color: primaryCyan, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc.documentType, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                Text(doc.documentName, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Photos & Media Preview
        if (d.media.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_library_rounded, color: purpleAccent, size: 20),
                    const SizedBox(width: 8),
                    Text('Photos & Media (${d.media.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: d.media.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final m = d.media[i];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 140,
                          color: slateBg,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                m.mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.image_not_supported_rounded, color: Colors.white38),
                                ),
                              ),
                              if (m.isCover)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryCyan,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Cover', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSpecBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: slateBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryCyan),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLegalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionBar() {
    if (_isProcessing) {
      return Container(
        height: 68,
        color: cardDark,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryCyan)),
              SizedBox(width: 12),
              Text('Processing review action...', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: cardDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Decline Button
          OutlinedButton(
            onPressed: _handleReject,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 8),

          // Request Changes Button
          Expanded(
            child: OutlinedButton(
              onPressed: _handleRequestChanges,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: purpleAccent),
                foregroundColor: purpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Request Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),

          // Approve & Publish Button
          Expanded(
            child: ElevatedButton(
              onPressed: _handleApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text('Approve Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
