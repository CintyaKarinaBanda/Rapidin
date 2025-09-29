<<<<<<< HEAD
<<<<<<< HEAD
# Rapidin - Gestión de Pedidos para Restaurantes

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)
![Clean Architecture](https://img.shields.io/badge/Architecture-Clean-blue)

## Descripción

Aplicación móvil para la gestión de pedidos en restaurantes, diseñada para operar con capacidad de escalabilidad. Incluye soporte offline robusto para garantizar operación continua sin conectividad.

### Características principales
- **Sincronización offline/online** automática
- **Clean Architecture** con separación clara de responsabilidades
- **Firebase** para autenticación y notificaciones push
- **Estado reactivo** con Riverpod
- **Escalable** hacia microservicios

## Arquitectura

```
lib/
├── core/          # Utilidades, errores, constantes
├── domain/        # Entidades y casos de uso
├── data/          # Repositorios y fuentes de datos
└── presentation/  # UI, pantallas y ViewModels
```

## Stack Tecnológico

| Tecnología | Propósito |
|------------|----------|
| **Flutter** | Framework multiplataforma |
| **Riverpod** | Gestión de estado e inyección de dependencias |
| **Drift/Hive** | Persistencia local offline |
| **Firebase Auth** | Autenticación y control de acceso |
| **FCM** | Notificaciones push |
| **Dio** | Cliente HTTP para APIs REST |
| **Firestore** | Base de datos en tiempo real |

## Instalación

### Prerrequisitos
- Flutter SDK ≥ 3.0
- Dart SDK ≥ 3.0
- Android Studio / VS Code
- Firebase CLI (opcional)

### Pasos

1. **Clonar repositorio**
   ```bash
   git clone https://github.com/CintyaKarinaBanda/Rapidin
   cd rapidin
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Agregar `google-services.json` (Android)
   - Agregar `GoogleService-Info.plist` (iOS)

4. **Ejecutar aplicación**
   ```bash
   flutter run
   ```

### Builds de producción

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Consideraciones Técnicas

### Gestión de riesgos

| Riesgo | Mitigación |
|--------|------------|
| **Over-engineering** | Plantillas mínimas y generadores de código |
| **Conflictos de sincronización** | Colas locales con política "server wins" |
| **Acoplamiento en ViewModels** | Lógica de negocio exclusiva en use cases |

### Supuestos de diseño

- Escalabilidad hacia arquitectura de microservicios
- Notificaciones funcionales en segundo plano
- Dominio independiente de cambios en UI/datos
- Conectividad intermitente como escenario normal

## Roadmap

- [ ] Implementación de métricas y analytics
- [ ] Soporte para múltiples idiomas
- [ ] Integración con sistemas POS
- [ ] Dashboard web para administradores
=======
=======
>>>>>>> ea40f5b5502b3afac10d1297465db0e4c0edbe87
# rapidin

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
<<<<<<< HEAD
>>>>>>> ea40f5b (davai)
=======
>>>>>>> ea40f5b5502b3afac10d1297465db0e4c0edbe87
