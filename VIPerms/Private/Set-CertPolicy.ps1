function Set-CertPolicy {
    <#
    .SYNOPSIS
    Ignore SSL verification.

    .DESCRIPTION
    Using a custom .NET type, override SSL verification policies.
    #>

    param (
        [Switch] $SkipCertificateCheck,
        [Switch] $ResetToDefault
    )

    try {
        if ($SkipCertificateCheck) {
            if ($PSVersionTable.PSEdition -eq 'Core') {
                # Invoke-restmethod provide Skip certcheck param in PowerShell Core
                $Script:PSDefaultParameterValues = @{
                    "invoke-restmethod:SkipCertificateCheck" = $true
                    "invoke-webrequest:SkipCertificateCheck" = $true
                }
            } else {
                # Load the assembly containing TrustAllCertsPolicy if not already loaded
                $assemblyName = 'System.Net.Http'
                $loadedAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object { $_.GetName().Name }

                if (-not $loadedAssemblies.Contains($assemblyName)) {
                    Add-Type -AssemblyName $assemblyName
                }

                Add-Type -TypeDefinition  @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                        return true;
                    }
                }
"@
                [Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
            }
        }
    } catch {
        $Err = $_
        throw $Err
    }
}
