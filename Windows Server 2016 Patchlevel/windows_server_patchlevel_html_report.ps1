<#    
    .SYNOPSIS
    Auflistung aller Windows Server Patchlevel im WSUS als HTML Report
    .DESCRIPTION
    PowerShell Script zur Auflistung aller Windows Server
    und Sortierung nach Release/Build inkl. HTML Report
    .EXAMPLE
    C:\Scripts\windows_server_patchlevel_html_report.ps1
    .NOTES
    Date:    10.04.2019
    Author:  Jan Kappen
    Website: https://www.zueschen.eu
    Twitter: @JanKappen
#>

# Variablen und Einstellungen
$WSUSServer = "WSUS_Servername"
$Port = "8531"
$Groupname = "Server"
$date = Get-Date -UFormat "%Y%m%d"
$Logfile = "C:\temp\$date-wsus_server_log.log"
$HTMLFile = "C:\temp\$date-wsus_server_log.htm"
$SSL = $true
# holen der vorhandenen Releases vom WSUS
$computer = Get-WsusServer -Name $WSUSServer -Port $Port |get-wsuscomputer
$releases = $computer.clientversion |ForEach-Object {"{0}.{1}" -f $_.Build,$_.Revision} |Sort-Object -Unique

# Prüfung auf benötigtes Modul
if (-not (Get-Module -ListAvailable -Name ReportHTML)) {
    Write-Host -ForegroundColor Red 'Benötigtes Modul "ReportHTML" nicht vorhanden, Abbruch!'`n
    Write-Host -ForegroundColor Green 'Installation muss mir "Install-Module -Name ReportHTML" durchgeführt werden'
    Write-Host -ForegroundColor Green 'Weitere Infos unter "https://www.powershellgallery.com/packages/ReportHTML/"'
    # Hilfe und Anleitung: https://azurefieldnotesblog.blob.core.windows.net/wp-content/2017/06/Help-ReportHTML2.html
    exit 
}

# Abfrage der WSUS-Clients
if ($SSL -eq $true) {
    $Clients = Get-WsusServer -Name $WSUSServer -Port $Port -UseSsl | get-wsuscomputer -ComputerTargetGroups $Groupname | select FullDomainName, IPAddress, ClientVersion, OSDescription, RequestedTargetGroupName
} else {
    $Clients = Get-WsusServer -Name $WSUSServer -Port $Port | get-wsuscomputer -ComputerTargetGroups $Groupname | select FullDomainName, IPAddress, ClientVersion, OSDescription, RequestedTargetGroupName
}

# Bau den Report
$rpt = @()
$rpt += Get-HTMLOpenPage -TitleText "WSUS Status Übersicht - Windows Server 2016 Patchlevel" -HideLogos

$rpt += Get-HtmlContentOpen -HeaderText "Weitere Informationen - https://support.microsoft.com/en-us/help/4000825/windows-10-windows-server-2016-update-history"
$rpt += Get-HTMLContentClose

#region
foreach ($release in $releases) {

    # Auflistung der Systeme und Zuordnung zu Build-Version
    $x = @()
    foreach ($Client in $Clients) {
        if ($Client.ClientVersion -match $release) {
            $x += $Client
        }}

    ### Hinzufügen zu Liste (nur wenn Variable nicht leer)
    if ($x) {
        $rpt += Get-HtmlContentOpen -HeaderText "OS-Build $release"
            $rpt+= Get-HtmlContentTable $x
        $rpt += Get-HTMLContentClose 
    }
}

#
$rpt += Get-HTMLClosePage  
$rpt | set-content -path "c:\temp\server_status.html"

# Ablegen der Output-Datei im IIS-Verzeichnis
Set-Content -Value $rpt -path "C:\inetpub\wwwroot\server_status.html"  
