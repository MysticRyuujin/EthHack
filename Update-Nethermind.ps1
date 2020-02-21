Function Update-Nethermind {
    [CmdletBinding()]
    param()
    begin {

    }
    process {
        Write-Host "Getting latest release from GitHub" -ForegroundColor Cyan
        try {
            $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/NethermindEth/nethermind/releases/latest"
        } catch {
            $_
            break
        }
        $WindowsRelease = $LatestRelease.assets | Where-Object name -match "nethermind-windows-amd64.*.zip"
        if (!$WindowsRelease) {
            Write-Error "Could not find an asset matching nethermind-windows-amd64.*.zip"
            break
        }
        
        Write-Host "Downloading $($WindowsRelease.browser_download_url)" -ForegroundColor DarkMagenta
        try {
            Invoke-WebRequest -Uri $WindowsRelease.browser_download_url -OutFile "E:\Nethermind\Releases\$($WindowsRelease.name)"
        } catch {
            $_
            break
        }

        if (Test-Path -LiteralPath "E:\Nethermind\Releases\Extracted\") {
            Write-Host "Removing old upgrade folder" -ForegroundColor Yellow
            Remove-Item -LiteralPath "E:\Nethermind\Releases\Extracted\" -Recurse -Force
        }
        Write-Host "Extracing Files" -ForegroundColor Cyan
        Expand-Archive -LiteralPath "E:\Nethermind\Releases\$($WindowsRelease.name)" -DestinationPath "E:\Nethermind\Releases\Extracted\"
        
        Write-Host "Getting running process" -ForegroundColor Cyan
        $Nethermind = Get-Process -Name "Nethermind.Runner" -ErrorAction SilentlyContinue
        if (!$Nethermind) {
            Write-Host "Nethermind not running" -ForegroundColor Yellow
        } else {
            Write-Host "Attempting to close Nethermind gracefully" -ForegroundColor DarkGreen
            $wshell = New-Object -ComObject wscript.shell
            [void]$wshell.AppActivate($Nethermind.MainWindowTitle)
            $wshell.SendKeys("^{c}")
            Write-Host "Waiting for Nethermind to close..." -ForegroundColor DarkMagenta -NoNewline
            while ((Get-Process -Name "Nethermind.Runner" -ErrorAction SilentlyContinue)) {
                Write-Host "." -ForegroundColor DarkMagenta -NoNewline
                Start-Sleep -Seconds 1
            }
            Write-Host "Nethermind closed" -ForegroundColor Green
        }

        if (Test-Path -LiteralPath "E:\Nethermind\Current\") {
            Write-Host "Removing current Nethermind folder" -ForegroundColor Yellow
            Remove-Item -LiteralPath "E:\Nethermind\Current\" -Recurse -Force
        }
        Write-Host "Upgrading Nethermind" -ForegroundColor Cyan
        Copy-Item -LiteralPath "E:\Nethermind\Releases\Extracted\" -Destination "E:\Nethermind\Current\" -Recurse -Force
    }
    end {
        Start-ScheduledTask -TaskName "Nethermind"
        Write-Host "Done" -ForegroundColor Green
    }
}
