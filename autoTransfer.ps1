set-executionpolicy unrestricted 
$source ="C:\ProgramData\Gyros\Gyrolab\Results\Administrator"
$destination = "\\qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Gyros\Run Data"

Function Register-Watcher {
    param ($folder)
    $filter = "*custom3*.xls" #files that have copy in the title
    $watcher = New-Object IO.FileSystemWatcher $folder, $filter -Property @{ 
        IncludeSubdirectories = $true
        EnableRaisingEvents = $true
    }

    $changeAction = [scriptblock]::Create('
        #This is the code which will be executed every time a file change is detected
        
        #re-initialize the dates every time the script block is run
        $date = [DateTime]::Today.AddDays(-1).AddHours(22)
        $year = Get-Date -format yyyy
        $month = Get-Date -format MM-MMMM
        $specificDay = Get-Date -format MMddyy
        
        #specify paths and names of files generated
        $path = $Event.SourceEventArgs.FullPath
        $name = $Event.SourceEventArgs.Name
        $changeType = $Event.SourceEventArgs.ChangeType
        $timeStamp = $Event.TimeGenerated
        Write-Host "The file $name was $changeType at $timeStamp"
        Write-Host $path
        
        #write 
        New-Item -ItemType directory -Path "\\qdcns0002\ath_data$\ATHDept\Laboratory\Immunology\Gyros\Run Data\$year\$month\$specificDay"
        
        #search excel file for analyte names
        $xl = New-Object -COM "Excel.Application"
        $xl.Visible = $false
        $xl.displayAlerts = $false
        $wb = $xl.Workbooks.Open("$path")
        $ws = $wb.Sheets.Item(1)
        $colLength = $ws.UsedRange.Rows.Count
        Write-Host "Assigning variables"
        $analyte = @($ws.Range("I2").Text)
        Write-Host "Assigning more variables"
        Write-Host "Saving Excel file"
        $val = ""  
        for ($i = 3; $i -lt $colLength; $i++) {
            
            if ($analyte -notcontains $ws.Range("I$i").text) {
                $analyte += $ws.Range("I$i").text
            }
        }
        
        for ($str = 0; $str -lt $analyte.length; $str++){
            $val += $analyte[$str]+" "
           }
        $val += "raw data " + "Gustav(3475)"
        Write-Host "saved as: " $val
        $wb.SaveAs("$destination\$year\$month\$specificDay\$val.XLS")
        $wb.Close()
        $xl.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl)
        Remove-Variable xl
    ')

    Register-ObjectEvent $Watcher "Created" -Action $changeAction
    while($TRUE){
	$result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed -bor [System.IO.WatcherChangeTypes]::Created, 1000);
	if($result.TimedOut){
		continue;
	}
  }
}

 Register-Watcher "C:\ProgramData\Gyros\Gyrolab\Results\Administrator"