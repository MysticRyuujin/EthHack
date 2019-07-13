# This requires Nethereum DLL files
# https://github.com/Nethereum/Nethereum/releases

$block = {
    Add-Type -Path 'C:\EthHack\net461dlls\Nethereum.Signer.dll' # Nethereum DLL
    Add-Type -Path 'C:\EthHack\net461dlls\Nethereum.Web3.dll' # Nethereum DLL
    $Web3 = [Nethereum.Web3.Web3]::new('http://localhost:8545') # JSON-RPC Host (this can also be a WebSocket connection object)
    while ($True) {
        $NewKey = [Nethereum.Signer.EthECKey]::GenerateKey()
        $Address = $NewKey.GetPublicAddress()
        try {
            $Balance = [Nethereum.Web3.Web3]::Convert.FromWei($Web3.Eth.GetBalance.SendRequestAsync($Address).GetAwaiter().GetResult().Value)
        } catch {
            $Balance = -1
        }
        if ($Balance -ne 0) {
            $Result = [psobject]@{
                Address = $Address
                Private = $NewKey.GetPrivateKey()
                Balance = $Balance
            }
            if ($Balance -gt 0) {
                ConvertTo-JSON -InputObject $Result | Out-File "C:\EthHack\Found\$address.txt"
            } else {
                ConvertTo-JSON -InputObject $Result | Out-File "C:\EthHack\Error\$address.txt"
            }
        }
    }
}

# 16 instances seems to do pretty well to nearly max out my 4c/8t CPU
for ($i=0; $i -lt 16; $i++) {
    $null = Start-Job -Scriptblock $Block
}

# This will never end, simply closing the window will exit all processes though
While ($(Get-Job -State Running).count -gt 0) {
    Start-Sleep 3600
}
