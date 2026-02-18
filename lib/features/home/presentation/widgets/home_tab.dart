import 'dart:async';
import 'package:flutter/material.dart' as material;
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';
import 'package:rido/core/theme/ui_theme.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;
  final Function(String) onVehicleSelected;

  const HomeTab({
    super.key,
    required this.onMenuTap,
    required this.onNotificationTap,
    required this.onSearchTap,
    required this.onVehicleSelected,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Carousel State
  final PageController _pageController = PageController();
  int _currentSlide = 0;
  Timer? _carouselTimer;
  
  final List<Map<String, dynamic>> _slides = [
    {
      'title': "Electrify your ride",
      'subtitle': "Built with love for Dhamtari",
      'asset': 'assets/lottie/taxi app.json',
      'isLottie': false, 
    },
    {
      'title': "Fast & Request",
      'subtitle': "Book your ride in seconds",
      'asset': 'assets/lottie/ride 2.json',
    },
    {
      'title': "Share & Save",
      'subtitle': "Carpooling made easy",
      'asset': 'assets/lottie/carpool.json',
    },
    {
      'title': "Community First",
      'subtitle': "Safe & Secure Payments",
      'asset': 'assets/lottie/Payments.json',
    },
  ];

  // Vehicle Selection State
  String? _selectedVehicle; 
  
  // Vehicles Data
  final List<Map<String, dynamic>> _vehicles = [
    {'name': 'Car', 'asset': 'assets/lottie/car.json', 'isLottie': true, 'discount': 'Popular'},
    {'name': 'Bike', 'asset': 'assets/lottie/bike.json', 'isLottie': true},
    {'name': 'Scooty', 'asset': 'assets/lottie/scotter.json', 'isLottie': true},
    {'name': 'Auto', 'asset': '🛺', 'isLottie': false},
  ];

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int next = _pageController.page!.round() + 1;
        if (next >= _slides.length) {
          next = 0;
        }
        _pageController.animateToPage(
          next, 
          duration: const Duration(milliseconds: 600), 
          curve: Curves.easeInOut
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return material.SafeArea(
      child: material.SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Menu (Left) -- Notification (Right)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Button.ghost(
                  onPressed: widget.onMenuTap,
                  child: const Icon(LucideIcons.menu, size: 24),
                ),
                Button.ghost(
                  onPressed: widget.onNotificationTap,
                  child: const Icon(LucideIcons.bell, size: 24),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // 2. Banner Carousel
            SizedBox(
              height: 22.h,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentSlide = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4), 
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: material.Colors.transparent, // Transparent background
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                         Positioned(
                           right: -20,
                           bottom: -10,
                           child: Lottie.asset(
                             slide['asset'],
                             height: 22.h,
                             fit: BoxFit.contain,
                             errorBuilder: (ctx, err, stack) => const SizedBox(), 
                           ),
                         ),
                         Padding(
                           padding: const EdgeInsets.all(20),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               // Gradient and Faded Title (Purple)
                               ShaderMask(
                                 shaderCallback: (bounds) => const LinearGradient(
                                   colors: [material.Color(0xFF8B5CF6), material.Color(0x888B5CF6)], // Purple Gradient
                                   begin: Alignment.centerLeft,
                                   end: Alignment.centerRight,
                                 ).createShader(bounds),
                                 child: SizedBox(
                                   width: 60.w, // Limit width to avoid overlap
                                   child: Text(
                                     slide['title'],
                                     style: const TextStyle(
                                       color: material.Colors.white, 
                                       fontSize: 24, // Smaller size
                                       fontWeight: FontWeight.bold
                                     ),
                                   ),
                                 ),
                               ),
                               const SizedBox(height: 8),
                               Text(slide['subtitle']).small().muted(),
                               const Spacer(),
                             ],
                           ),
                         )
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Carousel Indicators
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                 return AnimatedContainer(
                   duration: const Duration(milliseconds: 300),
                   margin: const EdgeInsets.symmetric(horizontal: 4),
                   width: _currentSlide == index ? 20 : 8,
                   height: 8,
                   decoration: BoxDecoration(
                     color: _currentSlide == index 
                         ? theme.colorScheme.primary 
                         : theme.colorScheme.muted,
                     borderRadius: BorderRadius.circular(4)
                   ),
                 );
              }),
            ),
            
            const SizedBox(height: 25),
            
            // 3. Vehicle Selector (Suggestions)
            Text("Suggestions").h4().foreground(),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _vehicles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final v = _vehicles[index];
                  return _buildVehicleOption(
                     name: v['name'],
                     asset: v['asset'],
                     isLottie: v['isLottie'],
                     discount: v['discount']
                  );
                },
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 4. Where To? Search Bar (Uber Style)
            GestureDetector(
              onTap: widget.onSearchTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                   children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.search, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Text("Where to?").h4().foreground(),
                   ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 5. Recent Locations
            Column(
              children: [
                _buildLocationItem(icon: LucideIcons.house, title: "Home", subtitle: "Dhamtari, CG"),
                const Divider(),
                _buildLocationItem(icon: LucideIcons.briefcase, title: "Work", subtitle: "Rudri Road"),
              ],
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildVehicleOption({
    required String name, 
    required String asset, 
    bool isLottie = false,
    String? discount
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedVehicle == name;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedVehicle = name);
        widget.onVehicleSelected(name);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const material.Color(0xFF8B5CF6) : theme.colorScheme.border,
                width: isSelected ? 3 : 1
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 if (isLottie) 
                   Lottie.asset(
                     asset, 
                     height: name == 'Scooty' || name == 'Bike' ? 70 : 60, // Increased size for all, esp Scooty/Bike
                     repeat: true
                   )
                 else 
                   Text(asset, style: const TextStyle(fontSize: 40)),
                 const SizedBox(height: 8),
                 Text(name).medium().foreground(),
              ],
            ),
          ),
          if (discount != null)
            Positioned(
              top: -10,
              right: 0,
              left: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const material.Color(0xFF8B5CF6), // Purple
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(discount, style: const material.TextStyle(color: material.Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildLocationItem({required IconData icon, required String title, required String subtitle}) {
     return Opacity(
       opacity: 0.6, // Disabled look
       child: material.ListTile(
          leading: Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: const material.Color(0xFF8B5CF6).withOpacity(0.1), // Purplish accent background
               shape: BoxShape.circle
             ),
             child: Icon(icon, size: 20, color: const material.Color(0xFF8B5CF6)), // Purple Icon
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          onTap: null, // Disabled interaction as requested ("make theme disabled for now")
       ),
     );
  }
}
