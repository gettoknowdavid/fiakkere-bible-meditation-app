import 'package:flutter/material.dart';
import 'package:models/models.dart';

class PlaylistItemTile extends StatelessWidget {
  PlaylistItemTile({
    required this.index,
    required this.item,
    required this.onRemove,
    Key? key,
  }) : super(key: key ?? ValueKey(item.id));

  /// This item's position within the currently rendered list — required by
  /// [ReorderableDragStartListener] so the framework knows which entry is
  /// being dragged. Must match the index this tile was built at inside the
  /// enclosing [ReorderableListView.builder], not the item's `sortOrder`.
  final int index;

  final PlaylistItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final verse = item.verse.target;
    if (verse == null) return const SizedBox.shrink();
    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: const Icon(Icons.drag_handle),
      ),
      title: Text(
        verse.reference,
        style: Theme.of(context).textTheme.labelLarge,
      ),
      subtitle: Text(verse.text, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline),
        onPressed: onRemove,
      ),
    );
  }
}
