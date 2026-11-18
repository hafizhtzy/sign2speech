# ==============================================================================
# Script Build Flutter Web dengan WebAssembly (Wasm) & Content Hashing
# Sesuai Standar AGENTS.md & GEMINI.md (Aturan 1.B: Kompatibilitas Wasm)
# ==============================================================================

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Flutter Web Wasm Production Build: Sign2Speech          " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Pastikan Web support aktif
Write-Host "`n[1/3] Memeriksa environment Flutter Web..." -ForegroundColor Yellow
flutter config --enable-web

# 2. Build Web dengan flag --wasm dan --web-content-hash
Write-Host "`n[2/3] Mengompilasi WebAssembly (Wasm) dengan cache-busting content hash..." -ForegroundColor Yellow
flutter build web --wasm --web-content-hash $args

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[3/3] Build Wasm Berhasil! Output tersedia di folder build/web/" -ForegroundColor Green
    Write-Host "Siap di-deploy ke Supabase Storage, Firebase Hosting, atau Cloudflare Pages." -ForegroundColor Green
} else {
    Write-Host "`nBuild Wasm gagal dengan exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
