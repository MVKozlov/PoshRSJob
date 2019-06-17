Function WriteStream {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true)]
        [Object]$IndividualJob
    )
    Begin {
        $Streams = "Verbose","Warning","Error","Output","Debug","Information"
    }

    Process {
        ForEach ($Stream in $Streams)
        {
            $streamData = $IndividualJob.InnerJob.Streams.$Stream
            If ($IndividualJob.$Stream -or $streamData)
            {
                Switch ($Stream) {
                    "Verbose"     { $streamData | ForEach-Object { Write-Verbose $_     } }
                    "Debug"       { $streamData | ForEach-Object { Write-Debug   $_     } }
                    "Warning"     { $streamData | ForEach-Object { Write-Warning $_     } }
                    "Error"       { $streamData | ForEach-Object { Write-Error   $_     } }
                    "Information" { $streamData | ForEach-Object { Write-Information $_ } }
                    "Output"      { $IndividualJob | Where-Object { $_ } | Select-Object -ExpandProperty Output }
                }
            }
        }
    }
}
