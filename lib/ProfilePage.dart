import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forzamos la carga al entrar
      print("DEBUG: Solicitando carga de perfil...");
      context.read<ProviderState>().loadUserProfile();
    });
  }

  // --- MÉTODOS DE IMAGEN (Igual que antes) ---
  Future<void> _showImageSourceDialog() async {
    final provider = context.read<ProviderState>();
    final profile = provider.userProfile;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de la galería'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
              ),
              if (profile?['photoUrl'] != null || _profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                  onTap: () { Navigator.pop(context); _deletePhoto(); },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) {
        setState(() { _profileImage = File(image.path); _isUploading = true; });
        final provider = context.read<ProviderState>();
        final url = await provider.uploadProfilePhoto(_profileImage!);
        if (mounted) {
          setState(() => _isUploading = false);
          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al subir')));
            setState(() => _profileImage = null);
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isUploading = false; _profileImage = null; });
    }
  }

  ImageProvider? _getProfileImage(Map<String, dynamic> profile) {
    if (_profileImage != null) return FileImage(_profileImage!);
    if (profile['photoUrl'] != null && profile['photoUrl'].toString().isNotEmpty) return NetworkImage(profile['photoUrl']);
    return null;
  }

  Future<void> _deletePhoto() async {
    final provider = context.read<ProviderState>();
    final success = await provider.deleteProfilePhoto();
    if (mounted && success) {
      setState(() => _profileImage = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto eliminada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderState>();
    final profile = provider.userProfile;

    // --- LÓGICA DE DATOS BLINDADA ---
    // Usamos "--" por defecto para saber si cargó o no
    String ratingStr = "--";
    String tripsStr = "--";

    if (profile != null) {
      // DEBUG: Imprimimos en consola qué llega exactamente
      // print("DEBUG DATOS CRUDOS: $profile");

      // 1. EXTRAER RATING (A prueba de fallos)
      try {
        if (profile['rating'] != null) {
          // Convertimos cualquier cosa (int, double, string) a String primero
          final raw = profile['rating'].toString();
          // Parseamos a double
          final val = double.tryParse(raw);
          if (val != null) {
            ratingStr = val.toStringAsFixed(1);
          }
        } else {
          // Si es nulo en BD, asumimos 5.0
          ratingStr = "5.0";
        }
      } catch (e) {
        print("Error parseando rating: $e");
        ratingStr = "Err";
      }

      // 2. EXTRAER VIAJES
      try {
        if (profile['completedTrips'] != null) {
          tripsStr = profile['completedTrips'].toString();
        } else {
          tripsStr = "0";
        }
      } catch (e) {
        tripsStr = "0";
      }
    }
    // ----------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- AVATAR ---
            GestureDetector(
              onTap: _isUploading ? null : _showImageSourceDialog,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _isUploading ? null : _getProfileImage(profile),
                    child: _isUploading
                        ? const CircularProgressIndicator()
                        : (_profileImage == null && profile['photoUrl'] == null)
                        ? Text(
                      profile['fullName'] != null && profile['fullName'].isNotEmpty
                          ? profile['fullName'][0].toUpperCase()
                          : "U",
                      style: TextStyle(fontSize: 40, color: Colors.blue.shade800),
                    )
                        : null,
                  ),
                  if (!_isUploading)
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showImageSourceDialog,
              child: const Text('Cambiar foto de perfil', style: TextStyle(fontSize: 14)),
            ),

            const SizedBox(height: 8),
            Text(
              profile['fullName'] ?? "Usuario",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "@${profile['username']}",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),

            const SizedBox(height: 30),

            // --- TARJETA DE ESTADÍSTICAS (AQUÍ ESTÁ LA MAGIA) ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    Icons.star_rounded,
                    ratingStr, // Variable calculada
                    "Calificación",
                    Colors.amber,
                  ),
                  Container(width: 1, height: 40, color: Colors.grey.shade300),
                  _buildStatColumn(
                    Icons.directions_car,
                    tripsStr, // Variable calculada
                    "Viajes",
                    Colors.blue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- INFO DETALLADA ---
            _buildInfoTile("Universidad", profile['university'] ?? "No registrada", Icons.school),
            _buildInfoTile("Correo", profile['email'] ?? "", Icons.email),
            _buildInfoTile("Celular", profile['phone'] ?? "", Icons.phone),

            const SizedBox(height: 40),

            // --- BOTÓN SALIR ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await provider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/SELECT_UNI', (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Cerrar Sesión", style: TextStyle(color: Colors.red.shade700, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blue.shade800, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }
}