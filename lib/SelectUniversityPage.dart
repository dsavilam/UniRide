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
                child: ListView(
                  children: [
                    _UniversityCard(
                      name: 'Universidad de los Andes',
                      assetPath: 'assets/logos/Andes.png',
                      // Nota: Ya no usamos el color para teñir la imagen,
                      // pero lo dejo por si quieres usarlo luego para bordes o textos.
                      color: Colors.yellow.shade700,
                      onTap: () => provider.selectUniversity('Andes'),
                    ),
                    const SizedBox(height: 30), // Aumenté un poco el espacio entre items

                    _UniversityCard(
                      name: 'Pontificia Universidad Javeriana',
                      assetPath: 'assets/logos/Javeriana.png',
                      color: Colors.blue.shade800,
                      onTap: () => provider.selectUniversity('Javeriana'),
                    ),
                    const SizedBox(height: 30),

                    _UniversityCard(
                      name: 'Universidad del Rosario',
                      assetPath: 'assets/logos/Rosario.png',
                      color: Colors.red.shade900,
                      onTap: () => provider.selectUniversity('Rosario'),
                    ),
                    const SizedBox(height: 30),

                    _UniversityCard(
                      name: 'Universidad Externado',
                      assetPath: 'assets/logos/Externado.png',
                      color: Colors.green.shade800,
                      onTap: () => provider.selectUniversity('Externado'),
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
              height: 120, // Aumentado para que se vean más grandes
              width: 120,  // Definimos ancho fijo para uniformidad
              decoration: const BoxDecoration(
                // Si quisieras un borde sutil podrías descomentar esto:
                // shape: BoxShape.circle,
                // color: Colors.grey.shade50,
              ),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain, // Esto hace que todos se vean del mismo tamaño visual sin cortarse
              ),
            ),
            const SizedBox(height: 12),
            // Nombre de la Universidad
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20, // Aumentado un poquito el tamaño de letra
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