import 'package:flutter/material.dart';

class PointingButton extends StatelessWidget {
  final bool isPointed;
  final VoidCallback onTap;
  final Color? baseColor;
  final double size;
  final String? tooltip;

  const PointingButton({
    super.key,
    required this.isPointed,
    required this.onTap,
    this.baseColor,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = baseColor ?? Theme.of(context).primaryColor;
    
    return Tooltip(
      message: tooltip ?? (isPointed ? 'Dépointer' : 'Pointer'),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isPointed ? Colors.green.shade100 : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(
              color: isPointed ? Colors.green.shade400 : color.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isPointed
                ? [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(
            isPointed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isPointed ? Colors.green.shade700 : color,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}

class PointingStatus extends StatelessWidget {
  final bool isPointed;
  final String? pointedAt;
  final bool showDate;

  const PointingStatus({
    super.key,
    required this.isPointed,
    this.pointedAt,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPointed) return const SizedBox.shrink();

    DateTime? date;
    if (pointedAt != null) {
      date = DateTime.tryParse(pointedAt!);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Pointé',
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showDate && date != null) ...[
            const SizedBox(width: 4),
            Text(
              '${date.day}/${date.month}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BatchPointingBar extends StatelessWidget {
  final int selectedCount;
  final bool isProcessing;
  final VoidCallback onPoint;
  final VoidCallback onCancel;
  final String itemType; // 'dépense' ou 'charge'

  const BatchPointingBar({
    super.key,
    required this.selectedCount,
    required this.isProcessing,
    required this.onPoint,
    required this.onCancel,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: selectedCount > 0 ? 80 : 0,
      child: selectedCount > 0
          ? Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$selectedCount $itemType${selectedCount > 1 ? 's' : ''} sélectionnée${selectedCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Prêt pour le pointage en lot',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: isProcessing ? null : onCancel,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isProcessing ? null : onPoint,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.flash_on),
                    label: Text(
                      isProcessing ? 'En cours...' : 'Pointer',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}