# to start - .\Webserver.ps1 portno

PARAM(
    [Parameter(Mandatory = $true)]
    $ipaddr,

    [Parameter(Mandatory = $true)]
    $portno
)

$url = 'http://' + $ipaddr + ':'+$portno+'/'
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
$listener.Start()

Write-Host "Listening at $url..."

netsh advfirewall firewall add rule name="Powershell Webserver" dir=in action=allow protocol=TCP localport=$portno

$killFlag = $false
while ($listener.IsListening -And !$killFlag)
{
    $context = $listener.GetContext()
    $requestUrl = $context.Request.Url
    $response = $context.Response

    Write-Host ''
    Write-Host "> Incoming request from $requestUrl"

    $ipadd = (Get-NetIPConfiguration |
        Where-Object {
            $_.IPv4DefaultGateway -ne $null -and
            $_.NetAdapter.Status -ne "Disconnected"
        }
    ).IPv4Address.IPAddress

    $localPath = $requestUrl.LocalPath
    Write-Host "> Incoming localpath is $localPath"
    if ($localPath -eq "/kill") {
        $killFlag = $true
        $content = "Kill request to " + $ipadd + " at " + (get-Date).toString()
    }
    else {
        $content = "Response from " + $ipadd + " at " + (get-Date).toString()
    }
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)
    $response.OutputStream.Write($buffer,0,$buffer.Length)
    $response.Close()
}
$listener.Stop()
$listener.Close()

netsh advfirewall firewall delete rule name="Powershell Webserver"