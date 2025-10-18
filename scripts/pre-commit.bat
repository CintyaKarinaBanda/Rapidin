@echo off
echo 🔍 Running pre-commit checks...

echo 📝 Formatting code...
dart format . --set-exit-if-changed
if %errorlevel% neq 0 (
    echo ❌ Code formatting failed. Please run 'dart format .' and try again.
    exit /b 1
)

echo 🔍 Analyzing code...
flutter analyze --fatal-infos
if %errorlevel% neq 0 (
    echo ❌ Code analysis failed. Please fix the issues and try again.
    exit /b 1
)

echo 🧪 Running tests...
flutter test
if %errorlevel% neq 0 (
    echo ❌ Tests failed. Please fix the failing tests and try again.
    exit /b 1
)

echo ✅ All pre-commit checks passed!
exit /b 0