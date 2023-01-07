##----------------------------------------------------------------------------------------------------------------------
##  Validators
##----------------------------------------------------------------------------------------------------------------------

$Validators = @{ };

##----------------------------------------------------------------------------------------------------------------------
##  Filter Function
##----------------------------------------------------------------------------------------------------------------------

function PD-Validate
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    if ($Validator -is [array])
    {
        ForEach ($SubValidator in $Validator)
        {
            if (PD-Validate -Validator $SubValidator)
            {
                return $True;
            }
        }

        return $False;
    }
    
    if ($Validator -is [string])
    {
        if ($Validator -match "^([a-zA-Z]+):(.+)$")
        {
            if ($Validators.$($Matches[1]))
            {
                return $Validators.$($Matches[1]).Invoke($Matches[2]);
            }
        }
    }

    Write-Log "Invalid Validator $Validator";

    return $False;
};

##----------------------------------------------------------------------------------------------------------------------
##  File
##----------------------------------------------------------------------------------------------------------------------

$Validators.File =
{
    param
    (
        [Parameter(Mandatory = $True)] $File
    );

    return (Test-Path ([System.Environment]::ExpandEnvironmentVariables($File)));
};

##----------------------------------------------------------------------------------------------------------------------
##  GUID
##----------------------------------------------------------------------------------------------------------------------

$Validators.guid =
{
    param
    (
        [Parameter(Mandatory = $True)] $ID
    );

    return (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$ID");
};

##----------------------------------------------------------------------------------------------------------------------
##  PowerShell
##----------------------------------------------------------------------------------------------------------------------

$Validators.powershell =
{
    param
    (
        [Parameter(Mandatory = $True)] $Command
    );

    return (Invoke-Expression -Command $Command);
};

##----------------------------------------------------------------------------------------------------------------------
##  package
##----------------------------------------------------------------------------------------------------------------------

$Validators.Package =
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    return ((Get-Package $Item.Publisher.ProductName -ErrorAction SilentlyContinue) -ne $Null);
}

##----------------------------------------------------------------------------------------------------------------------
##  Version
##----------------------------------------------------------------------------------------------------------------------

$Validators.version =
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    if ($Validator -match "^(.+)([<>=])([0-9\.]+)$")
    {
        $Version = $Null;
        $Target = $Matches[3];
        $File = [System.Environment]::ExpandEnvironmentVariables($Matches[1]);

        if (Test-Path $File)
        {
            $Version = ([string](Get-Command $File).Version);
        }
        else
        {
            $InstalledPackage = (Get-Package $Item.Publisher.ProductName -ErrorAction SilentlyContinue);

            if ($InstalledPackage)
            {
                $Version = $InstalledPackage.Version;
            }
        }

        if ($Version)
        {
            if ($Matches[2] -eq "=")
            {
                return $Target -eq $Version;
            }
            elseif ($Matches[2] -eq ">")
            {
                return $Target -gt $Version;
            }
            elseif ($Matches[2] -eq "<")
            {
                return $Target -lt $Version;
            }
        }

        return $False;
    }

    Write-Log "Invalid Version Validator $Validator";

    return $False;
};

##----------------------------------------------------------------------------------------------------------------------
##  Validator Logic
##----------------------------------------------------------------------------------------------------------------------

$Validators.NOT =
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    if (PD-Validate -Validator $Validator)
    {
        return $False;
    }

    return $True;
};

$Validators.AND =
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    ForEach ($SubValidator in ($Validator -split "&"))
    {
        if (!PD-Validate -Validator $SubValidator)
        {
            return $False;
        }
    }

    return $True;
};

$Validators.OR =
{
    param
    (
        [Parameter(Mandatory = $True)] $Validator
    );

    ForEach ($SubValidator in ($Validator -split "|"))
    {
        if (!PD-Validate -Validator $SubValidator)
        {
            return $True;
        }
    }

    return $False;
};