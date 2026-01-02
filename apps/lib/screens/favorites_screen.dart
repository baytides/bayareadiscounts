import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/programs_provider.dart';
import '../widgets/program_card.dart';
import '../config/theme.dart';
import '../services/export_service.dart';
import 'program_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => FavoritesScreenState();
}

class FavoritesScreenState extends State<FavoritesScreen> {
  Future<void> _exportPrograms(List<dynamic> favorites) async {
    final success = await ExportService.saveAndShareCsv(
      favorites.cast(),
      context,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Programs exported successfully'
              : 'Failed to export programs'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _printPrograms(List<dynamic> favorites) async {
    final success = await ExportService.printPrograms(favorites.cast());
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to prepare print preview'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyAllToClipboard(List<dynamic> favorites) async {
    await ExportService.copyAllToClipboard(favorites.cast());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Programs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Programs'),
        actions: [
          Consumer<ProgramsProvider>(
            builder: (context, provider, child) {
              final favorites = provider.favoritePrograms;
              if (favorites.isEmpty) return const SizedBox.shrink();

              // Show action buttons only when there are favorites
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Copy to clipboard button
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy to clipboard',
                    onPressed: () => _copyAllToClipboard(favorites),
                  ),
                  // Export button (desktop only shows both, mobile shows menu)
                  if (isDesktop) ...[
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Export to CSV',
                      onPressed: () => _exportPrograms(favorites),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      tooltip: 'Print',
                      onPressed: () => _printPrograms(favorites),
                    ),
                  ] else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'export':
                            _exportPrograms(favorites);
                            break;
                          case 'print':
                            _printPrograms(favorites);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: ListTile(
                            leading: Icon(Icons.download),
                            title: Text('Export to CSV'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: ListTile(
                            leading: Icon(Icons.print),
                            title: Text('Print'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ProgramsProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favoritePrograms;

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved programs yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon on any program\nto save it for later',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              // Use grid layout on desktop
              if (isDesktop && constraints.maxWidth >= 600) {
                int crossAxisCount;
                if (constraints.maxWidth >= 1200) {
                  crossAxisCount = 4;
                } else if (constraints.maxWidth >= 900) {
                  crossAxisCount = 3;
                } else {
                  crossAxisCount = 2;
                }

                const cardHeight = 340.0;
                final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16 - 32) / crossAxisCount;
                final aspectRatio = cardWidth / cardHeight;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final program = favorites[index];
                    return ProgramCard(
                      program: program,
                      isFavorite: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ProgramDetailScreen(
                              program: program,
                            ),
                          ),
                        );
                      },
                      onFavoriteToggle: () {
                        provider.toggleFavorite(program.id);
                      },
                    );
                  },
                );
              }

              // List view for mobile
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final program = favorites[index];
                  return ProgramCard(
                    program: program,
                    isFavorite: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProgramDetailScreen(
                            program: program,
                          ),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      provider.toggleFavorite(program.id);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
