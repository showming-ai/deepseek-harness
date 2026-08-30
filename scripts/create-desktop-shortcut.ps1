$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$batPath = Join-Path $repoRoot 'start-deepseek-harness.bat'
$assetsDir = Join-Path $repoRoot 'assets'
$icoPath = Join-Path $assetsDir 'deepseek.ico'

if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
}

# Generate ICO if not exists
try {
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    $bmp = New-Object System.Drawing.Bitmap(256, 256)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $rect = New-Object System.Drawing.Rectangle(16, 16, 224, 224)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(255, 66, 133, 244),
        [System.Drawing.Color]::FromArgb(255, 26, 60, 180),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    $g.FillEllipse($brush, $rect)

    $font = New-Object System.Drawing.Font('Arial Black', 58, [System.Drawing.FontStyle]::Bold)
    $textBrush = [System.Drawing.Brushes]::White
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center

    $textRect = New-Object System.Drawing.RectangleF(0, 0, 256, 256)
    $g.DrawString('DSH', $font, $textBrush, $textRect, $sf)

    $hIcon = $bmp.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $fs = New-Object System.IO.FileStream($icoPath, [System.IO.FileMode]::Create)
    $icon.Save($fs)
    $fs.Close()
    $bmp.Dispose()
    $g.Dispose()
    Write-Host "已生成圖示檔案: $icoPath"
} catch {
    Write-Warning "生成圖示失敗: $_"
}

# Find Desktop folders
$desktopPaths = @()
$specialDesktop = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
if ($specialDesktop -and (Test-Path $specialDesktop)) {
    $desktopPaths += $specialDesktop
}
$userProfileDesktop = Join-Path $env:USERPROFILE 'Desktop'
if ($userProfileDesktop -and (Test-Path $userProfileDesktop) -and ($desktopPaths -notcontains $userProfileDesktop)) {
    $desktopPaths += $userProfileDesktop
}

$wshShell = New-Object -ComObject WScript.Shell

foreach ($desktop in $desktopPaths) {
    $shortcutPath = Join-Path $desktop 'DeepSeek Harness.lnk'
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $batPath
    $shortcut.WorkingDirectory = $repoRoot.Path
    $shortcut.Description = '啟動 DeepSeek Harness (Web UI)'
    if (Test-Path $icoPath) {
        $shortcut.IconLocation = "$icoPath,0"
    }
    $shortcut.Save()
    Write-Host "已成功建立桌面捷徑: $shortcutPath"
}
