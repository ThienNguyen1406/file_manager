import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/empty_state.dart';
import '../../components/file_grid_item.dart';
import '../../components/file_tile.dart';
import '../../components/folder_card.dart';
import '../../components/section_header.dart';
import '../../page/folder_detail/folder_detail_page.dart';
import '../../providers/drive_provider.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DriveProvider>(
      builder: (context, driveProvider, _) {
        final favoriteFolders = driveProvider.favoriteFolders;
        final favoriteFiles = driveProvider.favoriteFiles;
        final isEmpty = favoriteFolders.isEmpty && favoriteFiles.isEmpty;

        return Scaffold(
          body: isEmpty
              ? EmptyState(
                  icon: Icons.favorite_border,
                  title: 'Chưa có mục yêu thích',
                  subtitle: 'Thêm trái tim vào folder hoặc file để xem ở đây',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (favoriteFolders.isNotEmpty) ...[
                        Text(
                          'Thư mục yêu thích',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) => FolderCard(
                                folder: favoriteFolders[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FolderDetailPage(
                                        folder: favoriteFolders[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          itemCount: favoriteFolders.length,
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (favoriteFiles.isNotEmpty) ...[
                        SectionHeader(
                          title: 'Tập tin yêu thích',
                          showViewToggle: true,
                        ),
                        const SizedBox(height: 12),
                        Consumer<DriveProvider>(
                          builder: (context, provider, _) {
                            if (provider.viewMode == ViewMode.grid) {
                              return GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemBuilder: (context, index) =>
                                    FileGridItem(file: favoriteFiles[index]),
                                itemCount: favoriteFiles.length,
                              );
                            } else {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) =>
                                    FileTile(file: favoriteFiles[index]),
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemCount: favoriteFiles.length,
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}

