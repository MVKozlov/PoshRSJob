Function TryReceiveData {
param(
    [Parameter(ValueFromPipeline = $true)]
    [RSJob]$Job
)
PROCESS {
    If ($Job.Handle.isCompleted -AND (-NOT $Job.Completed)) {
        #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) completed")
        $Data = $null
        $CaughtErrors = $null
        Try {
            $Data = $Job.InnerJob.EndInvoke($Job.Handle)
        } Catch {
            $CaughtErrors = $_
            #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) Caught terminating Error in job: $_")
        }
        #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) Checking for errors ($($Job.InnerJob.Streams.Error.Count)) & ($($null -ne $CaughtErrors))")
        If ($Job.InnerJob.Streams.Error.Count -ne 0 -or $null -ne $CaughtErrors) {
            #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) Errors Found!")
            $ErrorList = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.ErrorRecord]
            If ($Job.InnerJob.Streams.Error) {
                ForEach ($Err in $Job.InnerJob.Streams.Error) {
                    #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("`t$($Job.Id) Adding Error")
                    [void]$ErrorList.Add($Err)
                }
            }
            If ($null -ne $CaughtErrors) {
                ForEach ($Err in $CaughtErrors) {
                    #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("`t$($Job.Id) Adding Error")
                    [void]$ErrorList.Add($Err)
                }
            }
            #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) $($ErrorList.Count) Errors Found!")
            $Job.Error = $ErrorList
        }
        #$PoshRS_jobCleanup.Host.UI.WriteVerboseLine("$($Job.Id) Disposing job")
        $Job.InnerJob.dispose()
        #Return type from Invoke() is a generic collection; need to verify the first index is not NULL
        If ($Data -and ($Data.Count -gt 0) -AND (-NOT ($Data.Count -eq 1 -AND $Null -eq $Data[0]))) {
            $Job.output = $Data
            #It's not needed because HasMoreData is a ScriptProperty
            #$Job.HasMoreData = $True
        }
        #$Error.Clear()
        $Job.Completed = $True
    }
}

}
