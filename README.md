## **Power Deploy**
Power Deploy is a tool for installing and uninstalling software on Windows devices. It allows you to automate software installations and uninstalls, or perform them manually through a user interface. With Power Deploy, you can quickly and easily install and uninstall software on a single device or on multiple devices at once.

Some key features of Power Deploy include:

Automated software installations and uninstalls A user-friendly    interface for manual installations and uninstalls The ability to    install and uninstall software on multiple devices at once Support for site deployments (e.g. mounting on a UNC path) Using Power Deploy can save time and effort when managing software installations and    uninstalls, and can help ensure that software is consistently deployed across your organization.

### **Using Power Deploy**
To use PowerDeploy, you simply need to run the powerdeploy.ps1 script. You can specify certain parameters when running the script to customize its behavior. For example, you can specify the -NoUI parameter to run the script without a user interface, or you can specify a different ConfigFile or PackageDir to use custom configurations or package directories. The LogFile parameter can also be specified to specify a custom log file location.

### **Configuring Power Deploy**
Power Deploy can be configured using a config.json file. The file should contain a JSON object with the following optional properties:

    {
        "Mount": {
            "Path": "\\\\BA-UNICORN\\A$\\PowerDeploy",
            "Letter": "X"
        }
    }

`Path`: The path from which Power Deploy will load. If not set, Power Deploy will use the path it was executed from.
`Letter`: If Path and Letter are set, the specified path will be mounted to the specified letter and used locally. It is recommended to use this option.

To configure Power Deploy, create a config.json file with the desired options and save it in the same directory as the Power Deploy executable. Power Deploy will read the configuration file automatically when it is run.

### **Packaging Applications with Power Deploy**
Power Deploy uses a simple folder structure to package applications for installation. In the root of the Power Deploy directory, you will find an Applications folder. To create a package, create a new folder inside the Applications folder and add a package.json file and your installation files.

The package.json file should contain a JSON object with the following properties:

    {
        "Template": "template-name", // Optional. The name of a template to build the package from.
        "Name": "Example Package", // Required. The name of the package.
        "Version": "1.0", // Optional. The version of the package.
        "Filter": {...}, // Optional. A set of filters to determine which machines are targeted.
        "Install": [...], // Optional. A set of commands to run during installation.
        "Uninstall": [...], // Optional. A set of commands to run during uninstallation.
        "AllowInstall": true, // Optional. Allows users to install the package from the user interface.
        "AllowUninstall": true, // Optional. Allows users to uninstall the package from the user interface.
        "Validator": [...] // Optional. A set of instructions to check if a program is installed correctly.
    }

`Template`: The name of a template to build the package from. This is an optional field.
`Name`: The name of the package. This is a required field.
`Version`: The version of the package. This is an optional field.
`Filter`: A set of filters to determine which machines are targeted. This is an optional field.
`Install`: A set of commands to run during installation. This is an optional field.
`Uninstall`: A set of commands to run during uninstallation. This is an optional field.
`AllowInstall`: Allows users to install the package from the user interface. This is an optional field.
`AllowUninstall`: Allows users to uninstall the package from the user interface. This is an optional field.
`Validator`: A set of instructions to check if a program is installed correctly. This is an optional field.

Once you have created a package folder with a `package.json` file and your installation files, you can use Power Deploy to install or uninstall the package.

#### **Install & Uninstall Commands**
To write install and uninstall commands for Power Deploy, you can use a variety of command types  The available command types are:

`CMD`: Executes a command using the cmd.exe command-line interpreter.
`BAT`: Executes a batch file using the cmd.exe command-line interpreter.
`PowerShell`: Executes a PowerShell command or script.
`Script`: Executes a PowerShell script file.
To use a command type, prefix the command with the type followed by a colon. For example, to execute a CMD command, you would use `CMD`:command-text, and to execute a PowerShell command, you would use PowerShell:command-text.

Here is an example of how you might use these command types in a package.json file:

    {
        "Name": "Example Package",
        "Install": [
            "PowerShell:Install-ExamplePackage"
        ],
        "Uninstall": [
            "CMD:installer.exe"
        ]
    }

In this example `package.json` file, the Install commands will execute a PowerShell command to install the package. The Uninstall commands will execute a CMD command to run the installer.exe file, which will presumably be an uninstaller for the package.

Note that the CMD command in the Uninstall section is just running the installer.exe file, so it is not necessary to specify the full path to the file. However, if the installer.exe file is not located in the same directory as the package.json file, you will need to specify the full path to the file.

#### **Installation Valiators**
In Power Deploy, validators are used to check if an installed package is installed correctly and can be used in the Validator field of a package.json file.

The available validator types are:

File: Checks if a specified file exists on the system.
GUID: Checks if a package with a specified GUID is installed on the system.
PowerShell: Executes a PowerShell command or script and returns the result.
Package: Checks if a package with a specified name is installed on the system.
Version: Compares the version of a specified file or package with a target version.

To use a validator type, prefix the validator with the type followed by a colon. For example, to use the File validator, you would use File:path\to\file, and to use the Package validator, you would use Package:package-name.

Here is an example of how you might use validators in a package.json file:

    {
        "Name": "Example Package",
        "Validator": [
            "File:C:\Program Files\Example Package\example.exe",
            "Package:Example Package"
        ]
    }

In this example, the Validator field specifies two validators to run: a File validator that checks if the example.exe file exists, and a Package validator

#### **Filters**
In Power Deploy, filters are used to determine which machines a package should be installed on or uninstalled from and can be used in the Filter field of a package.json file.

The available filter types are:

`Name`: Filters machines based on their name using a regex pattern.
`WMIC`: Filters machines using a WMIC query.
PowerShell: Filters machines using a PowerShell command or script.
`Group`: Filters machines based on their membership in an Active Directory group.
`OU`: Filters machines based on their membership in an Active Directory organizational unit (OU).

To use a filter type, prefix the filter with the type followed by a colon. For example, to use the Name filter, you would use Name:pattern, and to use the Group filter, you would use Group:group-name.

Here is an example of how you might use filters in a package.json file:

    {
        "Name": "Example Package",
        "Filter": [
            "Name:Laptop-([0-9]+)",
            "Group:Example Group"
        ]
    }

In this example, the Filter field specifies two filters to run: a Name filter that matches machine names starting with`Laptop-` followed by a number, and a Group filter that matches machines that are members of the `Example Group` Active Directory group.
