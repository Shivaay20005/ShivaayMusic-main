import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/utils/helper.dart';

class MaintenanceOverlay extends StatefulWidget {
  final Map<String, dynamic> config;

  const MaintenanceOverlay({super.key, required this.config});

  @override
  State<MaintenanceOverlay> createState() => _MaintenanceOverlayState();
}

class _MaintenanceOverlayState extends State<MaintenanceOverlay> {
  
  @override
  void initState() {
    super.initState();
    // STOP AUDIO when Maintenance/Blocked screen appears
    if (Get.isRegistered<AudioHandler>()) {
      Get.find<AudioHandler>().stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    
    // Determine if this is a Force Update or Maintenance
    bool isUpdate = widget.config['updateUrl'] != null && widget.config['updateUrl'].toString().isNotEmpty;
    
    return Material(
      color: Colors.black.withValues(alpha: 0.98),
      child: PopScope(
        canPop: false, // Block BACK button
        onPopInvokedWithResult: (didPop, result) {
           // Logic if we wanted to handle the attempt (e.g. show toast)
           // Currently just blocking silently.
           return;
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpdate ? Icons.system_update : Icons.warning_amber_rounded,
                color: isUpdate ? Colors.blueAccent : Colors.redAccent,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                widget.config['title'] ?? (isUpdate ? "Update Required" : "System Under Maintenance"),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                widget.config['message'] ??
                    (isUpdate 
                        ? "A new version of ShivaayMusic is available. Please update to continue." 
                        : "We are currently performing scheduled maintenance. Please check back later."),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // UPDATE BUTTON
              if (isUpdate)
                ElevatedButton.icon(
                  onPressed: () => _launchUrl(widget.config['updateUrl']),
                  icon: const Icon(Icons.download),
                  label: const Text("UPDATE NOW"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),

              if (!isUpdate && widget.config['estimatedTime'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      "Estimated Return: ${widget.config['estimatedTime']}",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
              const SizedBox(height: 24),
              // Status Link (Secondary)
              if (widget.config['statusUrl'] != null)
                TextButton.icon(
                    onPressed: () => _launchUrl(widget.config['statusUrl']),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Check Status Page"),
                    style: TextButton.styleFrom(foregroundColor: Colors.white60)
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    await launchUrlSafe(url);
  }
}
