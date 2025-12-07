# UniRide 🚗🎓

**UniRide** es una aplicación móvil de carpooling diseñada exclusivamente para comunidades universitarias. Conecta a estudiantes que tienen vehículo (conductores) con aquellos que necesitan transporte (pasajeros), facilitando viajes seguros, económicos y eficientes hacia y desde la universidad.

## 📋 Tabla de Contenidos

1.  [Características Principales](#-características-principales)
2.  [Arquitectura y Tecnologías](#-arquitectura-y-tecnologías)
3.  [Estructura del Proyecto](#-estructura-del-proyecto)
4.  [Instalación y Configuración](#-instalación-y-configuración)
5.  [Flujos de Usuario](#-flujos-de-usuario)
6.  [Modelo de Datos (Firebase)](#-modelo-de-datos-firebase)

---

## 🌟 Características Principales

### 🔐 Autenticación y Seguridad
*   **Registro Restringido:** Solo permite el registro con correos institucionales verificados (ej. `@javeriana.edu.co`, `@uniandes.edu.co`).
*   **Verificación de Correo:** Flujo de verificación de email antes de permitir el acceso completo.

### 🚘 Modo Conductor
*   **Gestión de Vehículos:** Registro de múltiples vehículos con detalles (Placa, Modelo, Color).
*   **Publicación de Viajes:** Interfaz intuitiva para programar viajes seleccionando origen, destino y puntos intermedios (waypoints) en el mapa.
*   **Rutas Inteligentes:** Visualización de la ruta sugerida utilizando OpenStreetMap y OSRM.
*   **Gestión de Pasajeros:** Aceptación automática de reservas y visualización de lista de pasajeros en tiempo real.
*   **Control de Viaje:** Estados de viaje (Activo, En Progreso, Finalizado) para mantener a los pasajeros informados.

### 🙋‍♂️ Modo Pasajero
*   **Búsqueda Avanzada:** Algoritmo de búsqueda geoespacial que encuentra viajes que coinciden con el origen y destino del pasajero, o que pasan cerca de ellos (waypoints).
*   **Reservas:** Sistema de reserva de cupos en tiempo real.
*   **Detalle de Viaje:** Visualización completa de la ruta, información del conductor y vehículo asignado.
*   **Calificación:** Sistema de reseñas y calificación para conductores.

### 👤 Perfil y Estadísticas
*   **Sistema de Reputación:** Calificación promedio (estrellas) basada en reseñas reales.
*   **Foto de Perfil:** Carga y gestión de fotos de perfil almacenadas en la nube.

---

## 🛠 Arquitectura y Tecnologías

El proyecto está construido utilizando **Flutter** para el desarrollo multiplataforma (iOS y Android) y **Firebase** como Backend-as-a-Service (BaaS).

### Dependencias Clave (`pubspec.yaml`)
*   **Gestión de Estado:** `provider` (^6.1.2) - Arquitectura MVVM simplificada.
*   **Backend:**
    *   `firebase_auth`: Autenticación de usuarios.
    *   `firebase_database`: Base de datos en tiempo real (NoSQL).
    *   `firebase_storage`: Almacenamiento de archivos multimedia.
*   **Mapas y Geolocalización:**
    *   `flutter_map`: Renderizado de mapas (OpenStreetMap).
    *   `latlong2`: Manejo de coordenadas.
    *   `geolocator`: Obtención de ubicación GPS del dispositivo.
    *   `http`: Peticiones a la API de rutas (OSRM).

---

## 📂 Estructura del Proyecto

El código fuente se encuentra en el directorio `lib/` y sigue una estructura modular:

```text
lib/
├── main.dart             # Punto de entrada. Inicialización de Firebase y Rutas.
├── ProviderState.dart    # Lógica de Negocio (State Management). Interactúa con Firebase.
├── home_page.dart        # Pantalla Principal. Maneja la navegación entre pestañas (Pasajero/Conductor).
├── SignUpPage.dart       # Pantalla de Registro y Login.
├── ProfilePage.dart      # Pantalla de Perfil de Usuario.
├── ScheduleTripPage.dart # Formulario y Mapa para crear nuevos viajes.
├── DriverTripPage.dart   # Vista del Conductor para un viaje activo (Mapa + Pasajeros).
├── TripDetailsPage.dart  # Vista del Pasajero para un viaje reservado.
└── ...
```

---

## 🚀 Instalación y Configuración

### Prerrequisitos
*   Flutter SDK (>=3.2.0)
*   Cuenta de Firebase configurada.

### Pasos
1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/tu-usuario/uniride.git
    cd uniride
    ```
2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Configuración de Firebase:**
    *   Asegúrate de tener los archivos `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) en sus respectivas carpetas.
4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```

---

## 🔄 Flujos de Usuario

### 1. Publicar un Viaje (Conductor)
1.  En la pestaña "Soy Conductor", selecciona "Programar Viaje".
2.  Elige un vehículo registrado.
3.  En el mapa, selecciona el punto de partida (o usa tu ubicación actual).
4.  Selecciona el destino y, opcionalmente, un punto intermedio (waypoint).
5.  Define fecha, hora, precio y cupos disponibles.
6.  Confirma la publicación. El viaje aparecerá en "Mis Viajes Publicados".

### 2. Reservar un Viaje (Pasajero)
1.  En la pestaña "Soy Pasajero", ingresa tu origen y destino deseado.
2.  El sistema buscará coincidencias directas o rutas que pasen cerca (radio de 2km).
3.  Selecciona un viaje de la lista de resultados.
4.  Revisa los detalles y pulsa "Reservar Cupo".
5.  El viaje aparecerá en "Mis Reservas Activas".

### 3. Finalizar Viaje y Calificar
1.  El conductor inicia el viaje y, al llegar, pulsa "Finalizar Viaje".
2.  Automáticamente se incrementa el contador de viajes para todos los participantes.
3.  Se abre un diálogo para calificar a los pasajeros/conductor.
4.  Las calificaciones actualizan el promedio en el perfil del usuario en tiempo real.

---

## 💾 Modelo de Datos (Firebase)

La base de datos Realtime Database tiene dos nodos principales:

### `users`
Almacena la información de perfil y vehículos de cada usuario.
```json
{
  "uid_usuario": {
    "profile": {
      "fullName": "Nombre",
      "email": "correo@uni.edu.co",
      "rating": 4.8,
      "completedTrips": 12,
      "ratingCount": 5
    },
    "vehicles": { ... }
  }
}
```

### `trips`
Almacena todos los viajes publicados.
```json
{
  "trip_id": {
    "driverId": "uid_conductor",
    "status": "active", // active, in_progress, finished
    "origin": { "lat": ..., "lng": ... },
    "destination": { "lat": ..., "lng": ... },
    "seats": {
      "available": 3,
      "passengers": {
        "uid_pasajero": true
      }
    }
  }
}
```

---
**Desarrollado para el Hackathon 24h Colombia de Young AI Leaders 2025** 
