import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants/app_colors.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              // Clear logs method (optional to add to AuthProvider)
              authProvider.infoLogs.clear();
              authProvider.notifyListeners();
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: authProvider.infoLogs.isEmpty
          ? const Center(
              child: Text(
                'No logs available yet.\nTry signing in with Google.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: authProvider.infoLogs.length,
              itemBuilder: (context, index) {
                final log = authProvider.infoLogs[index];
                
                // Determine color based on log type
                Color logColor = Colors.blueGrey;
                if (log.contains('ERROR')) logColor = Colors.red;
                if (log.contains('SUCCESS')) logColor = Colors.green;
                if (log.contains('WARNING')) logColor = Colors.orange;

                return Card(
                  elevation: 0,
                  color: logColor.withValues(alpha: 0.1),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          log.contains('ERROR') 
                              ? Icons.error 
                              : log.contains('SUCCESS')
                                  ? Icons.check_circle
                                  : Icons.info,
                          color: logColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            log,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}