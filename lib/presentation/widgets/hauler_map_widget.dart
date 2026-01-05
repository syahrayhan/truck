import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants.dart';
import '../bloc/bloc.dart';

/// Interactive map widget showing hauler, loader, and dump point
class HaulerMapWidget extends StatefulWidget {
  const HaulerMapWidget({super.key});

  @override
  State<HaulerMapWidget> createState() => _HaulerMapWidgetState();
}

class _HaulerMapWidgetState extends State<HaulerMapWidget> {
  final MapController _mapController = MapController();
  bool _followHauler = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HaulerBloc, HaulerState>(
      builder: (context, state) {
        final haulerLocation = state.currentLocation;
        final loader = state.selectedLoader;
        final dumpPoint = state.dumpPoint;
        
        // Default center (Jakarta)
        LatLng center = const LatLng(-6.2088, 106.8456);
        
        if (haulerLocation != null) {
          center = LatLng(haulerLocation.lat, haulerLocation.lng);
        } else if (loader != null) {
          center = LatLng(loader.location.lat, loader.location.lng);
        }

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.0,
                minZoom: 10,
                maxZoom: 19,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() => _followHauler = false);
                  }
                },
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hauler.truck',
                  maxZoom: 19,
                ),
                
                // Radius circles
                CircleLayer(
                  circles: [
                    // Loader radius
                    if (loader != null)
                      CircleMarker(
                        point: LatLng(loader.location.lat, loader.location.lng),
                        radius: loader.radius,
                        useRadiusInMeter: true,
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        borderColor: const Color(0xFF4CAF50),
                        borderStrokeWidth: 2,
                      ),
                    
                    // Dump point radius
                    if (dumpPoint != null)
                      CircleMarker(
                        point: LatLng(dumpPoint.location.lat, dumpPoint.location.lng),
                        radius: dumpPoint.radius,
                        useRadiusInMeter: true,
                        color: const Color(0xFFFF9800).withOpacity(0.2),
                        borderColor: const Color(0xFFFF9800),
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
                
                // Markers
                MarkerLayer(
                  markers: [
                    // Loader marker
                    if (loader != null)
                      Marker(
                        point: LatLng(loader.location.lat, loader.location.lng),
                        width: 50,
                        height: 50,
                        child: _LoaderMarker(
                          name: loader.name,
                          isWaiting: loader.waitingTruck,
                        ),
                      ),
                    
                    // Dump point marker
                    if (dumpPoint != null)
                      Marker(
                        point: LatLng(dumpPoint.location.lat, dumpPoint.location.lng),
                        width: 50,
                        height: 50,
                        child: _DumpPointMarker(name: dumpPoint.name),
                      ),
                    
                    // Hauler marker
                    if (haulerLocation != null)
                      Marker(
                        point: LatLng(haulerLocation.lat, haulerLocation.lng),
                        width: 60,
                        height: 60,
                        child: _HaulerMarker(
                          status: state.currentStatus,
                          bodyUp: state.bodyUp,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            
            // Map controls
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: [
                  // Follow hauler toggle
                  FloatingActionButton.small(
                    heroTag: 'follow',
                    onPressed: () {
                      setState(() => _followHauler = !_followHauler);
                      if (_followHauler && haulerLocation != null) {
                        _mapController.move(
                          LatLng(haulerLocation.lat, haulerLocation.lng),
                          _mapController.camera.zoom,
                        );
                      }
                    },
                    backgroundColor: _followHauler 
                        ? const Color(0xFF1E88E5)
                        : Colors.white,
                    child: Icon(
                      _followHauler ? Icons.gps_fixed : Icons.gps_not_fixed,
                      color: _followHauler ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Zoom in
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  
                  // Zoom out
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            // Legend
            Positioned(
              left: 16,
              bottom: 16,
              child: _MapLegend(),
            ),
          ],
        );
      },
    );
  }
}

/// Hauler truck marker
class _HaulerMarker extends StatelessWidget {
  final HaulerStatus status;
  final bool bodyUp;

  const _HaulerMarker({
    required this.status,
    required this.bodyUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getShortStatus(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 40,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD54F),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getStatusColor(),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Truck body
              const Center(
                child: Icon(
                  Icons.local_shipping,
                  color: Color(0xFF5D4037),
                  size: 20,
                ),
              ),
              // Body up indicator
              if (bodyUp)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case HaulerStatus.standby:
        return Colors.grey;
      case HaulerStatus.queuing:
        return const Color(0xFF2196F3);
      case HaulerStatus.spotting:
        return const Color(0xFF9C27B0);
      case HaulerStatus.loading:
        return const Color(0xFF4CAF50);
      case HaulerStatus.haulingLoad:
        return const Color(0xFFFF9800);
      case HaulerStatus.dumping:
        return const Color(0xFFF44336);
      case HaulerStatus.haulingEmpty:
        return const Color(0xFF00BCD4);
    }
  }

  String _getShortStatus() {
    switch (status) {
      case HaulerStatus.standby:
        return 'IDLE';
      case HaulerStatus.queuing:
        return 'QUEUE';
      case HaulerStatus.spotting:
        return 'SPOT';
      case HaulerStatus.loading:
        return 'LOAD';
      case HaulerStatus.haulingLoad:
        return 'HAUL';
      case HaulerStatus.dumping:
        return 'DUMP';
      case HaulerStatus.haulingEmpty:
        return 'RETURN';
    }
  }
}

/// Loader marker
class _LoaderMarker extends StatelessWidget {
  final String name;
  final bool isWaiting;

  const _LoaderMarker({
    required this.name,
    required this.isWaiting,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isWaiting 
                ? const Color(0xFF4CAF50) 
                : const Color(0xFF757575),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.construction,
            color: Colors.white,
            size: 20,
          ),
        ),
        if (isWaiting)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'READY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

/// Dump point marker
class _DumpPointMarker extends StatelessWidget {
  final String name;

  const _DumpPointMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.downloading,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Map legend
class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendItem(const Color(0xFF4CAF50), 'Loader Zone'),
          const SizedBox(height: 4),
          _legendItem(const Color(0xFFFF9800), 'Dump Zone'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


