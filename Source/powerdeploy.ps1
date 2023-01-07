##----------------------------------------------------------------------------------------------------------------------
##  Named Paramaters
##----------------------------------------------------------------------------------------------------------------------

param
(
    [bool] $NoUI = $False,
    [string] $ConfigFile = "%scriptroot%\config.json",
    [string] $PackageDir = "%scriptroot%\Applications",
    [string] $LogFile = "C:\Windows\Logs\power-deploy.log"
);

##----------------------------------------------------------------------------------------------------------------------
##  Splash Screen
##----------------------------------------------------------------------------------------------------------------------

Write-Host "------------------------------------------------------------------------"
Write-Host " ____  _____  _    _  ____  ____    ____  ____  ____  __    _____  _  _ "
Write-Host "(  _ \(  _  )( \/\/ )( ___)(  _ \  (  _ \( ___)(  _ \(  )  (  _  )( \/ )"
Write-Host " )___/ )(_)(  )    (  )__)  )   /   )(_) ))__)  )___/ )(__  )(_)(  \  / "
Write-Host "(__)  (_____)(__/\__)(____)(_)\_)  (____/(____)(__)  (____)(_____) (__) "
Write-Host "------------------------------------------------------------------------"
Write-Host "By Marcus Goluch 2023"
Write-Host "------------------------------------------------------------------------"

##----------------------------------------------------------------------------------------------------------------------
##  Step 1: Create custom log function
##----------------------------------------------------------------------------------------------------------------------

function Write-Log
{
    param
    (
        $Output
    );

    [System.Console]::WriteLine($Output);

    Add-Content -Path $LogFile -Value $Output -ErrorAction SilentlyContinue;
    
    return $Output;
};

##----------------------------------------------------------------------------------------------------------------------
##  Step 2: Build Configeration
##----------------------------------------------------------------------------------------------------------------------

$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Path;

$env:scriptroot = $ScriptDir;

$Config = (Get-Content -Path ([System.Environment]::ExpandEnvironmentVariables($ConfigFile)) | ConvertFrom-Json);

$LogFile = if ($Config.LogFile) {$Config.LogFile} else {$LogFile};

$LogFile = [System.Environment]::ExpandEnvironmentVariables($LogFile);

##----------------------------------------------------------------------------------------------------------------------
##  Step 3: Mount Libraries
##----------------------------------------------------------------------------------------------------------------------

try 
{
    Write-Log "Loading Function Libraries.";
    
    . "$ScriptDir\util.ps1";
    . "$ScriptDir\validators.ps1";
    . "$ScriptDir\filters.ps1";
    . "$ScriptDir\commands.ps1";
    . "$ScriptDir\templates.ps1";
    . "$ScriptDir\packages.ps1";
}
catch
{
    Write-Log "Failed to load Function Libraries.";
    Write-Log $Error;
    Exit;
}

##----------------------------------------------------------------------------------------------------------------------
##  Step 4: Mount UNC Path to local machine
##----------------------------------------------------------------------------------------------------------------------

$Mount = $ScriptDir;

if ($Config.Mount)
{
    $Mount = $MountPath = [System.Environment]::ExpandEnvironmentVariables($Config.Mount.Path);

    if ($Config.Mount.Letter)
    {
        $Mount = "$($Config.Mount.Letter):"

        if (!(Test-Path $Mount))
        {
            try 
            {
                Write-Log "Mounting Power Deploy as Network Drive ($Mount)";
                New-PSDrive -Name $Config.Mount.Letter -PSProvider FileSystem -Root $MountPath -Description "PowerDeploy" -Persist
            }
            catch
            {
                Write-Log "Failed to mount Network Drive....";
            }
        }
    }
}

$env:Mount = $Mount;

##----------------------------------------------------------------------------------------------------------------------
##  Step 5: Generate Package List
##----------------------------------------------------------------------------------------------------------------------

$PackageDir = if ($Config.PackageDir) {$Config.PackageDir} else {$PackageDir};

$PackageDir = [System.Environment]::ExpandEnvironmentVariables($PackageDir);

PD-GeneratePackages -Directory $PackageDir;

##----------------------------------------------------------------------------------------------------------------------
##  Step 6: Setup Wizzard
##----------------------------------------------------------------------------------------------------------------------

if (!$NoUI -and !$Config.NoUI)
{
    . "$ScriptDir\wizzard.ps1";
}

##----------------------------------------------------------------------------------------------------------------------
##  Step 7: Generate installation queue
##----------------------------------------------------------------------------------------------------------------------

[void] (PD-QueuePackages -Packages $script:ApplicationPackages.Values);

##----------------------------------------------------------------------------------------------------------------------
##  Step 8: Install Packages
##----------------------------------------------------------------------------------------------------------------------

ForEach ($PackageName in $script:PackageSequence)
{
    $Package = $script:ApplicationPackages.$PackageName;
    
    $Result = $Null;

    $env:packageroot = $Package.Directory;
    
    if ($Package.Install)
    {
        Write-Log "Installing Package $PackageName";
        
        $Result = (PD-Command -Command $Package.Package.Install -Package $Package);
    }
    elseif ($Package.Uninstall)
    {
        Write-Log "Uninstalling Package $PackageName";
        
        $Result = (PD-Command -Command $Package.Package.Uninstall -Package $Package);
    }

    if ($Package.Package.Validator)
    {
        $Package.Installed = (PD-Validate -Validator $Package.Package.Validator);
    }

    if ( !$Result -or ( ($Package.Install -and !$Package.Installed) -or ($Package.Uninstall -and $Package.Installed) ) )
    {
        Write-Log "Failed on $PackageName";
    }
}