import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:sizer/sizer.dart';

class RideEstimationSheet extends StatefulWidget {
  final String destination;
  final VoidCallback onConfirm;

  const RideEstimationSheet({super.key, required this.destination, required this.onConfirm});

  @override
  State<RideEstimationSheet> createState() => _RideEstimationSheetState();
}

class _RideEstimationSheetState extends State<RideEstimationSheet> {
  int _selectedVehicle = 0;
  
  final List<Map<String, dynamic>> _options = [
    {'name': 'Bike', 'price': '₹45', 'time': '3 mins', 'icon': LucideIcons.bike, 'desc': 'Fastest & Affordable'},
    {'name': 'Auto', 'price': '₹65', 'time': '5 mins', 'icon': LucideIcons.carTaxiFront, 'desc': 'Doorstep Pickup'},
    {'name': 'Mini', 'price': '₹90', 'time': '8 mins', 'icon': LucideIcons.car, 'desc': 'Comfy Hatchbacks'},
    {'name': 'Sedan', 'price': '₹120', 'time': '10 mins', 'icon': LucideIcons.carFront, 'desc': 'Top Rated Drivers'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 50, 
              height: 5, 
              decoration: BoxDecoration(color: theme.colorScheme.muted, borderRadius: BorderRadius.circular(10))
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Available Rides to ${widget.destination}", 
            ).h4().foreground(),
          ),
          SizedBox(
            height: 25.h,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final opt = _options[index];
                final isSelected = _selectedVehicle == index;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedVehicle = index),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.1) 
                          : theme.colorScheme.background,
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.border,
                        width: isSelected ? 2 : 1
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Try to load asset, fallback to icon
                        SizedBox(
                          width: 60,
                          height: 40,
                          child: Icon(opt['icon'], size: 32, color: theme.colorScheme.foreground),
                        ),
                        // Note: If you have actual assets, you can keep the Image.asset logic with errorBuilder
                        // For now using Icons for consistency with shadcn style clean look
                        
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opt['name']).medium().foreground(),
                              Text(opt['desc']).small().muted(),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(opt['price']).large().foreground(),
                            Text(opt['time']).small().muted(),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5.w),
            child: material.SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Button.primary(
                    onPressed: widget.onConfirm,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Book ${_options[_selectedVehicle]['name']}"),
                        const SizedBox(width: 10),
                        const Icon(LucideIcons.arrowRight, size: 20)
                      ],
                    ),
                  ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
