import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './ProviderState.dart';

class SelectUniversityPage extends StatelessWidget {
  const SelectUniversityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ProviderState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Text(
                'Selecciona\ntu universidad',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 40),

              Expanded(
                // CAMBIO: Usamos GridView.count en lugar de ListView
                child: GridView.count(
                  crossAxisCount: 2, // 2 Columnas
                  crossAxisSpacing: 20, // Espacio horizontal entre tarjetas
                  mainAxisSpacing: 20, // Espacio vertical entre tarjetas
                  childAspectRatio: 0.75, // Relación de aspecto (Ancho / Alto) para que quepa la imagen y el texto
                  children: [
                    // --- ANDES ---
                    _UniversityCard(
                      name: 'Universidad de los Andes',
                      assetPath: 'assets/logos/Andes.png',
                      color: Colors.yellow.shade700,
                      onTap: () {
                        provider.selectUniversity('Universidad de los Andes');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),

                    // --- JAVERIANA ---
                    _UniversityCard(
                      name: 'Pontificia Universidad Javeriana',
                      assetPath: 'assets/logos/Javeriana.png',
                      color: Colors.blue.shade800,
                      onTap: () {
                        provider.selectUniversity('Pontificia Universidad Javeriana');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),

                    // --- ROSARIO ---
                    _UniversityCard(
                      name: 'Universidad del Rosario',
                      assetPath: 'assets/logos/Rosario.png',
                      color: Colors.red.shade900,
                      onTap: () {
                        provider.selectUniversity('Universidad del Rosario');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),

                    // --- EXTERNADO ---
                    _UniversityCard(
                      name: 'Universidad Externado',
                      assetPath: 'assets/logos/Externado.png',
                      color: Colors.green.shade800,
                      onTap: () {
                        provider.selectUniversity('Universidad Externado');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final String name;
  final String assetPath;
  final Color color;
  final VoidCallback onTap;

  const _UniversityCard({
    required this.name,
    required this.assetPath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Necesario para detectar taps en espacios vacíos
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
          children: [
            Container(
              height: 100, // Reduje un poco la imagen para el grid
              width: 100,
              decoration: const BoxDecoration(
                // shape: BoxShape.circle,
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 3, // Permitir hasta 3 líneas de texto
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16, // Reduje un poco la letra para que quepa mejor en 2 columnas
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}