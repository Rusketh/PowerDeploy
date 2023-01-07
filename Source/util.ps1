##----------------------------------------------------------------------------------------------------------------------
##  Merge 2 Objects
##----------------------------------------------------------------------------------------------------------------------

function Merge-Object
{
    param
    (
        [Parameter(Mandatory=$true)] [System.Object] $Source,
        [Parameter(Mandatory=$true)] [System.Object] $Destination = @{},
        [bool] $Recurse = $False,
        [bool] $Assign = $False,
        [int] $Deph = 1
    );

    ForEach($Key in ($Source | Get-Member -MemberType Property))
    {
        $Value = $Source.$Key;
        $Current = $Destination.$Key;

        if ( $Assign -or ($Current -eq $Null) -or ( ($Value -is [System.Object]) -and ($Current -is [System.Object]) ) )
        {
            if ( $Assign -and ($Value -is [System.Object]) )
            {
                $Current = @{ };
            }

            if ($Recurse -and ($Deph -gt 0) -and ($Value -is [System.Object]))
            {
                $Current = (Merge-Object -Source $Value -Destination $Current -Recurse $Recurse -Deph $Deph--);
            }

            $Destination | Add-Member -MemberType NoteProperty -Name $Key -Value $Current;
        }
    }

    return $Destination;
};
