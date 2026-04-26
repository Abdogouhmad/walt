# Set the shell to bash for better compatibility
set shell := ["bash", "-c"]

# --- Project Initialization ---

# Install dependencies
install:
    flutter pub get

# Clean the project and reinstall dependencies
reset:
    flutter clean
    flutter pub get

# --- Code Generation ---

# Run build_runner once
build: clean
    flutter pub run build_runner build --delete-conflicting-outputs

# Watch for file changes and run build_runner
watch:
    flutter pub run build_runner watch --delete-conflicting-outputs

# --- Quality Control ---

# Run linter and static analysis
lint:
    flutter analyze
# Format all files
format:
    dart format .
# --- Execution ---

# Run the app in debug mode
run:
    flutter run

# Run the app in release mode
run-release:
    flutter run --release

# --- Build & Deployment ---

# Build Android APK (Release)
build-apk: clean
    flutter build apk --release --split-per-abi

# Build Android App Bundle (for Play Store)
build-bundle:
    flutter build appbundle --release

# clean project
clean:
  flutter clean
  flutter pub get

# generate image
img: clean
  dart run flutter_launcher_icons

#generate freezed files
model:
  dart run build_runner build --delete-conflicting-outputs
