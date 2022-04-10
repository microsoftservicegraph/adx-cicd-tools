#Requires -PSEdition Core

Set-LoggingDefaultLevel -Level INFO
Set-LoggingDefaultFormat '[%{timestamp:+%Y-%m-%d %T}] [%{level:-7}] %{message}'
Add-LoggingTarget -Name Console


$adxToolsDir = "$env:APPDATA\..\Local\adxTools"
$KustoCliExePath = "$adxToolsDir\kcli\kusto.cli.exe"

function GetOrDownloadCli {
  [CmdletBinding()]
  param (
    $CliZipUri
    , $CliPath
  )

  Process {
    if (-not (Test-Path $CliPath)) {
      Write-Log -Level INFO -Message "$(Split-Path -Leaf $CliPath) not found. downloading..."
      $tempFile = "$env:TEMP\$((New-TemporaryFile).Name).zip"
      Invoke-WebRequest -Uri $CliZipUri -OutFile $tempFile

      mkdir $adxToolsDir -Force | Out-Null
      Expand-Archive -LiteralPath $tempFile -DestinationPath $adxToolsDir -Force
    }

    Write-Log -Level INFO -Message "Using {0}" -Arguments $CliPath
    $CliPath
  }
}

# Download the CLIs if it does not exist.
GetOrDownloadCli "https://msgpublictools.blob.core.windows.net/tools/kcli.zip" $KustoCliExePath

Export-ModuleMember -Variable KustoCliExePath
