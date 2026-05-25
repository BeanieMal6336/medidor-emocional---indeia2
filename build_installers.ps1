# Script de Compilação para Instaladores do MindFlow (Windows & Android)
# Este script verifica as dependências locais e compila o aplicativo.

$flutterCmd = ".\flutter\bin\flutter.bat"
if (-not (Test-Path $flutterCmd)) {
    $flutterCmd = "flutter"
}

Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      ASSISTENTE DE COMPILAÇÃO - MINDFLOW         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verifica se o SDK do Flutter está acessível
Write-Host "[*] Verificando o SDK do Flutter..." -ForegroundColor Yellow
$flutterVersion = & $flutterCmd --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "[x] Erro: O SDK do Flutter não pôde ser encontrado!" -ForegroundColor Red
    Write-Host "[i] Certifique-se de que a pasta 'flutter' local está presente." -ForegroundColor Red
    Exit 1
}

# 2. Menu Interativo
Write-Host ""
Write-Host "Selecione uma opção de compilação:" -ForegroundColor Green
Write-Host "1) Compilar APK para Android (.apk)"
Write-Host "2) Compilar Executável para Windows PC (.zip)"
Write-Host "3) Compilar Ambos (Android & Windows)"
Write-Host "4) Sair"
$choice = Read-Host "Digite o número da opção (1-4)"

if ($choice -eq "1" -or $choice -eq "3") {
    Write-Host ""
    Write-Host "=== COMPIlANDO PARA ANDROID ===" -ForegroundColor Cyan
    Write-Host "[*] Iniciando compilação do APK de Release..." -ForegroundColor Yellow
    & $flutterCmd build apk --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "[√] APK compilado com sucesso!" -ForegroundColor Green
        Write-Host "[i] Arquivo disponível em: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    } else {
        Write-Host "[x] Falha na compilação do Android. Certifique-se de ter instalado o Android SDK (Android Studio)." -ForegroundColor Red
    }
}

if ($choice -eq "2" -or $choice -eq "3") {
    Write-Host ""
    Write-Host "=== COMPIlANDO PARA WINDOWS PC ===" -ForegroundColor Cyan
    Write-Host "[*] Iniciando compilação do executável Windows..." -ForegroundColor Yellow
    & $flutterCmd build windows --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[*] Compactando arquivos gerados..." -ForegroundColor Yellow
        $outputPath = "build\mindflow-windows-x64.zip"
        if (Test-Path $outputPath) { Remove-Item $outputPath }
        
        # Cria arquivo ZIP
        Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath $outputPath
        
        Write-Host ""
        Write-Host "[√] Executável Windows compactado com sucesso!" -ForegroundColor Green
        Write-Host "[i] Arquivo disponível em: $outputPath" -ForegroundColor Green
    } else {
        Write-Host "[x] Falha na compilação do Windows. Certifique-se de ter instalado o Visual Studio com o workload 'Desktop development with C++'." -ForegroundColor Red
    }
}

if ($choice -eq "4") {
    Write-Host "Operação cancelada pelo usuário."
    Exit 0
}
