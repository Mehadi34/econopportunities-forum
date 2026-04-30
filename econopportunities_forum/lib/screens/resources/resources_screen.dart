import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/resource_model.dart';
import '../../providers/resources_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [null, ...ResourceCategory.values];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tabLabel(ResourceCategory? cat) {
    if (cat == null) return 'All';
    switch (cat) {
      case ResourceCategory.study:
        return 'Study';
      case ResourceCategory.events:
        return 'Events';
      case ResourceCategory.templates:
        return 'Templates';
      case ResourceCategory.gallery:
        return 'Gallery';
      case ResourceCategory.reports:
        return 'Reports';
      case ResourceCategory.other:
        return 'Other';
    }
  }

  Future<void> _uploadResource() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');
      const storage = StorageService();
      final file = File(picked.path);
      final result = await storage.uploadResource(file, 'other');
      if (result == null) throw Exception('Upload failed');

      final resource = ResourceModel(
        id: '',
        title: result['fileName'] ?? 'Resource',
        description: '',
        uploadedBy: currentUser.uid,
        uploadedByName: currentUser.displayName,
        type: ResourceType.image,
        category: ResourceCategory.other,
        fileUrl: result['fileUrl'],
        fileName: result['fileName'],
        fileSize: result['fileSize'],
        createdAt: DateTime.now(),
      );
      await ref.read(firestoreServiceProvider).createResource(resource);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resource uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isUploading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resources'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: _tabs.map((c) => Tab(text: _tabLabel(c))).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _tabs
              .map((c) => _ResourceList(category: c))
              .toList(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _uploadResource,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload'),
        ),
      ),
    );
  }
}

class _ResourceList extends ConsumerWidget {
  final ResourceCategory? category;
  const _ResourceList({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider(category));

    return resourcesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (resources) {
        if (resources.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.folder_outlined,
            title: 'No resources yet',
            subtitle: 'Upload the first resource!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resources.length,
          itemBuilder: (_, i) => _ResourceCard(resource: resources[i]),
        );
      },
    );
  }
}

class _ResourceCard extends ConsumerWidget {
  final ResourceModel resource;
  const _ResourceCard({required this.resource});

  IconData get _typeIcon {
    switch (resource.type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf;
      case ResourceType.image:
        return Icons.image;
      case ResourceType.video:
        return Icons.video_file;
      case ResourceType.document:
        return Icons.description;
      case ResourceType.link:
        return Icons.link;
      case ResourceType.other:
        return Icons.attach_file;
    }
  }

  Future<void> _download(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(firestoreServiceProvider)
          .incrementDownloadCount(resource.id);
      final url = resource.fileUrl ?? resource.link;
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening resource...')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (resource.description.isNotEmpty)
                    Text(
                      resource.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (resource.fileSizeFormatted.isNotEmpty)
                        Text(resource.fileSizeFormatted,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      if (resource.fileSizeFormatted.isNotEmpty)
                        const Text(' · ',
                            style: TextStyle(color: AppColors.textSecondary)),
                      const Icon(Icons.download, size: 12,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 2),
                      Text('${resource.downloadCount}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.primary),
              onPressed: () => _download(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
