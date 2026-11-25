import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/firestore/models/models.dart';

String roomLabel(PropertyDoc room) => (room.roomName?.trim().isNotEmpty ?? false)
    ? room.roomName!.trim()
    : room.title;

String buildingLabel(PropertyDoc property) =>
    (property.propertyName?.trim().isNotEmpty ?? false)
    ? property.propertyName!.trim()
    : property.title;

/// Asks what to remove, naming it and how many rooms go with it.
///
/// [rooms] are the listings this screen would delete: every room of a
/// building, the one room of a room screen ([isRoomView]), or a whole-place
/// listing. [roomsInBuilding] tells a room screen whether its room is the last
/// one. With several rooms the owner can pick just one instead.
///
/// Returns the listings to delete, or null if the owner backed out.
Future<List<PropertyDoc>?> confirmListingRemoval(
  BuildContext context, {
  required List<PropertyDoc> rooms,
  required bool isRoomView,
  int roomsInBuilding = 1,
}) async {
  final first = rooms.first;
  final building = buildingLabel(first);

  if (isRoomView && first.isRoom) {
    return _confirmOneRoom(context, first, isLast: roomsInBuilding <= 1);
  }

  if (!first.isRoom) {
    final ok = await _ask(
      context,
      title: 'Remove $building?',
      message:
          'This deletes the listing for $building. This can\'t be undone.',
      action: 'Remove listing',
    );
    return ok == _Choice.remove ? rooms : null;
  }

  final count = rooms.length;
  final noun = count == 1 ? 'room' : 'rooms';
  final choice = await _ask(
    context,
    title: 'Remove $building?',
    message:
        'This deletes $count $noun: ${rooms.map(roomLabel).join(', ')}. '
        'This can\'t be undone.',
    action: count == 1 ? 'Remove 1 room' : 'Remove all $count rooms',
    offerOneRoom: count > 1,
  );
  if (choice == _Choice.remove) return rooms;
  if (choice != _Choice.pickOne || !context.mounted) return null;

  final room = await showDialog<PropertyDoc>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text('Which room in $building?', style: _titleStyle),
      children: [
        for (final r in rooms)
          SimpleDialogOption(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            onPressed: () => Navigator.of(dialogContext).pop(r),
            child: Text(roomLabel(r), style: _bodyStyle),
          ),
        SimpleDialogOption(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Cancel',
            style: _bodyStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: dialogContext.appColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
  if (room == null || !context.mounted) return null;
  return _confirmOneRoom(context, room, isLast: false);
}

Future<List<PropertyDoc>?> _confirmOneRoom(
  BuildContext context,
  PropertyDoc room, {
  required bool isLast,
}) async {
  final name = roomLabel(room);
  final building = buildingLabel(room);
  final choice = await _ask(
    context,
    title: 'Remove $name?',
    message: isLast
        ? 'This deletes $name, the only room in $building, so $building '
              'leaves your properties. This can\'t be undone.'
        : 'This deletes 1 room, $name in $building. The other rooms stay '
              'listed. This can\'t be undone.',
    action: 'Remove this room',
  );
  return choice == _Choice.remove ? [room] : null;
}

enum _Choice { remove, pickOne }

const _titleStyle = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 17,
  fontWeight: FontWeight.w800,
);

const _bodyStyle = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 14,
  height: 1.4,
);

Future<_Choice?> _ask(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool offerOneRoom = false,
}) {
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  const minimum = Size.fromHeight(48);
  const buttonText = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  return showDialog<_Choice>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.appColors;
      Widget outlined(String label, _Choice? result) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.fieldBorder),
          minimumSize: minimum,
          shape: shape,
        ),
        onPressed: () => Navigator.of(dialogContext).pop(result),
        child: Text(label, style: buttonText, textAlign: TextAlign.center),
      );

      return AlertDialog(
        backgroundColor: colors.surface,
        scrollable: true,
        title: Text(title, style: _titleStyle),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: _bodyStyle.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (offerOneRoom) ...[
              outlined('Remove one room instead', _Choice.pickOne),
              const SizedBox(height: 8),
            ],
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.destructive,
                foregroundColor: AppColors.onInk,
                minimumSize: minimum,
                shape: shape,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_Choice.remove),
              child: Text(action, style: buttonText, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            outlined('Cancel', null),
          ],
        ),
      );
    },
  );
}
