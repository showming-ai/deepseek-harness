$ErrorActionPreference = 'SilentlyContinue'
$conns = Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue
if ($conns) {
    foreach ($c in $conns) {
        if ($c.OwningProcess -gt 0) {
            Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
            Write-Host "[提示] 已關閉佔用 Port 3080 的舊程序 (PID: $($c.OwningProcess))"
        }
    }
}
