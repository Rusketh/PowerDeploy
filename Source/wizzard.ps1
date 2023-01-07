##----------------------------------------------------------------------------------------------------------------------
##  Step 1: Generate UI
##----------------------------------------------------------------------------------------------------------------------

$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window"
    Title="Power Deploy Wizzard - Software"
    WindowStartupLocation="CenterScreen"
    SizeToContent="WidthAndHeight"
    ShowInTaskbar="True"
    Background="lightgray"
    Topmost="True"
    MinWidth="400"
    Padding="20"> 

    <StackPanel>
        <TextBlock Text="Select the programs that you want to install:" FontSize="16" FontWeight="Bold" />
        <TextBlock Text="Deselect an installed peice of software to uninstall it." FontSize="14" />
        <TextBlock Text="Select an uninstalled peice of software to install it." FontSize="14" />
        <TextBlock Text="Greyed out options can not be installed/uninstalled." FontSize="14" />
        <Separator />
        <ScrollViewer VerticalScrollBarVisibility="Visible" MinHeight="300">
            <StackPanel>
"@;

$SkipUI = $True;

ForEach($Package in $script:ApplicationPackages.Values)
{
    if ($Package.Package.AllowInstall -or $Package.Package.AllowUninstall)
    {
        $XAML += "`n`t`t`t<CheckBox x:Name=`"Package$($Package.ID)`" Content=`"$($Package.Name) ($(if ($Package.Installed ) {"Installed"} else {"Not Installed"}))`" ";
        
        if ( !(($Package.Package.AllowInstall -and !$Package.Installed -and $Package.Package.Install) -or ($Package.Package.AllowUninstall -and $Package.Installed -and $Package.Package.Uninstall)) )
        {
            $XAML += "IsEnabled=`"False`" ";
        }

        if ($Package.Installed -or $Package.Targeted)
        {
            $XAML += "IsChecked=`"True`" ";
        }

        $XAML += "/>`n";

        $SkipUI = $False;
    }
}

$XAML += @"
            </StackPanel>
        </ScrollViewer>

        <Separator />

        <DockPanel Width="Auto">
            <Button x:Name="Abort" Content="Exit" DockPanel.Dock="Left" Height="40" Width="120" />
            <Button x:Name="Continue" Content="Continue" DockPanel.Dock="Left" Height="40" Width="120" />
        </DockPanel>

    </StackPanel>
</Window>
"@

##----------------------------------------------------------------------------------------------------------------------
##  Step 2: Show UI
##----------------------------------------------------------------------------------------------------------------------

if (!$SkipUI)
{
    $Reader = (New-Object System.Xml.XmlNodeReader ([xml] $XAML));

    $Window = [Windows.Markup.XamlReader]::Load($Reader);

    $Window.FindName("Continue").Add_Click(
        {
            $Window.DialogResult = [System.Windows.Forms.DialogResult]::OK;
        }
    );
    
    $Window.FindName("Abort").Add_Click(
        {
            $Window.DialogResult = [System.Windows.Forms.DialogResult]::Abort;

            $Window.Close();
            
            Write-Log "Aborted";

            [Environment]::Exit(1);
        }
    );

    [void] $Window.Showdialog();

##----------------------------------------------------------------------------------------------------------------------
##  Step 3: Update Software
##----------------------------------------------------------------------------------------------------------------------
    
    ForEach($Package in $script:ApplicationPackages.Values)
    {
        $Checked = $Window.FindName("Package$($Package.ID)").IsChecked;
        
        if ($Package.Installed -and !$Checked)
        {
            $Package.Uninstall = $True;
            $Package.Install = $False;
        }
        elseif ($Checked -and !$Package.Installed)
        {
            $Package.Uninstall = $False;
            $Package.Install = $True;
        }
        else
        {
            $Package.Uninstall = $False;
            $Package.Install = $False;
        }
    }
     
##----------------------------------------------------------------------------------------------------------------------
##  Step 4: Close UI
##----------------------------------------------------------------------------------------------------------------------

    $Window.Close();
}