#Requires -PSEdition Core

function Remove-ADXArtifacts {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
  }
}

Export-ModuleMember -Function Remove-ADXArtifacts
