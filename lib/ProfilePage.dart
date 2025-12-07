import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Intentamos cargar los datos al abrir la pantalla por si acaso no están
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderState>().loadUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderState>();
    final profile = provider.userProfile;

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
                  // Avatar grande
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      profile['fullName'] != null &&
                              profile['fullName'].isNotEmpty
                          ? profile['fullName'][0].toUpperCase()
                          : "U",
                      style:
                          TextStyle(fontSize: 40, color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre y Usuario
                  Text(
                    profile['fullName'] ?? "Usuario",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "@${profile['username']}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tarjeta de estadísticas (Rating y Viajes)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
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
                          "${profile['rating']}",
                          "Calificación",
                          Colors.amber,
                        ),
                        Container(
                            width: 1, height: 40, color: Colors.grey.shade300),
                        _buildStatColumn(
                          Icons.directions_car,
                          "${profile['completedTrips']}",
                          "Viajes",
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Información detallada
                  _buildInfoTile("Universidad",
                      profile['university'] ?? "No registrada", Icons.school),
                  _buildInfoTile("Correo", profile['email'] ?? "", Icons.email),
                  _buildInfoTile(
                      "Celular", profile['phone'] ?? "", Icons.phone),

                  const SizedBox(height: 40),

                  // Botón Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await provider.logout();
                        if (context.mounted) {
                          // Regresar a la selección de universidad y borrar historial
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              '/SELECT_UNI', (route) => false);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "Cerrar Sesión",
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
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
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade800, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          )
        ],
      ),
    );
  }
}
