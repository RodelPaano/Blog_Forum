import 'package:flutter/material.dart';

class HomeHeaderView extends StatelessWidget {
  const HomeHeaderView({super.key, required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final mobile = MediaQuery.of(context).size.width < 800;

    return Container(
      padding: EdgeInsets.all(mobile ? 18 : 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loggedIn ? "Welcome back!" : "Discover Stories",
                  style: TextStyle(
                    fontSize: mobile ? 20 : 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  loggedIn
                      ? "Share your thoughts with everyone."
                      : "Read amazing posts from the community.",
                ),
              ],
            ),
          ),

          Container(
            width: mobile ? 50 : 70,
            height: mobile ? 50 : 70,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              loggedIn ? Icons.edit : Icons.explore,
              size: mobile ? 28 : 36,
            ),
          ),
        ],
      ),
    );
  }
}
