#Requires -PSEdition Core

function Build-ADXArtifacts {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
  }
}

Export-ModuleMember -Function Build-ADXArtifacts
