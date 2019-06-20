Function SetIsReceived {
    Param (
        [parameter(ValueFromPipeline=$True)]
        [rsjob]$RSJob
    )
    Begin{
        $Flags = 'nonpublic','instance','static'
        $isReseivedStates = @("Completed", "Failed", "Stopped")
    }
    Process {
        $SetTrue = ($isReseivedStates -contains $RSJob.State)
        If ($PSVersionTable['PSEdition'] -and $PSVersionTable.PSEdition -eq 'Core') {
            $RSJob.IsReceived = $SetTrue
        }
        Else {
            $Field = $RSJob.gettype().GetField('IsReceived',$Flags)
            $Field.SetValue($RSJob,$SetTrue)
        }
    }
}