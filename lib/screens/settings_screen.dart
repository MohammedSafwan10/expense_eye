import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:expense_eye/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            subtitle: Text(
              'Currently ${context.select<ThemeProvider, String>((provider) => provider.themeModeText)}',
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => const _ThemeModeDialog(),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Data Management'),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all expenses permanently'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data'),
                  content: const Text(
                    'Are you sure you want to delete all expenses? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Provider.of<ExpenseProvider>(context, listen: false)
                            .clearAllData();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All data cleared'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About ExpenseEye'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ExpenseEye',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: Color(0xFF6750A4),
                ),
                children: [
                  const Text(
                    'ExpenseEye is a simple and efficient expense tracking app that helps you manage your daily expenses.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeModeDialog extends StatelessWidget {
  const _ThemeModeDialog();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                subtitle: const Text('Light theme for better visibility'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                subtitle: const Text('Dark theme for better eye comfort'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
