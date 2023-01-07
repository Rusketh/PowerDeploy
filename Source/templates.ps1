##----------------------------------------------------------------------------------------------------------------------
##  commands
##----------------------------------------------------------------------------------------------------------------------

$Templates = @{ };

##----------------------------------------------------------------------------------------------------------------------
##  Template Function
##----------------------------------------------------------------------------------------------------------------------

function PD-Template
{
    param
    (
        [System.Object] $Template,
        [System.Object] $Directory,
        [string] $File
    );

    if (!$Template.Template)
    {
        return $Template
    }

    if ($Templates.$($Template.Template))
    {
        Add-Member -InputObject $Template -MemberType NoteProperty -Name "Directory" -Value $Directory;

        return $Templates.$($Template.Template).Invoke($Template, $File);
    }

    Write-Host "Invalid Template $($Template.Template) for $File";

 };

##----------------------------------------------------------------------------------------------------------------------
##  MSI
##----------------------------------------------------------------------------------------------------------------------

$Templates.MSI = 
{
    param
    (
        [System.Object] $Template,
        [string] $File
    );

    $Package = @{ };

    Merge-Object -Source $Template -Destination $Package;

    if ($Package.MSI)
    {
        $Package.MSI = [System.Environment]::ExpandEnvironmentVariables($Package.MSI.Replace("%scriptroot%", $ScriptDir).Replace("%mount%", $Mount).Replace("%packageroot%", $Package.Directory));
        
        if (Test-Path $Package.MSI)
        {

            if (!$Package.ProuctName)
            {
                try { $Package.ProuctName = (Get-AppLockerFileInformation -Path $Item).Publisher.ProductName; } catch { }
                
                if (!$Package.ProuctName)
                {
                    Write-Log "MSI: No product name for $File";
                }
            }

            if (!$Package.Name)
            {
                $Package.Name = $Package.ProuctName;
                
                if (!$Package.Name)
                {
                    Write-Log "MSI: No product name for $File";
                    return;
                }
            }

            if (!$Package.Version)
            {
                try { $Package.Version = ([string](Get-Command $Package.MSI).Version); } catch { }
                
                if (!$Package.Version)
                {
                    Write-Log "MSI: No version for $($Package.Name)";
                }
            }

            if (!$Package.GUID)
            {
                try { $Package.GUID = (Get-AppLockerFileInformation -Path $Item).Publisher.BinaryName; } catch { }
                
                if (!$Package.Version)
                {
                    Write-Log "MSI: No guid for $($Package.Name)";
                }
            }

            if (!$Package.Validator)
            {
                if ($Package.Version)
                {
                    $Package.Validator = "version:$($Package.ProuctName)=$($Package.Version)";
                }
                else
                {
                    $Package.Validator = "package:$($Package.ProuctName)";
                }
            }

            if (!$Package.Install)
            {
                $Package.Install = "cmd:msiexec /i `"$($Package.MSI)`"";
                
                if($Package.Transforms)
                {
                    $Transforms = (([array]$Package.Transforms) -join ";").Replace("%scriptroot%", $ScriptDir).Replace("%mount%", $Mount).Replace("%packageroot%", $Package.Directory);
                    
                    $Package.Install += " /T `"$($Package.Transforms)`"";
                }

                if($Package.Patches)
                {
                    $Patches = (([array]$Package.Patches) -join ";").Replace("%scriptroot%", $ScriptDir).Replace("%mount%", $Mount).Replace("%packageroot%", $Package.Directory);
                    
                    $Package.Install += " /P `"$($Package.Patches)`"";
                }

                if($Package.LogFile)
                {
                    $LogTo = $Package.LogFile.Replace("%scriptroot%", $ScriptDir).Replace("%mount%", $Mount).Replace("%packageroot%", $Package.Directory);

                    $Package.Install += " /L `"$LogTo`"";
                }

                if($Package.Passive)
                {
                    $Package.Install += " /passive";
                }

                if($Package.Quiet -or $Package.Silent)
                {
                    $Package.Install += " /quiet";
                }

                if($Package.AllUsers)
                {
                    $Package.Install += " ALLUSERS=1";
                }

                if($Package.Arguments)
                {
                    $Package.Install += " $($Package.Arguments)";
                }
            }

            if (!$Package.Uninstall)
            {
                $Package.Uninstall = "cmd:msiexec /x `"$($Package.MSI)`"";

                if($Package.Quiet -or $Package.Silent)
                {
                    $Package.Uninstall += " /quiet";
                }
            }

            
        }

        return $Package;
    }

    Write-Log "Invalid Package Template $File";
};

##----------------------------------------------------------------------------------------------------------------------
##  WinGet
##----------------------------------------------------------------------------------------------------------------------

$Templates.WinGet = 
{
    param
    (
        [System.Object] $Template,
        [string] $File
    );

    $Package = @{ };

    Merge-Object -Source $Template -Destination $Package;

    if (!$Package.ProuctName)
    {
        $Package.ProuctName = $Package.Name;

        if (!$Package.ProuctName)
        {
            Write-Log "WINGET: No product name for $File";
        }
    }

    if (!$Package.Name)
    {
        $Package.Name = $Package.ProuctName;
                
        if (!$Package.Name)
        {
            Write-Log "WINGET: No product name for $File";
            return;
        }
    }

    if (!$Package.Install)
    {
        $Package.Install = "cmd:winget install `"$($Package.ProuctName)`"";
        
        if ($Package.Version)
        {
            $Package.Install += " --$($Package.Version)";
        }

        if ($Package.Source)
        {
            $Package.Install += " --source $($Package.Source)";
        }

        if ($Package.Location)
        {
            $Location = $Package.Location.Replace("%scriptroot%", $ScriptDir).Replace("%mount%", $Mount).Replace("%packageroot%", $Package.Directory);

            $Package.Install += " --location $($Location)";
        }

        if($Package.Quiet -or $Package.Silent)
        {
            $Package.Install += " --silent";
        }
    }

    if (!$Package.Uninstall)
    {
        $Package.Uninstall = "cmd:winget uninstall `"$($Package.ProuctName)`"";
        
        if ($Package.Version)
        {
            $Package.Uninstall += " --$($Package.Version)";
        }

        if($Package.Quiet -or $Package.Silent)
        {
            $Package.Uninstall += " --silent";
        }
    }

    return $Package;
};