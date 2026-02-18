import 'package:flutter/material.dart' as material;
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

class RideEstimationSheet extends StatefulWidget {
  final String destination;
  final VoidCallback onConfirm;
  final String? preSelectedVehicle;

  const RideEstimationSheet({
    super.key, 
    required this.destination, 
    required this.onConfirm,
    this.preSelectedVehicle,
  });

  @override
  State<RideEstimationSheet> createState() => _RideEstimationSheetState();
}

class _RideEstimationSheetState extends State<RideEstimationSheet> {
  int _selectedVehicle = 0;
  
  final List<Map<String, dynamic>> _options = [
    {
      'name': 'Car',
      'price': 250,
      'asset': 'assets/lottie/car.json',
      'isLottie': true,
      'time': '3 min',
      'desc': 'Comfortable sedan'
    },
    {
      'name': 'Bike',
      'price': 40,
      'asset': 'assets/lottie/bike.json',
      'isLottie': true,
      'time': '2 min',
      'desc': 'Fastest ride'
    },
    {
      'name': 'Scooty',
      'price': 45,
      'asset': 'assets/lottie/scotter.json',
      'isLottie': true,
      'time': '3 min',
      'desc': 'Easy ride'
    },
    {
      'name': 'Auto',
      'price': 80,
      'asset': '🛺',
      'isLottie': false,
      'time': '5 min',
      'desc': 'Spacious'
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedVehicle != null) {
      final index = _options.indexWhere((opt) => opt['name'] == widget.preSelectedVehicle);
      if (index != -1) {
        _selectedVehicle = index;
      }
    }
  }

  // Helper to build lottie appropriately
  Widget _buildAsset(Map<String, dynamic> opt) {
    if (opt['isLottie'] == true) {
      final String assetPath = opt['asset'];
      final bool isDotLottie = assetPath.endsWith('.lottie');
      
      return Lottie.asset(
        assetPath, 
        fit: BoxFit.contain,
        decoder: isDotLottie ? LottieComposition.decodeZip : null,
      );
    } else {
      return Center(child: Text(opt['asset'], style: const TextStyle(fontSize: 30)));
    }
  }

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
            height: 35.h, 
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
                        // Asset Display
                        SizedBox(
                          width: 60,
                          height: 50,
                          child: _buildAsset(opt),
                        ),
                        
                        const SizedBox(width: 16),
                        Expanded(child: Column(
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
                            Text('₹${opt['price']}').large().foreground(),
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
          ),
          
          
        ],
      ),
    );
  }
}
