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
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8, // Adjust ratio to fit image and text
                  children: [
                    _UniversityCard(
                      name: 'Universidad de los Andes',
                      assetPath: 'assets/logos/Andes.png',
                      color: Colors.yellow.shade700,
                      onTap: () {
                        provider.selectUniversity('Andes');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),
                    _UniversityCard(
                      name: 'Pontificia Universidad Javeriana',
                      assetPath: 'assets/logos/Javeriana.png',
                      color: Colors.blue.shade800,
                      onTap: () {
                        provider.selectUniversity('Javeriana');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),
                    _UniversityCard(
                      name: 'Universidad del Rosario',
                      assetPath: 'assets/logos/Rosario.png',
                      color: Colors.red.shade900,
                      onTap: () {
                        provider.selectUniversity('Rosario');
                        Navigator.pushNamed(context, '/SIGNUP');
                      },
                    ),
                    _UniversityCard(
                      name: 'Universidad Externado',
                      assetPath: 'assets/logos/Externado.png',
                      color: Colors.green.shade800,
                      onTap: () {
                        provider.selectUniversity('Externado');
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
      // Usamos Container con fondo transparente para mejorar la zona táctil
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            // Contenedor del Logo
            Container(
              height: 100, // Reduced size for grid
              width: 100,
              decoration: const BoxDecoration(
                  // Si quisieras un borde sutil podrías descomentar esto:
                  // shape: BoxShape.circle,
                  // color: Colors.grey.shade50,
                  ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            // Nombre de la Universidad
            Expanded(
              // Use Expanded to prevent overflow
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16, // Reduced font size
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
