# 🚀 CI/CD Pipeline - Rapidin

## Workflows Configurados

### 1. **CI/CD Principal** (`ci-cd.yml`)
- **Trigger**: Push a `main` y `develop`, PRs a `main`
- **Jobs**: analyze, build-android, build-ios

### 2. **PR Quality Check** (`pr-check.yml`)
- **Trigger**: PRs
- **Funciones**: Validación + comentarios automáticos

### 3. **Release** (`release.yml`)
- **Trigger**: Tags `v*`
- **Genera**: APK + AAB + GitHub Release

## Proceso de Desarrollo

```bash
# Feature branch
git checkout -b feature/nueva-funcionalidad
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/nueva-funcionalidad

# Release
git tag v1.0.0
git push origin v1.0.0
```

## Setup Local

```bash
flutter pub get
flutter test
flutter analyze
scripts\pre-commit.bat
```