# This code will search a directory for a certain file extension, deleting files which do not meet certain criteria.
#  THIS CODE DOES NOT CHECK SUBFOLDERS
# By default, it will keep the last 7 days, the last 4 Sundays, and every End of Month.
# There are some variables which may need updating, which are declared below.
# The code will also not remove any files unless you override the $whatif variable.

$Saturday = "0"
$Sunday = "0"
# The variables $Saturday and $Sunday are to check whether your backups run on the weekends.
# If they DO NOT run on Saturday or Sunday, set both variables to "0".
# If they DO run on Saturday and Sunday, set both variables to "1".
# If they run on Saturday, but NOT Sunday, set $Saturday to "1" and $Sunday to "0"
# The code will handle the rest

$whatif = "1"
# By default this is "1".  This will allow you to run the script manually and check what will be deleted.
# It is highly recommended to run this script once with whatif enabled to see what will be deleted.
# If you are happy with the results, run the code with $whatif set to "0" to delete the files.
# Then change $whatif back to "1" and run the code again to ensure it will not delete files you want again.
# Then change it to "0" again and set up the scheduled task (if you are running it that way).


#Specify the file extension
$FileType = "fbk"
#Specify the folder you are checking
$Folder = "C:\Full\Path\To\Backups"
#Get a list of the files
$Files = (Get-ChildItem $Folder\*.$FileType | Select Name, CreationTime)
#Get todays Date
$Date = (Get-Date).Date
#Initialise array to hold files to be deleted
$Delete = @()
#Initialise arry to hold files to be kept
$Keep = @()


#Make last day of week Friday/Saturday/Sunday depending on $Saturday and $Sunday
$lastdayofweek = "Sunday"
if ($Sunday -eq "0") {
    if ($Saturday -eq "0") {
        $lastdayofweek = "Friday"
        }
    else {
        $lastdayofweek = "Saturday"
        }
    }

#Start iteration through the files
Foreach ($Name in $Files) {
    #Get the position in the array
    $Where = [array]::IndexOf($Files.Name, $Name.Name)
    $fom = Get-Date ($Files.CreationTime[$Where]) -Day 1 -Hour 0 -Minute 0 -Second 0
    $eom = (($fom).AddMonths(1).AddSeconds(-1))

    if ($eom.DayOfWeek -eq "Sunday") {
        if ($lastdayofweek -eq "Saturday") {
            $eom = (($eom).AddDays(-1))
        }
        elseif ($lastdayofweek -eq "Friday") {
            $eom = (($eom).AddDays(-2))
        }
    }
    elseif ($eom.DayOfWeek -eq "Saturday") {
        if ($lastdayofweek -eq "Friday") {
            $eom = (($eom).AddDays(-1))
        }
    }

	if ($Files.CreationTime[$Where] -ge $Date.AddDays(-7)) {
     	   $Keep += $Files[$Where].Name
    	}
    elseif ($Files.CreationTime.DayOfWeek[$Where] -eq $lastdayofweek -and $Files.CreationTime[$Where] -ge $Date.AddDays(-29)) {
            $Keep += $Files[$Where].Name

        }
    elseif ($Files.CreationTime.Day[$Where] -eq $eom.Day) {
            $Keep += $Files[$Where].Name
            
        }
    else {
    		$Delete += $Files[$Where].Name
    	}
    }

#Check Whatif condition
if ($whatif -eq "0") {
    Foreach ($Name in $Delete) {
        Remove-Item $Folder\$Name
        }
    }
else {
    #Otherwise report the files (includes 'any key to close')
    Write-Host "======================"
    Write-Host "Files to be retained"
    Write-Host "======================"
    $Keep
    Write-Host "======================"

    Write-Host "Files to be deleted"
    Write-Host "======================"
    $Delete
    Write-Host "======================"
    write-host ""
    write-host "End of Script.  Press any key to close..."
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
