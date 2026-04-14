# source: camille debay
# script to output trigger & action information for ALL scheduled tasks
# set up to provide more information on triggers & handlers
# unsure whether to add output option to CSV or just let it return array with data & print to screen.

# TODO: regular triggers (:
# DONE: regular actions (: 
# TODO: taskname with multiple taskpaths
function Get-CorrectWNFstateNames {
    param(
        [Object[]]$StateNames
    )
    $ressy = @()
    try {
        for($i=0;$i -le $StateNames.Count;$i++){
            $res = ''
            for($j=$StateNames[$i].Length-2;$j -ge 0;$j -= 2){
                $res+=$StateNames[$i].substring($j,2)
            }
            $ressy += $res
    
        }
        return $ressy
    } catch {
        Write-Output "NO STATENAMES"
    }
}


function Get-WNFstateNameExplanation {
    param(
        [String]$correctStateName,
        [Object[]]$csv
    )
    try {
        for($i=0;$i -le $csv.Count;$i++){
            if ($csv[$i].wnfstate -eq $correctStateName) {
                Write-Output $csv[$i].wnfstate $csv[$i].wnfstate_str $csv[$i].descr
                write-output ''
            }
        }
    } catch {
        Write-Output "NO MATCHING EXPLANATIONS"
    }

}

function Get-EventLogTrigger {
    param([String]$eventLogQuery)
    try {
        # regex to get text relevant to the query
        $regex = "&lt;Select(.*?)Select&gt;"
        $res = [regex]::Match($eventLogTrigger,$regex)
        # html cleanup
        $res = $res.Value.replace("&lt;","<").replace("&gt;",">")
        Write-Output $res
    } catch {
        Write-Output "NO SUCH TRIGGER"
    }

}

function Get-MyHash {
    param([String]$fileAndPath)
    try {
        $filehash = Get-FileHash -Path $fileAndPath -Algorithm SHA256
        return $filehash.Hash
    } catch {
        write-host "NOT SUITABLE FOR HASHING"
    
    }
}

function Get-ActionCOMData {
    param(
        [String]$CLSID
    )
    try {
        # this format is required because in the next line you call .net api
        $regkey = "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\$CLSID\InProcServer32"
        $tmptest = get-item -Path "HKLM:\SOFTWARE\Classes\CLSID\$CLSID\InProcServer32" -ErrorAction SilentlyContinue

        if ($tmptest -eq $null) {
            $regkey = get-item -path "HKLM:\SOFTWARE\Classes\CLSID\$CLSID\"
            $regval = [Microsoft.Win32.Registry]::GetValue($regkey,'AppID',$null)
            $app = Get-WmiObject win32_DCOMApplicationSetting | Where {$_.AppId -eq $regval}
            $svc = Get-WmiObject -Class win32_service | where { $_.Name -eq $App.LocalService }
            Write-Output $app.LocalService $app.Description $svc.Description
        } else {
            # getval needs 3 args, last 2 are just null
            $regvalue = [Microsoft.Win32.Registry]::GetValue($regkey,'',$null)
            $filehash = Get-MyHash -fileAndPath $regvalue
            Write-Output $regvalue $filehash
        }
    } catch {
        Write-Output "NO DICE"
    }
}



function get-scheduledTasks {
    $bloobloo = schtasks /query /FO:LIST
    $bloooooooo = @()
    foreach ($bloo in $bloobloo) {
        if($bloo.startsWith("TaskName")){
            $bloob = $bloo.split('\')[-1]
            if($bloob -notin $bloooooooo) {
                $bloooooooo += $bloob
            }
        }
    }
    $blobby = $bloooooooo | Sort-Object -Unique
    return $blobby

}

function Get-ActionCommand {
    param([String]$command)
    try {
        $parts = $command.Split('\')
        $executable = $parts[-1]
        if ($executable -eq 'sc.exe') {
            Write-Output $command
            Get-ActionArgument -scTask $True -argument $Global:ActionArg
            
        } else {
            $command = [environment]::ExpandEnvironmentVariables($command)
            $hash = Get-MyHash -fileAndPath $command
            Write-Output $command
            Write-Output $hash
        }
    } catch {
        "NO ACTION IN THIS FORMAT"
    }
}

function Get-ActionArgument {
    param(
        [String]$argument,
        [Boolean]$scTask
    )
    try {
        if  ($scTask) {
            #TODO: :)
            $svc = $argument.Split(' ')[1]
            $svc_descr = (Get-WmiObject -Class win32_service | where {$_.Name -eq $svc}).Description
            Write-Output $svc_descr
        } else {
            Write-Output $argument
       }
    } catch {
        Write-Output "NO ARG IN THIS FORMAT"
    }
}

# helper function until detailed handling
function Write-Data {
    param(
        [Object[]]$Data
    )
    for($i=0;$i -le $data.Count;$i++){
        write-output $data[$i]
    }

}

function Get-TitleCard {
    param([String]$scheduledTaskName)
    $len = $scheduledTaskName.Length
    $len = $len + 24 + 10
    if ($Global:Task_counter -ge 10) {
        $len+=1
    } 
    if ($Global:Task_counter -ge 100)  {
        $len += 1
    }
    $title = "#    $task_counter. Trigger / Action FOR $scheduledTaskName    #"
    $titleCard = "$("#" * $len)`n#$(' ' * ($len-2))#`n$title`n#$(' ' * ($len-2))#`n$("#"*$len)"
    return $titleCard
}


$allSchedTasks = get-scheduledTasks
$wnf_csv = import-csv -Path E:\Archive\School\mySchool\WnfNames-main\wnf.txt -Delimiter ' ' -header @('wnfstate','id','wnfstate_str','descr')
$namespace = @{ task="http://schemas.microsoft.com/windows/2004/02/mit/task" }

$Global:Task_counter = 1
foreach ($task in $allSchedTasks){
    $schedtask = Get-ScheduledTask -TaskName $task
    [xml]$xmlcontent = Export-ScheduledTask -TaskName $schedtask.TaskName -TaskPath $schedtask.TaskPath
    $wnfstates = Select-Xml -Xml $xmlcontent -XPath "//task:StateName" -Namespace $namespace | foreach { $_.Node.InnerXml }
    $eventLogTrigger = Select-Xml -Xml $xmlcontent -XPath "//task:Subscription" -Namespace $namespace | foreach { $_.Node.InnerXml }
    $ActionCOM = select-xml -xml $xmlcontent -XPath "//task:ClassId" -Namespace $namespace | foreach { $_.Node.InnerXml }
    $ActionCmd = select-xml -xml $xmlcontent -XPath "//task:Command" -Namespace $namespace | foreach { $_.Node.InnerXml }
    $Global:ActionArg = select-xml -xml $xmlcontent -XPath "//task:Arguments" -Namespace $namespace | foreach { $_.Node.InnerXml }

    $titleCard = Get-TitleCard -scheduledTaskName $task
    Write-Output $titleCard
    Write-Output ''   
    Write-Output "WNF Triggers for: $task (Trigger + Description)"
    Write-Output ''
    $correct_wnfstates = Get-CorrectWNFstateNames -StateNames $wnfstates
    $correct_wnfstates | ForEach-Object {Get-WNFstateNameExplanation -correctStateName $_ -csv $wnf_csv}
    Write-Output ''
    Write-Output "EventLog Triggers for: $task (EventLog Query)"
    Write-Output ''
    $eventLogTrigger | ForEach-Object { Get-EventLogTrigger -eventLogQuery $_ }
    Write-Output ''
    Write-Output "Actions for: $task (Command + Arguments + Hash)"
    Write-Output ''    
    $ActionCmd | ForEach-Object { Get-ActionCommand -command $_ }
    $ActionArg | ForEach-Object { Get-ActionArgument -argument $_ -scTask $false }
    Write-Output ''
    Write-Output "Actions for: $task (CLSID based: Command + Hash)"
    Write-Output ''
    $ActionCOM | ForEach-Object { Get-ActionCOMData -CLSID $_ }
    Write-Output "------------------------------------------------------------------------------------------------------"
    $Global:Task_counter++
}

# time triggers

# wnftriggers

# eventlog triggers

# normal actions

# normal actions with sc

# CLSID actions