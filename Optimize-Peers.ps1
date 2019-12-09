# Compare peers on nodes, remove redundant peers
function Optimize-ETHPeers {
    [CmdletBinding()]
    param (
        $Nodes = @(
            "http://node1:8545",
            "http://node2:8545",
            "http://node3:8545"
        )
    )

    begin {
        $PeerDict = [hashtable]@{}
    }
    
    process {
        foreach ($Node in $Nodes) {
            $Peers = (Get-ETHPeers -Node $Node).enode -as [System.Collections.Generic.List[string]]
            $PeerDict.Add($Node,$Peers)
        }
        for ($i=0; $i -lt $Nodes.Count; $i++) {
            # When dealing with the last node ($node[-1]) target first node ($node[0])
            if (($i + 1) -eq $Nodes.Count) {
                $a = 0
            } else {
                $a = $i+1
            }
            Compare-Object -ReferenceObject $PeerDict."$($Nodes[$i])" -DifferenceObject $PeerDict."$($Nodes[$a])" -ExcludeDifferent -IncludeEqual | ForEach-Object {
                # Ignore Private IP Space (we want local nodes peered)
                if ($_.InputObject -match "@192\.168|@172\.1[6-9]\.|@172\.2[0-9]\.|172.3[0-2]\.|@10\.") {
                    continue
                }
                # Remove the node randomly (helps prevent node[1] from lossing too many peers)
                $b = Get-Random ($i,$a)
                Write-Host "Removing $($_.InputObject) from $($Nodes[$b])" -ForegroundColor Cyan
                try {
                    Remove-ETHPeer -Node $Nodes[$b] -Peer $_.InputObject
                    $null = $PeerDict."$($Nodes[$b])".Remove($_.InputObject)
                    Write-Host "Success" -ForegroundColor Green
                } catch { 
                    Write-Host "Failed" -ForegroundColor Red
                    continue
                }
            }
        }
    }
}

function Get-ETHPeers {
    [CmdletBinding()]
    param (
        $Node
    )
    
    begin {
        $Body = @{
            "jsonrpc" = "2.0"
            "method" = "admin_peers"
            "id" = Get-Random
        }
    }
    
    process {
        (Invoke-RestMethod -Method Post -Uri $Node -Body ($Body | ConvertTo-Json) -ContentType 'application/json').result
    }
}

function Remove-ETHPeer {
    [CmdletBinding()]
    param (
        $Node,
        $Peer
    )

    begin {
        $Body = @{
            "jsonrpc" = "2.0"
            "method" = "admin_removePeer"
            "params" = $Peer -as [array]
            "id" = Get-Random
        }
    }

    process {
        $null = (Invoke-RestMethod -Method Post -Uri $Node -Body ($Body | ConvertTo-Json) -ContentType 'application/json')
    }
}
