#!/bin/bash
# Script per installare Flutter e compilare il progetto su Vercel

echo "Creazione del file .env dalle variabili di ambiente di Vercel..."
echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env

echo "Scaricando Flutter..."
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

echo "Versione di Flutter:"
flutter --version

echo "Scaricando le dipendenze..."
flutter pub get

echo "Compilando per il Web..."
flutter build web --release
