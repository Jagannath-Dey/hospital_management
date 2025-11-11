import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hospital_management_app/widgets/backgrounds/hospital_background.dart';

import '../../utils/constants.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HospitalBackground(
        style: BackgroundStyle.simple,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade500],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Emergency Services',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'In case of emergency, call immediately',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emergency Call Button
                      _buildEmergencyCallButton(context),

                      const SizedBox(height: 24),

                      // Quick Contacts
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEmergencyContact(
                        'Ambulance',
                        '911',
                        Icons.local_hospital,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildEmergencyContact(
                        'Fire Department',
                        '911',
                        Icons.fire_truck,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildEmergencyContact(
                        'Police',
                        '911',
                        Icons.local_police,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildEmergencyContact(
                        'Poison Control',
                        '1-800-222-1222',
                        Icons.medical_services,
                        Colors.purple,
                      ),

                      const SizedBox(height: 24),

                      // Hospital Hotline
                      const Text(
                        'Hospital Hotline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHospitalContact(
                        'Main Hospital',
                        '+1 (555) 123-4567',
                        '24/7 Emergency Care',
                      ),

                      const SizedBox(height: 24),

                      // Emergency Tips
                      const Text(
                        'Emergency Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTipCard(
                        'Heart Attack',
                        'Call 911 immediately. Keep the person calm and seated. Give aspirin if available and not allergic.',
                        Icons.favorite,
                        Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildTipCard(
                        'Stroke',
                        'Call 911. Remember FAST: Face drooping, Arm weakness, Speech difficulty, Time to call.',
                        Icons.psychology,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildTipCard(
                        'Severe Bleeding',
                        'Apply direct pressure to the wound. Elevate the injured area. Call 911 if bleeding doesn\'t stop.',
                        Icons.healing,
                        Colors.pink,
                      ),
                      const SizedBox(height: 12),
                      _buildTipCard(
                        'Choking',
                        'Encourage coughing. If unable to breathe, perform Heimlich maneuver. Call 911 if object doesn\'t dislodge.',
                        Icons.person,
                        Colors.blue,
                      ),

                      const SizedBox(height: 24),

                      // Nearby Hospitals Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _findNearbyHospitals(context);
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('Find Nearby Hospitals'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: AppColors.primaryBlue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCallButton(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.red.shade600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _makeEmergencyCall('911'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'CALL EMERGENCY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '911',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to call immediately',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(
      String name,
      String number,
      IconData icon,
      Color color,
      ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(number),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
          onPressed: () => _makeEmergencyCall(number),
        ),
      ),
    );
  }

  Widget _buildHospitalContact(String name, String number, String availability) {
    return Card(
      color: AppColors.primaryBlue.withOpacity(0.05),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.local_hospital, color: AppColors.primaryBlue),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number),
            Text(
              availability,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: AppColors.primaryBlue),
          onPressed: () => _makeEmergencyCall(number),
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String description, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeEmergencyCall(String number) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _findNearbyHospitals(BuildContext context) {
    // Open maps to show nearby hospitals
    final Uri mapsUri = Uri.parse('https://www.google.com/maps/search/hospitals+near+me');
    launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }
}