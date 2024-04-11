function Test-Telnet {
    param (
        [string]$IP,
        [int]$Port
    )

    $result = $null
    $timeout = 2 # Thời gian timeout, tính bằng giây

    try {
        $tcpclient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpclient.BeginConnect($IP, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($timeout * 1000, $false)

        if (-not $wait -or -not $tcpclient.Connected) {
            $tcpclient.Close()
            $result = $false
        } else {
            $tcpclient.EndConnect($asyncResult) | Out-Null
            $tcpclient.Close()
            $result = $true
        }
    } catch {
        $result = $false
    }

    return $result
}

function Validate-IP {
    param (
        [string]$IP
    )
    $octets = $IP -split '\.'
    if ($octets.Count -ne 4) {
        return $false
    }
    foreach ($octet in $octets) {
        if (-not ($octet -as [int] -ge 0 -and $octet -as [int] -le 255)) {
            return $false
        }
    }
    return $true
}

function Validate-Port {
    param (
        [string]$Port
    )
    if ($Port -match '^\d{1,5}$' -and $Port -as [int] -ge 0 -and $Port -as [int] -le 65535) {
        return $true
    }
    return $false
}

function Test-FileExistence {
    param (
        [string]$FilePath
    )
    if (-not (Test-Path $FilePath)) {
        throw "File không tồn tại."
    }
    return $true
}

$firstTelnet = $true

do {
    if ($firstTelnet) {
        $choice = Read-Host "Chọn 1 để nhập IP hoặc 2 để nhập đường dẫn tới file danh sách IP"
    } else {
        $choice = Read-Host "Chọn 1 để nhập IP, 2 để nhập đường dẫn tới file danh sách IP, hoặc 3 để thoát"
    }

    if ($choice -eq "1") {
        do {
            $IP = Read-Host "Nhập địa chỉ IP"
            if (-not (Validate-IP -IP $IP)) {
                Write-Host "Địa chỉ IP không hợp lệ. Vui lòng nhập lại." -ForegroundColor Red
                $validIP = $false
            } else {
                $validIP = $true
            }
        } while (-not $validIP)
        $IPs = @($IP)
    }
    elseif ($choice -eq "2") {
        do {
            $FilePath = Read-Host "Nhập đường dẫn đến file danh sách IP"
            if (-not (Test-Path $FilePath)) {
                Write-Host "File không tồn tại. Vui lòng nhập lại đường dẫn." -ForegroundColor Red
                $validFilePath = $false
            } else {
                $validFilePath = $true
            }
        } while (-not $validFilePath)
        $IPs = Get-Content $FilePath | Where-Object { $_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' }
    }

    if ($choice -eq "1" -or $choice -eq "2") {
        do {
            $Port = Read-Host "Nhập cổng"
            if (-not (Validate-Port -Port $Port)) {
                Write-Host "Cổng không hợp lệ. Vui lòng nhập lại." -ForegroundColor Red
                $validPort = $false
            } else {
                $validPort = $true
            }
        } while (-not $validPort)

        foreach ($IP in $IPs) {
            if (-not (Validate-IP -IP $IP)) {
                continue
            }
            $telnetResult = Test-Telnet -IP $IP -Port $Port
            if ($telnetResult) {
                Write-Host "Telnet thành công tới địa chỉ IP: $IP" -ForegroundColor Green
            } else {
                Write-Host "Không thể telnet tới địa chỉ IP: $IP" -ForegroundColor Red
            }
        }

        $firstTelnet = $false
    }
} while ($choice -ne "3")
