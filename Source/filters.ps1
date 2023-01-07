##----------------------------------------------------------------------------------------------------------------------
##  Filters
##----------------------------------------------------------------------------------------------------------------------

$Filters = @{ };

##----------------------------------------------------------------------------------------------------------------------
##  Filter Function
##----------------------------------------------------------------------------------------------------------------------

function PD-Filter
{
    param
    (
        [Parameter(Mandatory = $True)] $Filter
    );

    if ($Filter -is [array])
    {
        ForEach ($SubFilter in $Filter)
        {
            if (PD-Filter -Filter $SubFilter)
            {
                return $True;
            }
        }

        return $False;
    }
    elseif ($Filter -is [string])
    {
        if ($Filter -match "^([a-zA-Z]+):(.+)$")
        {
            if ($Filters.$($Matches[1]))
            {
                return $Filters.$($Matches[1]).Invoke($Matches[2]);
            }
        }
        elseif ($Filter -eq "*")
        {
            return $True;
        }
    }

    Write-Host "Invalid Filter $Filter";

    return $False;
};

##----------------------------------------------------------------------------------------------------------------------
##  Filter by Name
##----------------------------------------------------------------------------------------------------------------------

$Filters.Name =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Pattern
    );

    return ($Data.HostName -match $Pattern);
};

##----------------------------------------------------------------------------------------------------------------------
##  Filter by WMIC
##----------------------------------------------------------------------------------------------------------------------


$Filters.WMIC =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Query
    );

    return (Get-WmiObject -Query $Query) -ne $Null;
};

##----------------------------------------------------------------------------------------------------------------------
##  PowerShell
##----------------------------------------------------------------------------------------------------------------------

$Filters.PowerShell =
{
    param
    (
        [Parameter(Mandatory = $True)] $Command
    );

    return (Invoke-Expression -Command $Command);
};

##----------------------------------------------------------------------------------------------------------------------
##  Filter by AD Group
##----------------------------------------------------------------------------------------------------------------------

$Filters.Group =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Group
    );

    try
    {
        $Groups = ([System.DirectoryServices.DirectorySearcher]"(&(objectCategory=computer)(name=$($Data.HostName)))").FindAll().Properties["MemberOf"];
    }
    catch
    {
        Write-Host "Error with Group filter: $Group"
    }

    if (!$Groups)
    {
        return $False;
    }

    if ($Group.StartsWith("CN="))
    {
        return $Groups.Contains($Group);
    }
    else
    {
        return ($Groups | Where-Object { $_ -match "^CN=$Group," }) -ne $Null;
    }
    
};

##----------------------------------------------------------------------------------------------------------------------
##  Filter by OU
##----------------------------------------------------------------------------------------------------------------------

$Filters.OU = 
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $OU
    );

    if ($Recursive = $OU.EndsWith("*"))
    {
        $OU = $OU.Substring(0, $OU.Length - 1);
    }

    try
    {
        $DN = ([System.DirectoryServices.DirectorySearcher]"(&(objectCategory=computer)(name=$($Data.HostName)))").FindAll().Properties["distinguishedname"];
    }
    catch
    {
        Write-Host "Error with Group filter: $Group"
    }
    
    if (!$DN)
    {
        return $False;
    }

    if (!$Recursive)
    {
        return ($DN[0] -eq "CN=$($Data.HostName),$OU");
    }
    else
    {
        return ($DN[0].endsWith(",$OU"));
    }
};

##----------------------------------------------------------------------------------------------------------------------
##  Filter Logic
##----------------------------------------------------------------------------------------------------------------------

$Filters.NOT =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Filter
    );

    if (PD-Filter -Filter $Filter)
    {
        return $False;
    }

    return $True;
};

$Filters.AND =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Filter
    );

    ForEach ($SubFilter in ($Filter -split "&"))
    {
        if (!PD-Filter -Filter $SubFilter)
        {
            return $False;
        }
    }

    return $True;
};

$Filters.OR =
{
    param
    (
        [Parameter(Mandatory = $True)] [string] $Filter
    );

    ForEach ($SubFilter in ($Filter -split "|"))
    {
        if (!PD-Filter -Filter $SubFilter)
        {
            return $True;
        }
    }

    return $False;
};

