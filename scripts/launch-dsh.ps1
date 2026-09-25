$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = 'DeepSeek Harness Launcher'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "               DeepSeek Harness 啟動器                  " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "工作目錄: $($repoRoot.Path)" -ForegroundColor Gray
Write-Host ""

# 1. 檢查 Node.js
try {
    $nodeVer = & node -v
    if ($LASTEXITCODE -ne 0) {
        throw "node -v failed with exit code $LASTEXITCODE."
    }
    Write-Host "[✓] Node.js 版本: $nodeVer" -ForegroundColor Green
} catch {
    Write-Host "[錯誤] Node.js 無法正常執行，請先修復或安裝 Node.js (>= 22.19.0)。" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Write-Host "下載網址: https://nodejs.org/" -ForegroundColor Yellow
    Read-Host "請按 Enter 鍵結束..."
    exit 1
}

# 2. 檢查 pnpm
try {
    $pnpmVer = & pnpm -v
    if ($LASTEXITCODE -ne 0) {
        throw "pnpm -v failed with exit code $LASTEXITCODE."
    }
    Write-Host "[✓] pnpm 版本: $pnpmVer" -ForegroundColor Green
} catch {
    Write-Host "[錯誤] pnpm 無法正常執行，請先修復 Node.js / pnpm 安裝。" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor DarkRed
    Read-Host "請按 Enter 鍵結束..."
    exit 1
}

# 3. 檢查編譯產物是否齊全
$buildRecord = Join-Path $repoRoot.Path '.dsh-build\client-build-environment.json'
if (-not (Test-Path $buildRecord)) {
    Write-Host ""
    Write-Host "[提示] 偵測到專案尚未編譯或剛完成更新，正在自動執行編譯 (pnpm run build)..." -ForegroundColor Yellow
    & pnpm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[錯誤] 專案編譯失敗，請檢查錯誤訊息。" -ForegroundColor Red
        Read-Host "請按 Enter 鍵結束..."
        exit 1
    }
    Write-Host "[✓] 編譯完成！" -ForegroundColor Green
}

# 4. 檢查並清理殘留的 Port 3080 程序
$conns = Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue
if ($conns) {
    foreach ($c in $conns) {
        if ($c.OwningProcess -gt 0) {
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-Host "[提示] 已清理先前佔用 Port 3080 的舊程序 (PID: $($c.OwningProcess))" -ForegroundColor Yellow
        }
    }
}

# 5. 啟動 Web UI
Write-Host ""
Write-Host "正在啟動 DeepSeek Harness Web UI..." -ForegroundColor Cyan
Write-Host "提示:" -ForegroundColor Gray
Write-Host " - 預設網址: http://127.0.0.1:3080 (啟動完成後會自動開啟瀏覽器)" -ForegroundColor Gray
Write-Host " - 停止服務請按 Ctrl + C 或直接關閉此視窗" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

& pnpm dsh web

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "[提示] 服務已終止或發生錯誤 (Exit Code: $LASTEXITCODE)。" -ForegroundColor Red
    $choice = Read-Host "是否嘗試重新安裝依賴並重新編譯？ (Y/N)"
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        Write-Host "正在執行 pnpm install..." -ForegroundColor Yellow
        & pnpm install
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[錯誤] 依賴安裝失敗，未繼續編譯或重新啟動。" -ForegroundColor Red
            exit $LASTEXITCODE
        }
        Write-Host "正在執行 pnpm run build..." -ForegroundColor Yellow
        & pnpm run build
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[錯誤] 專案編譯失敗，未重新啟動。" -ForegroundColor Red
            exit $LASTEXITCODE
        }
        Write-Host "重新啟動中..." -ForegroundColor Cyan
        & pnpm dsh web
    }
}
