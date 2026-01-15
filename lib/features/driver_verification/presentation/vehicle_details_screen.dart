import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:sizer/sizer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Bike'; // Default
  String? _carType;
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _fuelController = TextEditingController();
  final Logger _logger = Logger();
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Auto', 'Bike', 'Scooter', 'Car'];
  final List<String> _carTypes = ['Sedan', 'SUV', 'Hatchback', 'Luxury'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == 'Car' && _carType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select Car Type")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'vehicle': {
          'type': _selectedType,
          'car_type': _carType,
          'model': _modelController.text,
          'plate': _plateController.text,
          'fuel': _fuelController.text,
        },
        'verification_status': 'pending', 
        'step': 2 // Completed
      });

      if (mounted) context.go('/driver-home'); // Pending Verification State 

    } catch (e) {
      _logger.e(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Vehicle Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100, // Fixed height for tiles
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _vehicleTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final type = _vehicleTypes[index];
                    final isSelected = _selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = type),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getIconForType(type), 
                              color: isSelected ? Colors.white : Colors.black,
                              size: 30,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              type, 
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedType == 'Car') ...[
                 DropdownButtonFormField<String>(
                   value: _carType,
                   items: _carTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                   onChanged: (v) => setState(() => _carType = v),
                   decoration: const InputDecoration(labelText: "Car Class", border: OutlineInputBorder()),
                 ),
                 const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: "Vehicle Model (e.g. Honda City)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(labelText: "Plate Number (e.g. CG 05 XX 0000)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fuelController,
                decoration: const InputDecoration(labelText: "Fuel Type (Petrol/Electric)", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 40),
               SizedBox(
               width: double.infinity,
               height: 50,
               child: ElevatedButton(
                 onPressed: _isLoading ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.black,
                   foregroundColor: Colors.white,
                 ),
                 child: _isLoading ? const CircularProgressIndicator() : const Text("Submit for Verification"),
               ),
             )
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Auto': return Icons.local_taxi; // Closest
      case 'Bike': return Icons.two_wheeler;
      case 'Scooter': return Icons.electric_scooter;
      case 'Car': return Icons.directions_car;
      default: return Icons.help;
    }
  }
}
