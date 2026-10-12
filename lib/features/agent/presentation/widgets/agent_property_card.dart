import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/agent_property_model.dart';

class AgentPropertyCard extends StatelessWidget {
  final AgentPropertyItem item;
  final VoidCallback? onMarkVisited;
  final bool isMarkingVisited;

  const AgentPropertyCard({
    super.key,
    required this.item,
    this.onMarkVisited,
    this.isMarkingVisited = false,
  });

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color accentPink = Color(0xFFFF2D7A);

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      final cr = amount / 10000000;
      return 'LKR ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (amount >= 1000000) {
      final m = amount / 1000000;
      return 'LKR ${m.toStringAsFixed(m.truncateToDouble() == m ? 0 : 2)} M';
    } else if (amount >= 100000) {
      final lk = amount / 100000;
      return 'LKR ${lk.toStringAsFixed(lk.truncateToDouble() == lk ? 0 : 2)} Lakhs';
    }
    return 'LKR ${amount.toStringAsFixed(0)}';
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return const Color(0xFF3B82F6); // Blue - Interested
      case 2:
        return const Color(0xFFF59E0B); // Amber - Visit Requested
      case 3:
        return const Color(0xFF10B981); // Green - Visited
      case 4:
        return const Color(0xFF8B5CF6); // Purple - Documents Requested
      default:
        return primaryCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(item.interactionStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: District + Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: primaryCyan),
                      const SizedBox(width: 4),
                      Text(
                        item.districtName,
                        style: const TextStyle(
                          color: primaryCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.referenceNo != null && item.referenceNo!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.referenceNo!,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.interactionStatusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),

            if (item.addressLine1 != null && item.addressLine1!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.addressLine1!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Price
            Text(
              _formatCurrency(item.price),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: accentPink,
              ),
            ),

            const Divider(height: 24, color: Color(0xFFF1F5F9)),

            // Buyer & Seller info section
            Row(
              children: [
                // Buyer
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDF2F7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded, size: 14, color: Color(0xFF3B82F6)),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'BUYER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.buyerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: item.buyerPhone != null && item.buyerPhone!.isNotEmpty
                              ? () => _copyToClipboard(context, item.buyerPhone!, 'Buyer Phone')
                              : null,
                          child: Text(
                            item.buyerPhone ?? 'No phone',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.buyerPhone != null ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Seller
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEDF2F7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF10B981)),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'SELLER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: item.sellerPhone != null && item.sellerPhone!.isNotEmpty
                              ? () => _copyToClipboard(context, item.sellerPhone!, 'Seller Phone')
                              : null,
                          child: Text(
                            item.sellerPhone ?? 'No phone',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.sellerPhone != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Action Button for Visit Requested (Step 10: Mark Visited)
            if (item.interactionStatus == 2 && onMarkVisited != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isMarkingVisited ? null : onMarkVisited,
                  icon: isMarkingVisited
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    isMarkingVisited ? 'Completing Visit...' : 'Mark as Visited',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
