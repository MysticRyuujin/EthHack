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
        # Get all of the current peers
        foreach ($Node in $Nodes) {
            $Peers = (Get-ETHPeers -Node $Node).enode
            ForEach ($Peer in $Peers) {
                if ($PeerDict.$Peer) {
                    $PeerDict.$Peer.Add($Node)
                } else {
                    $PeerDict.Add($Peer,$Node -as [System.Collections.Generic.List[string]])
                }
            }
        }
        ForEach ($Peer in $PeerDict.Keys) {
            if ($PeerDict.$Peer.Count -gt 1) {
                Get-Random ($PeerDict.$Peer -as [array]) -Count ($PeerDict.$Peer.Count - 1) | ForEach-Object {
                    Write-Host "Removing $Peer from $_" -ForegroundColor Cyan
                    try {
                        Remove-ETHPeer -Node $_ -Peer $Peer
                        Write-Host "Success" -ForegroundColor Green
                    } catch {
                        Write-Host "Failed" -ForegroundColor Red
                    }
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
