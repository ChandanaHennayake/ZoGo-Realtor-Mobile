import 'package:flutter/material.dart';
import '../../../buyer/presentation/widgets/notifications_sheet.dart';

class HomeHeader extends StatelessWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onClearSearch;

  const HomeHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClearSearch,
  });

  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color accentPink = Color(0xFFFF2D7A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: const BoxDecoration(
        color: primaryCyan,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const Spacer(),

              const Text(
                'ZoGo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => NotificationsSheet.show(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: accentPink,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryCyan,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              onSubmitted: onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search location, property, reference...',
                hintStyle: const TextStyle(
                  color: Color(0xFF9AA3AF),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: primaryCyan,
                ),
                suffixIcon: (searchController != null && searchController!.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: onClearSearch,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
