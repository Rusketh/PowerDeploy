##----------------------------------------------------------------------------------------------------------------------
##  commands
##----------------------------------------------------------------------------------------------------------------------

$Commands = @{ };

##----------------------------------------------------------------------------------------------------------------------
##  Command Function
##----------------------------------------------------------------------------------------------------------------------

function PD-Command
{
    param
    (
        [Parameter(Mandatory = $True)] $Command,
        [System.Object] $Package
    );

    if ($Command -is [array])
    {
        $Result = $True;

        ForEach ($SubCommand in $Command)
        {
            if (PD-Command -Command $SubCommand -Package $Package)
            {
                return $True;
            }
        }

        return $False;
    }
    
    if ($Command -is [string])
    {
        if ($Command -match "^([a-zA-Z0-9]+):(.+)$")
        {
            if ($Commands.$($Matches[1]))
            {
                $WorkingDir = $Package.Directory;

                if ($Package.Package.Directory)
                {
                    $WorkingDir = [System.Environment]::ExpandEnvironmentVariables($Package.Package.Directory);
                }
                
                try
                {
                    return $Commands.$($Matches[1]).Invoke($WorkingDir, $Matches[2], $Package.Uninstall);
                }
                catch
                {
                    Write-Log "$($Package.Name):";
                    Write-Log "Encountered error executing command: $Command";
                    Write-Log $_.Exception.Message;
                }
            }
        }
    }

    Write-Log "Invalid Command $Command";

    return $False;
};

##----------------------------------------------------------------------------------------------------------------------
##  Command Line
##----------------------------------------------------------------------------------------------------------------------

$Commands.CMD =
{
    param
    (
        [string] $WorkingDir,
        [string] $Command,
        [bool] $Uninstall
    );

    $env:packagepath = $WorkingDir;
    $env:packageroot = $Package.Directory;

    $Command = [System.Environment]::ExpandEnvironmentVariables($Command);
    
    Write-Log "Executing: cmd.exe /c $Command";

    Start-Process "cmd.exe" -ArgumentList @("/c", $Command) -WorkingDirectory $WorkingDir -Wait;
    
    return $?;
};

##----------------------------------------------------------------------------------------------------------------------
##  Batch File
##----------------------------------------------------------------------------------------------------------------------

$Commands.BAT = $Commands.cmd;

##----------------------------------------------------------------------------------------------------------------------
##  Power Shell
##----------------------------------------------------------------------------------------------------------------------

$Commands.PowerShell =
{
    param
    (
        [string] $WorkingDir,
        [string] $Command,
        [bool] $Uninstall
    );

    $env:packagepath = $WorkingDir;
    $env:packageroot = $Package.Directory;

    #$Command = [System.Environment]::ExpandEnvironmentVariables($Command);

    Write-Log "Executing: PowerShell.exe -Command $Command";

    Start-Process "PowerShell.exe" -ArgumentList @("-Command", $Command) -WorkingDirectory $WorkingDir -Wait;
    
    return $?;
};

##----------------------------------------------------------------------------------------------------------------------
##  Power Shell Script
##----------------------------------------------------------------------------------------------------------------------

$Commands.Script =
{
    param
    (
        [string] $WorkingDir,
        [string] $Command,
        [bool] $Uninstall
    );

    $env:packagepath = $WorkingDir;
    $env:packageroot = $Package.Directory;

    $Command = [System.Environment]::ExpandEnvironmentVariables($Command);

    Write-Log "Executing: PowerShell.exe -File $Command";

    Start-Process "PowerShell.exe" -ArgumentList @("-File", $Command) -WorkingDirectory $WorkingDir -Wait;
    
    return $?;
};

##----------------------------------------------------------------------------------------------------------------------
##  Driver
##----------------------------------------------------------------------------------------------------------------------
