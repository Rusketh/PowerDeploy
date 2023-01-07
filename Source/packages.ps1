##----------------------------------------------------------------------------------------------------------------------
##  Load a package
##----------------------------------------------------------------------------------------------------------------------

function PD-LoadPackage
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Directory,
        [string] $PackageJson = "$Directory\package.json"
    );

    $PackageJson = [System.Environment]::ExpandEnvironmentVariables($PackageJson);

    if (Test-Path $PackageJson)
    {
        $Package = $Null;

        try
        {
            $Package = (Get-Content -Path $PackageJson | ConvertFrom-Json);
        }
        catch
        {
            Write-Log "Invalid package file $PackageJson";
            Write-Log $Error;
            return;
        }

        $Package = (PD-Template -Template $Package -Directory $Directory -File $PackageJson);
        $PackageName = "$($Package.Name) $($Package.Version)";
            
        $script:ApplicationPackages.$PackageName =
        @{
            "Directory" = "$Directory";
            "Json" = $PackageJson;
            "Name" = $PackageName;
            "Package" = $Package;
            "Targeted" = $True;
            "Installed" = $False;
            "Uninstall" = $False;
            "Install" = $False;
            "ID" = $script:AppID;
        };

        Write-Log "Loaded Package: $PackageName ($script:AppID)";
            
        $script:AppID++;

        if ($Package.Includes)
        {
            ForEach ($Include in $Package.Includes)
            {
                if ($Include.endsWith("*"))
                {
                    PD-LoadPackages -Directory "$Directory\$($Include.Substring(0, $Include.Length - 1))";
                }
                else
                {
                    PD-LoadPackage -Directory "$Directory\$Include";
                }
            }
        }

        return $script:ApplicationPackages.$PackageName;
    }
};

##----------------------------------------------------------------------------------------------------------------------
##    Load all packages from directory
##----------------------------------------------------------------------------------------------------------------------

function PD-LoadPackages
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Directory
    );

    $Loaded = @();

    Write-Log "Loading packages from: $Directory";

    ForEach ($AppDir in (Get-ChildItem $Directory))
    {
        if (Test-Path "$Directory\$AppDir\package.json")
        {
            $Loaded += (PD-LoadPackage -Directory "$Directory\$AppDir");
        }
    }

    ForEach ($File in (Get-ChildItem $Directory -Filter "*.package"))
    {
        $Loaded += (PD-LoadPackage -Directory $Directory -PackageJson "$Directory\$File");
    }

    return $Loaded;
};

##----------------------------------------------------------------------------------------------------------------------
##  Determine if packages should be installed or removed.
##----------------------------------------------------------------------------------------------------------------------

function PD-GeneratePackages
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Directory
    );

    $script:AppID = 0;
    $script:ApplicationPackages = @{};

    ForEach ($Dir in ([array] $Directory))
    {
        [void] (PD-LoadPackages -Directory $Dir);
    }

    ForEach($Package in $script:ApplicationPackages.Values)
    {
        if ($Package.Package.Filter)
        {
            $Package.Targeted = (PD-Filter -Filter $Package.Package.Filter);
        }

        if ($Package.Package.Validator)
        {
            $Package.Installed = (PD-Validate -Validator $Package.Package.Validator);
        }

        if ($Package.Targeted -and !$Package.Installed)
        {
            $Package.Install = $True;
        }
        elseif ($Package.Installed -and !$Package.Targeted)
        {
            $Package.Uninstall = $True;
        }
    }
};

##----------------------------------------------------------------------------------------------------------------------
##  Add to installation queue
##----------------------------------------------------------------------------------------------------------------------

$script:PackageSequence = @();

function PD-QueuePackage
{
    param
    (
        [Hashtable] $Package,
        [bool] $Depenant = $False
    );

    if ($script:PackageSequence.Contains($Package.Name))
    {
        Write-Log "Skipping $($Package.Name) allready queued.";
        return $True;
    }

    if ($Package.Installed -and $Package.Install)
    {
        Write-Log "Skipping $($Package.Name) allready installed.";
        return $True;
    }

    if (!$Package.Installed -and $Package.Uninstall)
    {
        Write-Log "Skipping $($Package.Name) allready uninstalled.";
        return $True;
    }

    if (!($Package.Uninstall -or $Package.Install))
    {
        Write-Log "Skipping $($Package.Name) not action pending.";
        return $True;
    }

    if (!$Package.Targeted -and !$Depenant)
    {
        Write-Log "Skipping $($Package.Name) not targeted.";
        return $False;
    }

    if ($Package.Install)
    {
        if ($Package.Package.Dependencies)
        {
            $Dependencies = ($script:ApplicationPackages | Where-Object { $Package.Package.Dependencies.Contains($_.Name); });
        
            if (!(PD-QueuePackages -Package $Dependencies -Dependant $True))
            {
                return $False;
            }
        }
    }

    Write-Log "Adding $($Package.Name) to package sequence";

    $script:PackageSequence += $Package.Name;

    return $True;
};

##----------------------------------------------------------------------------------------------------------------------
##  Add to set installation queue
##----------------------------------------------------------------------------------------------------------------------

function PD-QueuePackages
{
    param
    (
        [array] $Packages
    );

    ForEach($Package in ($Packages | Sort-Object {$_.Package.Priority} ))
    {
        if (!(PD-QueuePackage -Package $Package))
        {
            return $False;
        }
    }

    return $True;
};