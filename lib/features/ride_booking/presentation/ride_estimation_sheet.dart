import 'package:flutter/material.dart';
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
    {'name': 'Bike', 'price': '₹45', 'time': '3 mins', 'icon': Icons.two_wheeler, 'desc': 'Fastest & Affordable'},
    {'name': 'Auto', 'price': '₹65', 'time': '5 mins', 'icon': Icons.local_taxi, 'desc': 'Doorstep Pickup'},
    {'name': 'Mini', 'price': '₹90', 'time': '8 mins', 'icon': Icons.directions_car, 'desc': 'Comfy Hatchbacks'},
    {'name': 'Sedan', 'price': '₹120', 'time': '10 mins', 'icon': Icons.directions_car_filled, 'desc': 'Top Rated Drivers'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600];
    final selectedColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey[100];
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Available Rides to ${widget.destination}", 
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor)
            ),
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
                return InkWell(
                  onTap: () => setState(() => _selectedVehicle = index),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor : backgroundColor,
                      border: Border.all(
                        color: isSelected ? (isDark ? Colors.white : Colors.black) : borderColor, 
                        width: isSelected ? 2 : 1
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/${opt['name'].toString().toLowerCase()}.png', 
                          width: 60, 
                          height: 40, 
                          errorBuilder: (c, e, s) => Icon(opt['icon'], size: 40, color: textColor)
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(opt['name'], style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor)),
                              Text(opt['desc'], style: TextStyle(fontSize: 10.sp, color: secondaryTextColor)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(opt['price'], style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor)),
                            Text(opt['time'], style: TextStyle(fontSize: 10.sp, color: secondaryTextColor)),
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
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: ElevatedButton(
                    onPressed: widget.onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Book ${_options[_selectedVehicle]['name']}", style: TextStyle(fontSize: 14.sp)),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, size: 20)
                      ],
                    ),
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
