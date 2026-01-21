import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:rido/core/theme/ui_theme.dart';
import 'package:animation_list/animation_list.dart';
import 'package:lottie/lottie.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Dummy Data
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Ride Completed',
      'body': 'Your ride to Intuit Inc. has been completed successfully.',
      'time': '2 mins ago',
      'icon': LucideIcons.check,
      'isRead': false,
      'color': Colors.green,
    },
    {
      'id': '2',
      'title': 'Driver Arrived',
      'body': 'Your driver Kafil is waiting at the pickup location.',
      'time': '10 mins ago',
      'icon': LucideIcons.car,
      'isRead': true,
      'color': Colors.blue,
    },
    {
      'id': '3',
      'title': 'Promo Code',
      'body': 'Use code RIDO50 to get 50% off on your next ride!',
      'time': '1 hour ago',
      'icon': LucideIcons.ticket,
      'isRead': true,
      'color': Colors.purple,
    },
     {
      'id': '4',
      'title': 'System Update',
      'body': 'We have updated our privacy policy. Please review it.',
      'time': '1 day ago',
      'icon': LucideIcons.info,
      'isRead': true,
      'color': Colors.orange,
    },
  ];

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _notifications.removeWhere((n) => _selectedIds.contains(n['id']));
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSingle(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return material.Container(
      color: theme.colorScheme.background,
      child: material.SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_isSelectionMode)
                     material.IconButton(
                      icon: Icon(LucideIcons.x, color: theme.colorScheme.foreground),
                      onPressed: () => setState(() {
                        _selectedIds.clear();
                        _isSelectionMode = false;
                      }),
                    )
                  else
                    material.IconButton(
                      icon: Icon(LucideIcons.menu, color: theme.colorScheme.foreground),
                      onPressed: () => material.Scaffold.of(context).openDrawer(),
                    ),
                  const SizedBox(width: 8),
                  if (_isSelectionMode)
                    Text("${_selectedIds.length} Selected", style: theme.typography.h4.copyWith(color: theme.colorScheme.foreground))
                  else
                    Text("Notifications", style: theme.typography.h4.copyWith(color: theme.colorScheme.foreground)),
                  const Spacer(),
                  if (_isSelectionMode)
                     material.IconButton(
                      icon: Icon(LucideIcons.trash2, color: theme.colorScheme.destructive),
                      onPressed: _deleteSelected,
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/lottie/empty_notifications.json',
                            width: 200,
                            height: 200,
                            errorBuilder: (c, e, s) => Icon(LucideIcons.bellOff, size: 64, color: theme.colorScheme.mutedForeground),
                          ),
                          const SizedBox(height: 16),
                          Text("No Notifications", style: theme.typography.large.copyWith(fontWeight: FontWeight.bold)),
                          Text("You're all caught up!", style: theme.typography.small.copyWith(color: theme.colorScheme.mutedForeground)),
                        ],
                      ),
                    )
                  : AnimationList(
                      children: _notifications.map((notification) {
                        final isSelected = _selectedIds.contains(notification['id']);
                        return _buildNotificationItem(context, notification, isSelected);
                      }).toList(),
                      duration: 1000,
                      reBounceDepth: 10.0,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> notification, bool isSelected) {
    final theme = Theme.of(context);
    final id = notification['id'] as String;
    
    return material.Dismissible(
      key: Key(id),
      direction: material.DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.destructive,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteSingle(id),
      child: material.GestureDetector(
        onLongPress: () => _toggleSelection(id),
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(id);
          } else {
             // Mark as read or navigate
             setState(() => notification['isRead'] = true);
          }
        },
        child: Container(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (notification['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification['icon'] as IconData, color: notification['color'] as Color, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(notification['title'] as String).medium().foreground()),
                        Text(notification['time'] as String).small().muted(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'] as String,
                      style: theme.typography.small.copyWith(
                        color: theme.colorScheme.mutedForeground,
                         fontSize: 13
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Unread Indicator
              if (!(notification['isRead'] as bool))
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 20),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
