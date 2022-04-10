#Requires -PSEdition Core

function Test-ADXArtifacts {
  [CmdletBinding()]
  param (
    [Parameter(ValueFromPipeline = $true)] $Category
  )

  Process {
  }
}


Export-ModuleMember -Function Test-ADXArtifacts
