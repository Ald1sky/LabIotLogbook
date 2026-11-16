import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  final List<String> activities;

  const ActivityScreen({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: activities.isEmpty
          ? const Center(
              child: Text(
                'Belum ada aktivitas.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: activities.length,
              separatorBuilder: (context, index) {
                return const Divider(
                  height: 24,
                );
              },
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.history,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        activities[index],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
