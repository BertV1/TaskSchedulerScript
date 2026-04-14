# source: camille debay
# script to output trigger & action information for ONE scheduled task
# set up to provide more information on custom_triggers & custom_handlers

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
            Write-Output "bloo bloo"
            $regkey = get-item -path "HKLM:\SOFTWARE\Classes\CLSID\$CLSID\"
            $regval = [Microsoft.Win32.Registry]::GetValue($tmpyregkeys,'AppID',$null)
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
        Write-Output "NO CLSID"
    }
}

function Write-Data {
    param(
        [Object[]]$Data
    )
    for($i=0;$i -le $data.Count;$i++){
        write-output $data[$i]
    }

}

function Get-ScheduledTasks {
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
            # $hash = Get-MyHash -fileAndPath $command
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
            $svc = $argument.Split(' ')[1]
            $svc = (Get-WmiObject -Class win32_service | where {$_.Name -eq $svc})
            Write-Output $svc.Description $svc.PathName
        } else {
            Write-Output $argument
       }
    } catch {
        Write-Output "NO ARG IN THIS FORMAT"
    }
}

$wnf_csv = import-csv -Path E:\Archive\School\mySchool\WnfNames-main\wnf.txt -Delimiter ' ' -header @('wnfstate','id','wnfstate_str','descr')
# this is the xml namespace of win sched tasks
$Global:namespace = @{ task="http://schemas.microsoft.com/windows/2004/02/mit/task" }

$schedtask = Get-ScheduledTask -TaskName $args
[Xml]$xmlcontent = Export-ScheduledTask -TaskName $schedtask.TaskName -TaskPath $schedtask.TaskPath
# an object[] of statenames
$wnfstates = Select-Xml -Xml $xmlcontent -XPath "//task:StateName" -Namespace $namespace | foreach { $_.Node.InnerXml }
$eventLogTrigger = Select-Xml -Xml $xmlcontent -XPath "//task:Subscription" -Namespace $namespace | foreach { $_.Node.InnerXml }
$ActionCOM = select-xml -xml $xmlcontent -XPath "//task:ClassId" -Namespace $namespace | foreach { $_.Node.InnerXml }
$ActionCmd = select-xml -xml $xmlcontent -XPath "//task:Command" -Namespace $namespace | foreach { $_.Node.InnerXml }
$Global:ActionArg = select-xml -xml $xmlcontent -XPath "//task:Arguments" -Namespace $namespace | foreach { $_.Node.InnerXml }
$correct_wnfstates = Get-CorrectWNFstateNames -StateNames $wnfstates


write-output "A. WNF triggers for: $args (Trigger + Descr)"
write-output ''

#Write-Output "A. 1. original triggers"
#$wnfstates | ForEach-Object {Write-Output $_}

#Write-Output "A. 2. converted triggers"
#Write-Data -data $correct_wnfstates   

#write-output "A. 3. converted triggers with description"
#Write-Output ''
$correct_wnfstates | ForEach-Object {Get-WNFstateNameExplanation -correctStateName $_ -csv $wnf_csv}

Write-Output ''
Write-Output "B. Eventlog triggers for: $args"
Write-Output ''
$eventLogTrigger | ForEach-Object { Get-EventLogTrigger -eventLogQuery $_ }

Write-Output ''
write-output "C. Actions for: $args (Exe + Args)"
write-output ''

$ActionCmd | ForEach-Object { Get-ActionCommand -command $_ }
$ActionArg | ForEach-Object { Get-ActionArgument -argument $_ -scTask $False}

Write-Output ''
Write-Output "D. Actions for $args (CLSID + Hash)"
Write-Output ''
$ActionCOM | ForEach-Object { Get-ActionCOMData -CLSID $_ }