# ==============================================================================
# Script Menjalankan Flutter Sign2Speech dengan Environment Supabase (.env)
# ==============================================================================

if (-Not (Test-Path ".env")) {
    Write-Host "File .env tidak ditemukan! Membuat dari .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
}

Write-Host "Menjalankan Flutter dengan konfigurasi Supabase dari .env..." -ForegroundColor Green
flutter run --dart-define-from-file=.env $args
