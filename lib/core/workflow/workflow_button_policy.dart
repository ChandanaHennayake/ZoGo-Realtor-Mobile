import 'package:flutter/material.dart';

/// Centralized Roles for ZoGo Realtor Multi-Agent System
enum AppUserRole {
  buyer,
  agent,
  seller,
  admin;

  static AppUserRole fromRoles(List<String>? roles) {
    if (roles == null || roles.isEmpty) return AppUserRole.buyer;
    final upper = roles.map((r) => r.trim().toUpperCase()).toSet();
    if (upper.contains('ADM') || upper.contains('ADMIN')) return AppUserRole.admin;
    if (upper.contains('AGT') || upper.contains('AGENT')) return AppUserRole.agent;
    if (upper.contains('SEL') || upper.contains('SELLER')) return AppUserRole.seller;
    return AppUserRole.buyer;
  }
}

/// Action state determining button rendering across all screens
class WorkflowActionState {
  final bool isVisible;
  final bool isEnabled;
  final String label;
  final String? disabledReason;
  final IconData? icon;
  final Color color;
  final Color? backgroundColor;

  const WorkflowActionState({
    required this.isVisible,
    required this.isEnabled,
    required this.label,
    this.disabledReason,
    this.icon,
    required this.color,
    this.backgroundColor,
  });

  WorkflowActionState copyWith({
    bool? isVisible,
    bool? isEnabled,
    String? label,
    String? disabledReason,
    IconData? icon,
    Color? color,
    Color? backgroundColor,
  }) {
    return WorkflowActionState(
      isVisible: isVisible ?? this.isVisible,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      disabledReason: disabledReason ?? this.disabledReason,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}

/// Single Source of Truth for Button Eligibility & Workflow Policies
class WorkflowButtonPolicy {
  // Interaction Status Constants (Aligned with backend BuyerPropertyInteractionStatus)
  static const int statusInterested = 1;
  static const int statusVisitRequested = 2;
  static const int statusVisited = 3;
  static const int statusDocumentsRequested = 4;
  static const int statusNegotiating = 5;
  static const int statusOfferSubmitted = 6;
  static const int statusOfferAccepted = 7;
  static const int statusOfferRejected = 8;
  static const int statusNotInterested = 9;
  static const int statusSold = 10;
  static const int statusCancelled = 11;
  static const int statusRejected = 12;

  // Visit Status Constants (Aligned with PropertyVisit entity)
  static const int visitRequested = 1;
  static const int visitConfirmed = 2;
  static const int visitCompleted = 3;
  static const int visitCancelled = 4;
  static const int visitRejected = 5;

  // Document Status Constants (Aligned with PropertyDocument entity)
  static const int docUploaded = 1;
  static const int docUnderReview = 2;
  static const int docVerified = 3;
  static const int docRejected = 4;

  static bool isClosed(int? status) {
    if (status == null) return false;
    return status == statusSold ||
        status == statusCancelled ||
        status == statusRejected ||
        status == statusNotInterested;
  }

  // ==========================================
  // BUYER BUTTON ELIGIBILITY
  // ==========================================

  /// "I'm Interested" / "Interest Submitted" Button
  static WorkflowActionState getBuyerInterestAction({
    required int? interactionStatus,
    required bool isUpdating,
  }) {
    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Inquiry Closed',
        disabledReason: 'This inquiry is already closed.',
        icon: Icons.lock_outline_rounded,
        color: Color(0xFF64748B),
      );
    }

    if (interactionStatus == null || interactionStatus == 0) {
      return WorkflowActionState(
        isVisible: true,
        isEnabled: !isUpdating,
        label: "I'm Interested",
        icon: Icons.thumb_up_alt_outlined,
        color: const Color(0xFF00C6D4),
      );
    }

    // Already expressed interest
    return const WorkflowActionState(
      isVisible: true,
      isEnabled: false,
      label: 'Interest Submitted',
      disabledReason: 'You have already expressed interest in this property.',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF10B981),
      backgroundColor: Color(0x1A10B981),
    );
  }

  /// "Request Visit" Button
  static WorkflowActionState getBuyerVisitAction({
    required int? interactionStatus,
    int? visitStatus,
    required bool isUpdating,
  }) {
    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Inquiry Closed',
        disabledReason: 'Cannot request visits on closed inquiries.',
        icon: Icons.block_rounded,
        color: Color(0xFF64748B),
      );
    }

    if (interactionStatus == null || interactionStatus < statusInterested) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Request Visit',
        disabledReason: 'Express interest first to schedule a visit.',
        icon: Icons.calendar_month_outlined,
        color: Color(0xFF3B82F6),
      );
    }

    if (interactionStatus == statusVisitRequested || visitStatus == visitRequested) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Visit Pending',
        disabledReason: 'A visit request is currently pending agent confirmation.',
        icon: Icons.hourglass_top_rounded,
        color: Color(0xFFF59E0B),
        backgroundColor: Color(0x1AF59E0B),
      );
    }

    if (visitStatus == visitConfirmed) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Visit Confirmed',
        disabledReason: 'Your appointment is confirmed. Check visit details.',
        icon: Icons.event_available_rounded,
        color: Color(0xFF3B82F6),
        backgroundColor: Color(0x1A3B82F6),
      );
    }

    if (interactionStatus >= statusVisited || visitStatus == visitCompleted) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Visit Completed',
        disabledReason: 'Property visit completed. Proceed to requesting documents.',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Request Visit',
      icon: Icons.calendar_month_outlined,
      color: const Color(0xFF3B82F6),
    );
  }

  /// "Request Documents" Button
  static WorkflowActionState getBuyerDocumentAction({
    required int? interactionStatus,
    int? documentStatus,
    required bool isUpdating,
  }) {
    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Documents Locked',
        disabledReason: 'Inquiry is closed.',
        icon: Icons.block_rounded,
        color: Color(0xFF64748B),
      );
    }

    // Gate: Must have completed a visit first (status >= 3)
    if (interactionStatus == null || interactionStatus < statusVisited) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Request Documents',
        disabledReason: 'Available only after completing a property visit.',
        icon: Icons.lock_outline_rounded,
        color: Color(0xFF94A3B8),
      );
    }

    if (interactionStatus == statusDocumentsRequested) {
      if (documentStatus == docUploaded) {
        return const WorkflowActionState(
          isVisible: true,
          isEnabled: false,
          label: 'Documents Submitted',
          disabledReason: 'Documents uploaded and awaiting agent review.',
          icon: Icons.upload_file_rounded,
          color: Color(0xFF3B82F6),
          backgroundColor: Color(0x1A3B82F6),
        );
      } else if (documentStatus == docUnderReview) {
        return const WorkflowActionState(
          isVisible: true,
          isEnabled: false,
          label: 'Under Review',
          disabledReason: 'Agent is currently reviewing the property documents.',
          icon: Icons.rate_review_outlined,
          color: Color(0xFFF59E0B),
          backgroundColor: Color(0x1AF59E0B),
        );
      } else if (documentStatus == docVerified) {
        return const WorkflowActionState(
          isVisible: true,
          isEnabled: false,
          label: 'Documents Completed',
          disabledReason: 'Property documents have been verified successfully.',
          icon: Icons.verified_rounded,
          color: Color(0xFF10B981),
          backgroundColor: Color(0x1A10B981),
        );
      } else if (documentStatus == docRejected) {
        return WorkflowActionState(
          isVisible: true,
          isEnabled: !isUpdating,
          label: 'Documents Rejected',
          disabledReason: 'Documents require correction or resubmission.',
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFEF4444),
          backgroundColor: const Color(0x1AEF4444),
        );
      }

      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Documents Requested',
        disabledReason: 'Document request submitted to seller and agent.',
        icon: Icons.description_outlined,
        color: Color(0xFF8B5CF6),
        backgroundColor: Color(0x1A8B5CF6),
      );
    }

    if (interactionStatus > statusDocumentsRequested) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Documents Completed',
        disabledReason: 'Legal documents stage completed.',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    // statusVisited == 3: Enabled to request documents
    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Request Documents',
      icon: Icons.description_outlined,
      color: const Color(0xFF8B5CF6),
    );
  }

  /// "Submit Offer" Button
  static WorkflowActionState getBuyerOfferAction({
    required int? interactionStatus,
    required bool isUpdating,
  }) {
    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Submit Offer',
        disabledReason: 'Inquiry is closed.',
        icon: Icons.block_rounded,
        color: Color(0xFF64748B),
      );
    }

    if (interactionStatus == null || interactionStatus < statusVisited) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Submit Offer',
        disabledReason: 'Complete a property visit before making an offer.',
        icon: Icons.lock_outline_rounded,
        color: Color(0xFF94A3B8),
      );
    }

    if (interactionStatus == statusOfferSubmitted) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Offer Submitted',
        disabledReason: 'Your offer has been submitted for review.',
        icon: Icons.local_offer_rounded,
        color: Color(0xFFEC4899),
        backgroundColor: Color(0x1AEC4899),
      );
    }

    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Submit Offer',
      icon: Icons.local_offer_outlined,
      color: const Color(0xFFEC4899),
    );
  }

  // ==========================================
  // AGENT BUTTON ELIGIBILITY
  // ==========================================

  /// Agent: Approve Visit Request
  static WorkflowActionState getAgentVisitApproveAction({
    required int visitStatus,
    required bool isUpdating,
  }) {
    final canApprove = visitStatus == visitRequested;
    return WorkflowActionState(
      isVisible: canApprove,
      isEnabled: canApprove && !isUpdating,
      label: 'Approve Visit',
      disabledReason: canApprove ? null : 'Visit is not in requested status.',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF10B981),
    );
  }

  /// Agent: Reject Visit Request
  static WorkflowActionState getAgentVisitRejectAction({
    required int visitStatus,
    required bool isUpdating,
  }) {
    final canReject = visitStatus == visitRequested;
    return WorkflowActionState(
      isVisible: canReject,
      isEnabled: canReject && !isUpdating,
      label: 'Reject Visit',
      disabledReason: canReject ? null : 'Visit cannot be rejected.',
      icon: Icons.cancel_outlined,
      color: const Color(0xFFEF4444),
    );
  }

  /// Agent: Complete Visit
  static WorkflowActionState getAgentCompleteVisitAction({
    required int interactionStatus,
    int? visitStatus,
    required bool isUpdating,
  }) {
    if (interactionStatus >= statusVisited || visitStatus == visitCompleted) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Visit Completed',
        disabledReason: 'Visit has already been completed.',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    final isEligible = interactionStatus == statusVisitRequested ||
        visitStatus == visitRequested ||
        visitStatus == visitConfirmed;

    return WorkflowActionState(
      isVisible: isEligible,
      isEnabled: isEligible && !isUpdating,
      label: 'Complete Visit',
      disabledReason: isEligible ? null : 'Visit is not in a pending state.',
      icon: Icons.task_alt_rounded,
      color: const Color(0xFF10B981),
    );
  }

  /// Agent: Document Verification Action
  static WorkflowActionState getAgentDocumentVerifyAction({
    required int documentStatus,
    required bool hasDocuments,
    required bool isUpdating,
  }) {
    if (documentStatus == docVerified) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Documents Completed',
        disabledReason: 'Documents already verified and completed.',
        icon: Icons.verified_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    final canVerify = (documentStatus == docUploaded || documentStatus == docUnderReview) && hasDocuments;
    return WorkflowActionState(
      isVisible: hasDocuments,
      isEnabled: canVerify && !isUpdating,
      label: 'Verify & Complete Documents',
      disabledReason: canVerify ? null : 'Required documents must be submitted first.',
      icon: Icons.verified_outlined,
      color: const Color(0xFF00C6D4),
    );
  }

  /// Agent: Document Rejection Action
  static WorkflowActionState getAgentDocumentRejectAction({
    required int documentStatus,
    required bool hasDocuments,
    required bool isUpdating,
  }) {
    if (documentStatus == docVerified || !hasDocuments) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Reject Documents',
        disabledReason: 'Cannot reject verified or absent documents.',
        icon: Icons.close_rounded,
        color: Color(0xFFEF4444),
      );
    }

    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Reject Documents',
      icon: Icons.thumb_down_alt_outlined,
      color: const Color(0xFFEF4444),
    );
  }

  /// Agent: Mark as Sold
  static WorkflowActionState getAgentMarkSoldAction({
    required int interactionStatus,
    required bool isUpdating,
  }) {
    if (interactionStatus == statusSold) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Sale Completed',
        disabledReason: 'Property sale has already been marked as complete.',
        icon: Icons.verified_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Mark as Sold',
        disabledReason: 'Inquiry is already closed.',
        icon: Icons.block_rounded,
        color: Color(0xFF64748B),
      );
    }

    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Mark as Sold',
      icon: Icons.monetization_on_outlined,
      color: const Color(0xFF10B981),
    );
  }

  /// Agent: Reject Inquiry
  static WorkflowActionState getAgentRejectInquiryAction({
    required int interactionStatus,
    required bool isUpdating,
  }) {
    if (interactionStatus == statusRejected) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Inquiry Rejected',
        disabledReason: 'Inquiry has been rejected.',
        icon: Icons.cancel_rounded,
        color: Color(0xFFEF4444),
        backgroundColor: Color(0x1AEF4444),
      );
    }

    if (isClosed(interactionStatus)) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Reject Inquiry',
        disabledReason: 'Cannot reject a closed inquiry.',
        icon: Icons.block_rounded,
        color: Color(0xFF64748B),
      );
    }

    return WorkflowActionState(
      isVisible: true,
      isEnabled: !isUpdating,
      label: 'Reject Inquiry',
      icon: Icons.block_rounded,
      color: const Color(0xFFEF4444),
    );
  }

  // ==========================================
  // SELLER BUTTON ELIGIBILITY
  // ==========================================

  /// Seller: Upload Documents Action
  static WorkflowActionState getSellerUploadDocumentAction({
    required int interactionStatus,
    int? documentStatus,
    required bool isOwner,
    required bool isUpdating,
  }) {
    if (!isOwner) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Upload Documents',
        disabledReason: 'Only property owner can upload documents.',
        icon: Icons.upload_file_rounded,
        color: Color(0xFF00C6D4),
      );
    }

    if (documentStatus == docVerified) {
      return const WorkflowActionState(
        isVisible: true,
        isEnabled: false,
        label: 'Documents Verified',
        disabledReason: 'All documents verified by agent.',
        icon: Icons.verified_rounded,
        color: Color(0xFF10B981),
        backgroundColor: Color(0x1A10B981),
      );
    }

    final isRequested = interactionStatus == statusDocumentsRequested;
    return WorkflowActionState(
      isVisible: isRequested,
      isEnabled: isRequested && !isUpdating,
      label: 'Upload Documents',
      disabledReason: isRequested ? null : 'No pending document requests.',
      icon: Icons.upload_file_rounded,
      color: const Color(0xFF00C6D4),
    );
  }

  /// Seller: Resubmit Documents Action (when rejected)
  static WorkflowActionState getSellerResubmitDocumentAction({
    required int? documentStatus,
    required bool isOwner,
    required bool isUpdating,
  }) {
    if (!isOwner) {
      return const WorkflowActionState(
        isVisible: false,
        isEnabled: false,
        label: 'Resubmit Documents',
        disabledReason: 'Only owner can resubmit documents.',
        icon: Icons.refresh_rounded,
        color: Color(0xFFF59E0B),
      );
    }

    final isRejected = documentStatus == docRejected;
    return WorkflowActionState(
      isVisible: isRejected,
      isEnabled: isRejected && !isUpdating,
      label: 'Resubmit Documents',
      disabledReason: isRejected ? null : 'Resubmission only allowed when documents are rejected.',
      icon: Icons.refresh_rounded,
      color: const Color(0xFFF59E0B),
    );
  }
}
