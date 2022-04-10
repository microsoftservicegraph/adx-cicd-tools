#Requires -PSEdition Core

$adxToolsDir = "$env:APPDATA\..\Local\adxTools"
$KustoCliExePath = "$adxToolsDir\kcli\kusto.cli.exe"

function GetScopedBinFilePath {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $BaseName
  )

  Process {
    $clusterName = $Cluster.Split('.')[0]
    Join-Path $PWD "bin\$clusterName.$Database.$BaseName"
  }
}

function GetLogFilePath {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $BaseName
  )

  Process {
    $clusterName = $Cluster.Split('.')[0]
    Join-Path $PWD "logs\$clusterName.$Database.$BaseName.log"
  }
}

function ExecuteKustoCli {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth
    , $CommandName
    , $Arguments
    , $LogFilePath
    , [switch] $WhatIf
  )

  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True
  $kustoCliArgs = @("https://$Cluster/$Database;$Auth", "-lineMode:false") + $Arguments
  $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True
  if ($Verbose) {
    Write-Log -Level DEBUG -Message "$KustoCliExePath $($kustoCliArgs -join ' ')"
  }
  if ($WhatIf) {
    Write-Log -Level WARNING -Message "Skipping actually running command due to -WhatIf"
    Start-Sleep -Milliseconds 50
  } else {
    $OutLogFilePath = $LogFilePath -replace '\.log', '_out.log'
    $ErrorLogFilePath = $LogFilePath -replace '\.log', '_err.log'

    Start-Process -NoNewWindow -Wait -filepath $KustoCliExePath -ArgumentList $kustoCliArgs -RedirectStandardOutput $OutLogFilePath -RedirectStandardError $ErrorLogFilePath

    Get-Content $OutLogFilePath, $ErrorLogFilePath | Set-Content $LogFilePath
    Remove-Item $OutLogFilePath, $ErrorLogFilePath

    PostProcessCommand $CommandName $LogFilePath -Verbose:$Verbose
  }
}

function ExecuteKustoCommand {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth
    , $LogFileBaseName = ""
    , [Parameter(ValueFromPipeline = $true)] $Command
    , [switch] $WhatIf
  )

  Process {
    $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True
    PreProcessCommand $Command -Verbose:$Verbose
    [char[]] $fileUnsafeChars = [IO.Path]::GetInvalidFileNameChars() + @(' ', '.')
    $logFileName = $LogFileBaseName
    if (-not $logFileName) {
      $logFileName = $Command.Split($fileUnsafeChars) -join '_'
    }
    $logFilePath = GetLogFilePath $Cluster $Database $logFileName
    ExecuteKustoCli $Cluster $Database $Auth $Command @("-execute:`"$Command`"") $logFilePath -WhatIf:$WhatIf -Verbose:$Verbose
  }
}

function ExecuteKustoScript {
  [CmdletBinding()]
  param (
    $Cluster
    , $Database
    , $Auth
    , [Parameter(ValueFromPipeline = $true)] $ScriptPath
    , [switch] $WhatIf
  )

  Process {
    $Verbose = $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -eq $True
    PreProcessCommand $ScriptPath -Verbose:$Verbose
    $logFilePath = GetLogFilePath $Cluster $Database $ScriptPath.BaseName
    ExecuteKustoCli $Cluster $Database $Auth $ScriptPath.FullName @("-script:`"$($ScriptPath.FullName)`"") $logFilePath -WhatIf:$WhatIf -Verbose:$Verbose
  }
}

function PreProcessCommand {
  [CmdletBinding()]
  param (
    $Command
  )

  Process {
    if (-not $Verbose) {
      return
    }

    Write-Log -Level INFO -Message ""
    Write-Log -Level INFO -Message "Executing: $Command"
  }
}

function PostProcessCommand {
  [CmdletBinding()]
  param (
    $Command
    , $LogFilePath
  )

  Process {
    $errors = Select-String -Path $LogFilePath -Pattern "Failed to execute:"
    if ($errors.Length -eq 0) {
      if ($Verbose) {
        Write-Log -Level INFO -Message "... Successfully executed: $Command"
        $lastLine = (Get-Content $LogFilePath)[-1]
        Write-Log -Level INFO -Message "... $lastLine"
      }
    } else {
      Write-Log -Level ERROR -Message "... Failed to execute: $Command"
      Write-Log -Level ERROR -Message "... ... More details in the logfile $LogFilePath"
    }
  }
}
