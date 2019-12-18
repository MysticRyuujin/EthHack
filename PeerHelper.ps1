# If your node is on a remote PC you'll need to open up RPC connectivity
# Edit localhost to the remote IP
$MyNode = "http://localhost:8545"

# Function for adding Peers to a node
function Add-ETHPeer {
    [CmdletBinding()]
    param (
        $Node,
        $Peer
    )

    begin {
        $Body = @{
            "jsonrpc" = "2.0"
            "method" = "admin_addPeer"
            "params" = $Peer -as [array]
            "id" = Get-Random
        }
    }

    process {
        $null = (Invoke-RestMethod -Method Post -Uri $Node -Body ($Body | ConvertTo-Json) -ContentType 'application/json')
    }
}

# Create a List to hold endodeIds
$NodeList = [System.Collections.Generic.List[string]]::new()

# Currently there are 200 pages shown by default
$MaxPages = 200

for ($i=1; $i -le $MaxPages; $i++) {

    # Get the list of nodes from etherscan page #
    $WebRequest = Invoke-WebRequest "https://etherscan.io/nodetracker/nodes?p=$i"

    # Parse all of the 'tr' elements from the page
    $TRs = $WebRequest.ParsedHtml.getElementsByTagName("tr")

    # Loop through the TR elements looking for node data
    ForEach ($TR in $TRs) {
        try {
            $TDs = $TR.getElementsByTagName('td')
            $enodeId = $TDs[0].innerText
            $IP = $TDs[2].innerText
            $Port = $TDs[3].innerText
        } catch {
            continue
        }
        if (($enodeId) -and ($IP) -and ($Port)) {
            # If the port is 0, try 30303?
            if ($Port -eq "0") {
                $Port = "30303"
            }
            # Add it to the list
            $NodeList.Add("enode://$enodeId@$IP`:$Port")
            
            # If the peer isn't 30303 (default port) maybe etherscan found it via an 'incoming' connection
            # Let's try also adding the enode as 30303, it can't hurt to try...?
            if ($Port -ne "30303") {
                $NodeList.Add("enode://$enodeId@$IP`:30303")
            }
        }
    }
}

# Loop through all of the discovered enodes and try to add them
# You could also just run the below to output to a file:
# $NodeList | ConvertTo-JSON | Out-File "static-nodes.json"
ForEach ($Enode in $NodeList) {
    Add-ETHPeer -Node $MyNode -Peer $Enode
}
