import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:walt/data/models/walt_category.dart';
import 'package:walt/data/services/image_store.dart';
import 'package:walt/features/categories/category_presets.dart';
import 'package:walt/providers/category_provider.dart';
import 'package:walt/shared/widgets/category_artwork.dart';
import 'package:walt/shared/widgets/category_picker.dart';
import 'package:walt_ui/walt_ui.dart';

/// Opens the category editor. [category] null creates a new category; passing
/// one edits it. The saved category is returned, so callers can select a newly
/// created category immediately.
Future<WaltCategory?> showCategoryEditor(
  BuildContext context, {
  WaltCategory? category,
}) {
  return showWaltModal<WaltCategory>(
    context,
    content: CategoryEditorSheet(category: category),
    heightFactor: 0.92,
  );
}

/// Offers edit/delete for a category, the action behind a long-press.
///
/// Returns true when the category was deleted, so the caller can clear a
/// selection that now points at nothing.
Future<bool> showCategoryActions(
  BuildContext context, {
  required WaltCategory category,
}) async {
  final deleted = await showWaltModal<bool>(
    context,
    heightFactor: 0.42,
    content: _CategoryActionsSheet(category: category),
  );
  return deleted ?? false;
}

/// A readable list of every category, for the "Manage categories" menu entry.
Future<void> showCategoryManager(BuildContext context) {
  return showWaltModal<void>(
    context,
    heightFactor: 0.9,
    content: const _CategoryManagerSheet(),
  );
}

/// Confirms and deletes [category], reporting every refusal in place.
///
/// Shared by the editor's delete button and the long-press action sheet so both
/// entry points enforce the same policy and say the same thing when it refuses.
/// Returns true only when the row was actually removed.
Future<bool> confirmAndDeleteCategory(
  BuildContext context,
  CategoryNotifier notifier,
  WaltCategory category,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete category?'),
      content: Text(
        '"${category.name}" will be removed. Categories used by '
        'transactions or budgets cannot be deleted.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;

  String? failure;
  try {
    await notifier.deleteCategory(category);
  } on CategoryInUseException catch (e) {
    final parts = <String>[
      if (e.transactionCount > 0)
        '${e.transactionCount} transaction${e.transactionCount == 1 ? '' : 's'}',
      if (e.budgetCount > 0)
        '${e.budgetCount} budget${e.budgetCount == 1 ? '' : 's'}',
    ];
    failure =
        '“${category.name}” is used by ${parts.join(' and ')}. '
        'Move those to another category first.';
  } on CategoryDefaultException {
    failure = 'Default categories cannot be deleted.';
  } catch (e) {
    failure = 'Could not delete the category.';
    debugPrint('CategoryEditor: delete failed — $e');
  }

  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failure ?? '“${category.name}” deleted')),
  );
  return failure == null;
}

class CategoryEditorSheet extends ConsumerStatefulWidget {
  const CategoryEditorSheet({super.key, this.category});

  final WaltCategory? category;

  @override
  ConsumerState<CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _type;
  late String _icon;
  late String _color;
  late CategoryImageSource _imageSource;
  String? _imagePath;

  bool _saving = false;

  /// A new category has no stored accent yet, so the first build waits for
  /// [didChangeDependencies] to read the active scheme and adopt a swatch.
  bool _awaitingThemeColor = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _type = category?.type ?? 'expense';
    _icon = category?.icon ?? 'category';
    // `didChangeDependencies` replaces this with the scheme's first swatch
    // before the first build, where `Theme.of` is legal.
    _color = category?.color ?? '';
    _awaitingThemeColor = category == null;
    _imageSource = category?.imageSource ?? CategoryImageSource.asset;
    _imagePath = category?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(CategoryPreset preset) {
    setState(() {
      _imageSource = CategoryImageSource.asset;
      _imagePath = preset.asset;
      _icon = preset.icon;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = preset.name;
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked == null) return;
      final relative = await ImageStore.importCategoryImage(picked.path);
      if (!mounted) return;
      if (relative == null) {
        _showError('Could not save that image. Try another one.');
        return;
      }
      setState(() {
        _imageSource = CategoryImageSource.file;
        _imagePath = relative;
      });
    } catch (e) {
      if (!mounted) return;
      _showError('Could not open the gallery.');
      debugPrint('CategoryEditor: image pick failed — $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final notifier = ref.read(categoryProvider.notifier);
    try {
      WaltCategory saved;
      if (_isEditing) {
        saved = widget.category!.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          icon: _icon,
          color: _color,
          imageSource: _imageSource,
          imagePath: _imagePath,
        );
        await notifier.updateCategory(saved);
      } else {
        saved = await notifier.createCategory(
          name: _nameController.text,
          type: _type,
          color: _color,
          icon: _icon,
          imageSource: _imageSource,
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, saved);
    } on CategoryNameTakenException catch (e) {
      _showError(e.toString());
    } on CategoryValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Could not save the category.');
      debugPrint('CategoryEditor: save failed — $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final category = widget.category;
    if (category == null) return;

    final deleted = await confirmAndDeleteCategory(
      context,
      ref.read(categoryProvider.notifier),
      category,
    );
    if (!mounted || !deleted) return;
    Navigator.pop(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_awaitingThemeColor) return;
    _awaitingThemeColor = false;
    // `initState` cannot read the theme, so a brand-new category starts empty.
    // Adopt a real swatch here, before the first build and before the user can
    // pick one — an edited category keeps its stored colour.
    _color = _swatchHexes(Theme.of(context)).first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = WaltCategory(
      id: widget.category?.id ?? -1,
      name: _nameController.text.trim().isEmpty
          ? 'Category'
          : _nameController.text.trim(),
      icon: _icon,
      color: _color,
      type: _type,
      isDefault: widget.category?.isDefault ?? false,
      imageSource: _imageSource,
      imagePath: _imagePath,
    );

    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: waltModalPadding(context),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Edit category' : 'New category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              CategoryArtwork(
                category: preview,
                size: 72,
                radius: AppRadius.lg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _imagePath == null
                          ? 'No image yet'
                          : 'Your category artwork',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Pick a bundled image below or import one from your '
                      'gallery. Imported images are copied into Walt and never '
                      'uploaded.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          InputUI(
            controller: _nameController,
            labelText: 'Name',
            hintText: 'e.g. Groceries',
            icon: Icons.label_outline,
            textInputAction: TextInputAction.done,
            onchange: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Type', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          PillSwitcher<String>(
            value: _type,
            options: const ['expense', 'income'],
            labelBuilder: (type) => type == 'income' ? 'Income' : 'Expense',
            iconBuilder: (type) => type == 'income'
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            semanticLabel: 'Category type',
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: Text('Artwork', style: theme.textTheme.labelLarge),
              ),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Import'),
              ),
              if (_imagePath != null)
                IconButton(
                  tooltip: 'Remove image',
                  onPressed: () => setState(() => _imagePath = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categoryPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final preset = categoryPresets[index];
                final selected =
                    _imageSource == CategoryImageSource.asset &&
                    _imagePath == preset.asset;
                return SizedBox(
                  width: 64,
                  child: CategoryTile(
                    category: preset.toCategory(id: -(index + 1)),
                    selected: selected,
                    onTap: () => _applyPreset(preset),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Colour', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          _SwatchGrid(
            selected: _color,
            onSelected: (hex) => setState(() => _color = hex),
          ),
          const SizedBox(height: AppSpacing.xl),

          AppButton(
            label: _isEditing ? 'Save changes' : 'Create category',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
            isFullWidth: true,
            size: ButtonSize.large,
          ),
          if (_isEditing) ...[
            const SizedBox(height: AppSpacing.md),
            if (widget.category!.isDefault)
              Text(
                'Default categories cannot be deleted.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              AppButton(
                label: 'Delete category',
                onPressed: _delete,
                type: ButtonType.text,
                isDestructive: true,
                isFullWidth: true,
                icon: Icons.delete_outline,
              ),
          ],
        ],
      ),
    );
  }
}

class _CategoryActionsSheet extends ConsumerWidget {
  const _CategoryActionsSheet({required this.category});

  final WaltCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: waltModalPadding(context),
      children: [
        Row(
          children: [
            CategoryArtwork(category: category, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Edit category'),
          onTap: () async {
            final host = Navigator.of(context).context;
            Navigator.pop(context);
            await showCategoryEditor(host, category: category);
          },
        ),
        if (!category.isDefault)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: scheme.error),
            title: Text(
              'Delete category',
              style: TextStyle(color: scheme.error),
            ),
            onTap: () async {
              final notifier = ref.read(categoryProvider.notifier);
              final deleted = await confirmAndDeleteCategory(
                context,
                notifier,
                category,
              );
              if (!context.mounted) return;
              if (deleted) Navigator.pop(context, true);
            },
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Default categories cannot be deleted.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

class _CategoryManagerSheet extends ConsumerWidget {
  const _CategoryManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);
    final theme = Theme.of(context);

    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: InlineErrorView(
          message: 'Could not load categories',
          onRetry: () => ref.read(categoryProvider.notifier).refresh(),
        ),
      ),
      data: (all) => ListView(
        padding: waltModalPadding(context),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage categories',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final category in all)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CategoryArtwork(category: category, size: 40),
              title: Text(category.name),
              subtitle: Text(
                '${category.type == 'income' ? 'Income' : 'Expense'}'
                '${category.isDefault ? ' · Default' : ''}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final host = Navigator.of(context).context;
                Navigator.pop(context);
                await showCategoryEditor(host, category: category);
              },
            ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'New category',
            icon: Icons.add_rounded,
            onPressed: () async {
              final host = Navigator.of(context).context;
              Navigator.pop(context);
              await showCategoryEditor(host);
            },
            type: ButtonType.secondary,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _SwatchGrid extends StatelessWidget {
  const _SwatchGrid({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final hexes = _swatchHexes(Theme.of(context), current: selected);
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final hex in hexes)
          Semantics(
            button: true,
            selected: hex.toLowerCase() == selected.toLowerCase(),
            label: 'Accent colour $hex',
            child: InkWell(
              onTap: () => onSelected(hex),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _parseHex(hex),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hex.toLowerCase() == selected.toLowerCase()
                          ? scheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: hex.toLowerCase() == selected.toLowerCase()
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color:
                              ThemeData.estimateBrightnessForColor(
                                    _parseHex(hex),
                                  ) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color _parseHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  return value == null ? const Color(0xFF5E6B78) : Color(0xFF000000 | value);
}

/// Theme-derived accent choices. A fixed rainbow of literal hex values is the
/// one thing the design system forbids, so these are generated from the active
/// scheme's hues and brightness. The currently stored colour is prepended when
/// it is not already present, so editing never silently changes it.
List<String> _swatchHexes(ThemeData theme, {String? current}) {
  final scheme = theme.colorScheme;
  final dark = theme.brightness == Brightness.dark;
  final double lightness = dark ? 0.66 : 0.42;

  Color tone(double hue) =>
      HSLColor.fromAHSL(1, hue, 0.48, lightness).toColor();

  String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  final primaries = <Color>[
    scheme.primary,
    scheme.secondary,
    scheme.tertiary,
    scheme.error,
    tone(15),
    tone(45),
    tone(95),
    tone(150),
    tone(195),
    tone(230),
    tone(280),
    tone(330),
  ];

  final seen = <String>{};
  final result = [
    if (current != null && current.trim().isNotEmpty) current,
    for (final color in primaries)
      if (seen.add(hex(color).toLowerCase())) hex(color),
  ];
  // Normalise and de-duplicate the prepended current value too.
  final unique = <String>[];
  final lowered = <String>{};
  for (final hexValue in result) {
    if (lowered.add(hexValue.toLowerCase())) unique.add(hexValue);
  }
  return unique;
}

/// Resolves a category's persisted colour to a Flutter [Color].
Color categoryColor(WaltCategory category) => _parseHex(category.color);
