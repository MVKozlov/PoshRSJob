Function Stop-RSJob {
    <#
        .SYNOPSIS
            Stops a Windows PowerShell runspace job.

        .DESCRIPTION
            Stops a Windows PowerShell background job that has been started using Start-RSJob

        .PARAMETER Job
            The job object to stop.

        .PARAMETER Name
            The name of the jobs to stop..

        .PARAMETER ID
            The ID of the jobs to stop.

        .PARAMETER InstanceID
            The GUID of the jobs to stop.

        .PARAMETER Batch
            Name of the set of jobs to stop.

        .PARAMETER PassThru
            Allow to passthru job object

        .NOTES
            Name: Stop-RSJob
            Author: Boe Prox/Max Kozlov

        .EXAMPLE
            Get-RSJob -State Completed | Stop-RSJob

            Description
            -----------
            Stop all jobs with a State of Completed.

            .EXAMPLE
            Stop-RSJob -ID 1,5,78

            Description
            -----------
            Stop jobs with IDs 1,5,78.
    #>
    [cmdletbinding(
        DefaultParameterSetName='Job'
    )]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Job', Position=0)]
        [Alias('InputObject')]
        [RSJob[]]$Job,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Name', Position=0)]
        [string[]]$Name,
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Id', Position=0)]
        [int[]]$Id,
        [parameter(ValueFromPipelineByPropertyName=$True,
        ParameterSetName='InstanceID')]
        [string[]]$InstanceID,
        [parameter(ValueFromPipelineByPropertyName=$True,
        ParameterSetName='Batch')]
        [string[]]$Batch,
        [switch]$PassThru
    )
    Begin {
        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }
        $List = New-Object System.Collections.ArrayList
    }
    Process {
        Write-Debug "Stop-RSJob. ParameterSet: $($PSCmdlet.ParameterSetName)"
        $Property = $PSCmdlet.ParameterSetName
        # Will be good to obsolete any other parameters except Job
        if ($Property -eq 'Job') { # Stop Jobs right from pipeline
            [System.Threading.Monitor]::Enter($PoshRS_jobs.syncroot)
            try {
                if ($Job) {
                    $Job | ForEach-Object {
                        Write-Verbose "Stopping $($_.InstanceId)"
                        if ($_.State -ne 'Completed' -and $_.State -ne 'Failed' -and $_.State -ne 'Stopped') {
                            Write-Verbose "Killing job $($_.InstanceId)"
                            if ($PassThru) {
                                [void] $_.InnerJob.Stop()
                                $_
                            }
                            else {
                                [void]$List.Add(
                                    (New-Object -Typename PSObject -Property @{
                                        Job = $_
                                        StopHandle = $_.InnerJob.BeginStop($null, $null)
                                    })
                                )
                            }
                        }
                        elseif ($PassThru) {
                            $_
                        }
                    }
                }
            }
            finally {
                [System.Threading.Monitor]::Exit($PoshRS_jobs.syncroot)
            }
        }
        elseif ($PSBoundParameters[$Property]) { # Stop Jobs in the End block
            Write-Warning "Any job identification parameters considered obsolete, please, use Get-RSJob for this"
            Write-Verbose "Adding $($PSBoundParameters[$Property])"
            [void]$List.AddRange($PSBoundParameters[$Property])
        }
    }
    End {
        if ($PSCmdlet.ParameterSetName -eq 'Job' -and $List.Count -gt 0) {
            Write-Debug "End"
            foreach ($o in $List) {
                $o.Job.InnerJob.EndStop($o.StopHandle)
            }
        }
        elseif ($List.Count) { # obsolete parameter sets used
            $PSBoundParameters[$Property] = $List
            [void]$PSBoundParameters.Remove('PassThru')
            Get-RSJob @PSBoundParameters | Stop-RSJob -PassThru:$PassThru
        }
    }
}
