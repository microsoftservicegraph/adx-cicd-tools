#Requires -PSEdition Core

$adxToolsDir = "$env:APPDATA\..\Local\adxTools"
$KustoCli = "$adxToolsDir\kcli\kusto.cli.exe"

function GetOrDownloadCli {
  [CmdletBinding()]
  param (
    $CliZipUri
    , $CliPath
  )

  Process {
    if (-not (Test-Path $CliPath)) {
      Write-Host -ForegroundColor Green "$(Split-Path -Leaf $CliPath) not found. downloading..."
      $tempFile = "$env:TEMP\$((New-TemporaryFile).Name).zip"
      Invoke-WebRequest -Uri $CliZipUri -OutFile $tempFile

      mkdir $adxToolsDir -Force | Out-Null
      Expand-Archive -LiteralPath $tempFile -DestinationPath $adxToolsDir -Force
    }

    Write-Host -ForegroundColor DarkGray "Using $CliPath"
    $CliPath
  }
}

# Download the CLIs if it does not exist.
GetOrDownloadCli "https://msgpublictools.blob.core.windows.net/tools/kcli.zip" $KustoCli

Export-ModuleMember -Variable KustoCli
