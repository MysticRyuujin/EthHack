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
            $Peers = (Get-ETHPeers -Nodes $Node).enode
            ForEach ($Peer in $Peers) {
                if ($Peer -match "enode://(.*)@(.*):(.*)") {
                    $Enode = $Matches[1]
                    $IP = $Matches[2]
                    $Port = $Matches[3]
                    if ($PeerDict.$Enode) {
                        $PeerDict.$Enode.Add(
                            @{
                                "Node" = $Node
                                "IP" = $IP
                                "Port" = $Port
                            }
                        )
                    }
                    else {
                        $PeerDict.Add(
                            $Enode,
                            [System.Collections.Generic.List[Hashtable]]::new()
                        )
                        $PeerDict.$Enode.Add(
                            @{
                                "Node" = $Node
                                "IP" = $IP
                                "Port" = $Port
                            }
                        )
                    }
                }
            }
        }
        ForEach ($Peer in $PeerDict.Keys) {
            # Ignore Private IP Space (we want local nodes peered)
            if ($PeerDict.$Peer.IP -match "@192\.168|@172\.1[6-9]\.|@172\.2[0-9]\.|172.3[0-2]\.|@10\.") {
                continue
            }
            if ($PeerDict.$Peer.Count -gt 1) {
                Get-Random ($PeerDict.$Peer -as [array]) -Count ($PeerDict.$Peer.Count - 1) | ForEach-Object {
                    Write-Host "Removing $Peer from $($_.Node)" -ForegroundColor Cyan
                    try {
                        $null = Remove-ETHPeers -Node $_.Node -Peers "enode://$Peer@$($_.IP):$($_.Port)"
                        Write-Host "Success" -ForegroundColor Green
                    }
                    catch {
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
        [Alias("Node")]
        [uri[]]$Nodes
    )
    begin {
        $Body = @{
            "jsonrpc" = "2.0"
            "method"  = "admin_peers"
            "id"      = Get-Random
        }
    }
    process {
        ForEach ($Node in $Nodes) {
            (Invoke-RestMethod -Method Post -Uri $Node -Body ($Body | ConvertTo-Json) -ContentType 'application/json').result
        }
    }
}

function Remove-ETHPeers {
    [CmdletBinding()]
    param (
        [uri]$Node,

        [Alias("Peer")]
        [uri[]]$Peers
    )
    begin {
        $Body = @{
            "jsonrpc" = "2.0"
            "method"  = "admin_removePeer"
            "params"  = [System.Object]::new()
            "id"      = Get-Random
        }
    }
    process {
        ForEach ($Peer in $Peers) {
            $Body.params = $Peer -as [array]
            (Invoke-RestMethod -Method Post -Uri $Node -Body ($Body | ConvertTo-Json) -ContentType 'application/json').result
        }
    }
}
