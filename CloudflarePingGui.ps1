<#
  Lightweight Windows GUI to find low-latency Cloudflare (or any) IPs.
  Measures TCP handshake latency to a configurable port.

  Run:
    powershell -ExecutionPolicy Bypass -STA -File .\CloudflarePingGui.ps1
  or double-click Start-CloudflarePingGui.bat
#>
[CmdletBinding()]
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:DefaultRanges = @(
    '173.245.48.0/20', '103.21.244.0/22', '103.22.200.0/22',
    '103.31.4.0/22', '141.101.64.0/18', '108.162.192.0/18',
    '190.93.240.0/20', '188.114.96.0/20', '197.234.240.0/22',
    '198.41.128.0/17', '162.158.0.0/15', '104.16.0.0/13',
    '104.24.0.0/14', '172.64.0.0/13', '131.0.72.0/22'
) -join [Environment]::NewLine

$script:WorkerScript = {
    param([string]$Range, [string]$Address, [int]$Port, [int]$TimeoutMs, [int]$Attempts)

    $samples = New-Object System.Collections.Generic.List[double]
    $lastError = $null
    for ($i = 0; $i -lt $Attempts; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        try {
            $watch = [System.Diagnostics.Stopwatch]::StartNew()
            $task = $client.ConnectAsync($Address, $Port)
            if ($task.Wait($TimeoutMs)) {
                $watch.Stop()
                if ($task.IsFaulted) {
                    $lastError = 'refused'
                }
                else {
                    $samples.Add($watch.Elapsed.TotalMilliseconds)
                }
            }
            else {
                $lastError = 'timeout'
            }
        }
        catch {
            $lastError = 'refused'
        }
        finally {
            $client.Close()
            $client.Dispose()
        }
    }

    if ($samples.Count -gt 0) {
        $sorted = @($samples | Sort-Object)
        $median = $sorted[[int][math]::Floor(($sorted.Count - 1) / 2)]
        [pscustomobject]@{
            Range     = $Range
            IP        = $Address
            Port      = $Port
            BestMs    = [math]::Round($sorted[0], 1)
            MedianMs  = [math]::Round($median, 1)
            LossPct   = [math]::Round(100 * ($Attempts - $sorted.Count) / $Attempts, 0)
            Status    = 'ok'
        }
    }
    else {
        [pscustomobject]@{
            Range     = $Range
            IP        = $Address
            Port      = $Port
            BestMs    = $null
            MedianMs  = $null
            LossPct   = 100
            Status    = if ($lastError) { $lastError } else { 'failed' }
        }
    }
}

function ConvertTo-UInt32IPv4 {
    param([string]$Address)
    $bytes = [System.Net.IPAddress]::Parse($Address).GetAddressBytes()
    return ([uint32]$bytes[0] -shl 24) -bor ([uint32]$bytes[1] -shl 16) -bor
           ([uint32]$bytes[2] -shl 8) -bor [uint32]$bytes[3]
}

function ConvertFrom-UInt32IPv4 {
    param([uint32]$Value)
    return '{0}.{1}.{2}.{3}' -f (($Value -shr 24) -band 255),
        (($Value -shr 16) -band 255), (($Value -shr 8) -band 255), ($Value -band 255)
}

function Get-TargetsFromLine {
    param([string]$Line, [int]$SamplesPerRange)

    $entry = $Line.Trim()
    if (-not $entry -or $entry.StartsWith('#')) { return @() }

    if ($entry -notmatch '/') {
        return @([pscustomobject]@{ Range = $entry; IP = $entry })
    }

    $parts = $entry.Split('/')
    $network = ConvertTo-UInt32IPv4 $parts[0]
    $prefix = [int]$parts[1]
    if ($prefix -lt 0 -or $prefix -gt 32) { throw "Invalid prefix in '$entry'." }

    $hostBits = 32 - $prefix
    if ($hostBits -le 1) {
        return @([pscustomobject]@{ Range = $entry; IP = (ConvertFrom-UInt32IPv4 $network) })
    }

    $hostCount = [uint64]1 -shl $hostBits
    $wanted = [math]::Min($SamplesPerRange, [int][math]::Min($hostCount - 2, 2000))
    $picked = New-Object System.Collections.Generic.HashSet[uint32]
    $result = New-Object System.Collections.Generic.List[object]

    $guard = 0
    while ($result.Count -lt $wanted -and $guard -lt ($wanted * 20 + 50)) {
        $guard++
        $offset = [uint32](Get-Random -Minimum 1 -Maximum ([int64]$hostCount - 1))
        if ($picked.Add($network + $offset)) {
            $result.Add([pscustomobject]@{ Range = $entry; IP = (ConvertFrom-UInt32IPv4 ($network + $offset)) })
        }
    }
    return $result.ToArray()
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Cloudflare Clean IP / Latency Scanner'
$form.Size = New-Object System.Drawing.Size(940, 660)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(820, 560)

$rangeLabel = New-Object System.Windows.Forms.Label
$rangeLabel.Text = 'IP ranges (CIDR) or single IPs, one per line:'
$rangeLabel.Location = New-Object System.Drawing.Point(12, 12)
$rangeLabel.AutoSize = $true
$form.Controls.Add($rangeLabel)

$rangeBox = New-Object System.Windows.Forms.TextBox
$rangeBox.Multiline = $true
$rangeBox.ScrollBars = 'Vertical'
$rangeBox.Location = New-Object System.Drawing.Point(12, 32)
$rangeBox.Size = New-Object System.Drawing.Size(300, 300)
$rangeBox.Anchor = 'Top,Left,Bottom'
$rangeBox.Text = $script:DefaultRanges
$form.Controls.Add($rangeBox)

function New-LabeledNumeric {
    param([string]$Text, [int]$Top, [decimal]$Min, [decimal]$Max, [decimal]$Value)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point(330, ($Top + 3))
    $label.AutoSize = $true
    $form.Controls.Add($label)

    $numeric = New-Object System.Windows.Forms.NumericUpDown
    $numeric.Location = New-Object System.Drawing.Point(460, $Top)
    $numeric.Size = New-Object System.Drawing.Size(90, 22)
    $numeric.Minimum = $Min
    $numeric.Maximum = $Max
    $numeric.Value = $Value
    $form.Controls.Add($numeric)
    return $numeric
}

$portInput = New-LabeledNumeric -Text 'Port:' -Top 32 -Min 1 -Max 65535 -Value 443
$samplesInput = New-LabeledNumeric -Text 'IPs sampled per range:' -Top 62 -Min 1 -Max 200 -Value 8
$attemptsInput = New-LabeledNumeric -Text 'Attempts per IP:' -Top 92 -Min 1 -Max 10 -Value 3
$timeoutInput = New-LabeledNumeric -Text 'Timeout (ms):' -Top 122 -Min 100 -Max 10000 -Value 1200
$threadsInput = New-LabeledNumeric -Text 'Parallel workers:' -Top 152 -Min 1 -Max 128 -Value 32

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = 'Start scan'
$startButton.Location = New-Object System.Drawing.Point(330, 192)
$startButton.Size = New-Object System.Drawing.Size(105, 30)
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = 'Stop'
$stopButton.Location = New-Object System.Drawing.Point(445, 192)
$stopButton.Size = New-Object System.Drawing.Size(105, 30)
$stopButton.Enabled = $false
$form.Controls.Add($stopButton)

$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = 'Export CSV'
$exportButton.Location = New-Object System.Drawing.Point(560, 192)
$exportButton.Size = New-Object System.Drawing.Size(105, 30)
$exportButton.Enabled = $false
$form.Controls.Add($exportButton)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = 'Copy best IP'
$copyButton.Location = New-Object System.Drawing.Point(675, 192)
$copyButton.Size = New-Object System.Drawing.Size(105, 30)
$copyButton.Enabled = $false
$form.Controls.Add($copyButton)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(330, 232)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$progressBar.Anchor = 'Top,Left,Right'
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Idle.'
$statusLabel.Location = New-Object System.Drawing.Point(330, 258)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.Anchor = 'Top,Left,Right'
$form.Controls.Add($statusLabel)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(12, 345)
$grid.Size = New-Object System.Drawing.Size(898, 265)
$grid.Anchor = 'Top,Left,Right,Bottom'
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.AutoSizeColumnsMode = 'Fill'
$form.Controls.Add($grid)

$script:Results = New-Object System.Collections.Generic.List[object]
$script:Pool = $null
$script:Jobs = New-Object System.Collections.Generic.List[object]
$script:Cancelled = $false

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 300

function Set-RunningState {
    param([bool]$Running)
    $startButton.Enabled = -not $Running
    $stopButton.Enabled = $Running
    $rangeBox.Enabled = -not $Running
    foreach ($input in @($portInput, $samplesInput, $attemptsInput, $timeoutInput, $threadsInput)) {
        $input.Enabled = -not $Running
    }
}

function Show-Results {
    $reachable = @($script:Results | Where-Object { $_.Status -eq 'ok' } | Sort-Object MedianMs, BestMs)
    $unreachable = @($script:Results | Where-Object { $_.Status -ne 'ok' })
    $ordered = @($reachable) + @($unreachable)

    $table = New-Object System.Data.DataTable
    foreach ($column in 'Range', 'IP', 'Port', 'MedianMs', 'BestMs', 'LossPct', 'Status') {
        [void]$table.Columns.Add($column)
    }
    foreach ($row in $ordered) {
        [void]$table.Rows.Add($row.Range, $row.IP, $row.Port, $row.MedianMs, $row.BestMs, $row.LossPct, $row.Status)
    }
    $grid.DataSource = $table

    $exportButton.Enabled = $script:Results.Count -gt 0
    $copyButton.Enabled = $reachable.Count -gt 0
}

function Stop-Scan {
    param([string]$Message)
    $script:Cancelled = $true
    $timer.Stop()
    foreach ($job in $script:Jobs) {
        if (-not $job.Handle.IsCompleted) {
            try { $job.Shell.Stop() } catch { }
        }
        try { $job.Shell.Dispose() } catch { }
    }
    $script:Jobs.Clear()
    if ($script:Pool) {
        try { $script:Pool.Close(); $script:Pool.Dispose() } catch { }
        $script:Pool = $null
    }
    Set-RunningState -Running $false
    $statusLabel.Text = $Message
    Show-Results
}

$timer.Add_Tick({
    $completed = 0
    foreach ($job in $script:Jobs) {
        if ($job.Handle.IsCompleted) {
            $completed++
            if (-not $job.Collected) {
                $job.Collected = $true
                try {
                    foreach ($item in $job.Shell.EndInvoke($job.Handle)) {
                        if ($item) { $script:Results.Add($item) }
                    }
                }
                catch { }
                finally { try { $job.Shell.Dispose() } catch { } }
            }
        }
    }

    $total = $script:Jobs.Count
    if ($total -gt 0) {
        $progressBar.Value = [math]::Min(100, [int](100 * $completed / $total))
        $okCount = @($script:Results | Where-Object { $_.Status -eq 'ok' }).Count
        $statusLabel.Text = "Tested $completed / $total targets - reachable: $okCount"
    }

    if ($total -gt 0 -and $completed -eq $total) {
        Stop-Scan -Message "Scan complete: $completed targets tested."
    }
    elseif ($completed % 5 -eq 0) {
        Show-Results
    }
})

$startButton.Add_Click({
    $targets = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($line in $rangeBox.Lines) {
            foreach ($target in (Get-TargetsFromLine -Line $line -SamplesPerRange ([int]$samplesInput.Value))) {
                $targets.Add($target)
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Invalid input', 'OK', 'Error') | Out-Null
        return
    }

    if ($targets.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Add at least one CIDR range or IP address.', 'Nothing to scan', 'OK', 'Warning') | Out-Null
        return
    }

    $script:Results = New-Object System.Collections.Generic.List[object]
    $script:Jobs = New-Object System.Collections.Generic.List[object]
    $script:Cancelled = $false
    $grid.DataSource = $null
    $progressBar.Value = 0
    $exportButton.Enabled = $false
    $copyButton.Enabled = $false
    Set-RunningState -Running $true
    $statusLabel.Text = "Starting scan of $($targets.Count) targets..."

    $port = [int]$portInput.Value
    $timeoutMs = [int]$timeoutInput.Value
    $attempts = [int]$attemptsInput.Value

    $script:Pool = [runspacefactory]::CreateRunspacePool(1, [int]$threadsInput.Value)
    $script:Pool.Open()

    foreach ($target in $targets) {
        $shell = [powershell]::Create()
        $shell.RunspacePool = $script:Pool
        [void]$shell.AddScript($script:WorkerScript)
        [void]$shell.AddArgument($target.Range)
        [void]$shell.AddArgument($target.IP)
        [void]$shell.AddArgument($port)
        [void]$shell.AddArgument($timeoutMs)
        [void]$shell.AddArgument($attempts)
        $script:Jobs.Add([pscustomobject]@{
            Shell     = $shell
            Handle    = $shell.BeginInvoke()
            Collected = $false
        })
    }

    $timer.Start()
})

$stopButton.Add_Click({ Stop-Scan -Message 'Scan stopped by user.' })

$exportButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = 'CSV files (*.csv)|*.csv'
    $dialog.FileName = "latency-scan-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:Results |
            Sort-Object @{ Expression = { $_.Status -ne 'ok' } }, MedianMs, BestMs |
            Export-Csv -Path $dialog.FileName -NoTypeInformation -Encoding UTF8
        $statusLabel.Text = "Saved: $($dialog.FileName)"
    }
})

$copyButton.Add_Click({
    $best = $script:Results | Where-Object { $_.Status -eq 'ok' } | Sort-Object MedianMs, BestMs | Select-Object -First 1
    if ($best) {
        [System.Windows.Forms.Clipboard]::SetText($best.IP)
        $statusLabel.Text = "Copied $($best.IP) ($($best.MedianMs) ms median on port $($best.Port))"
    }
})

$form.Add_FormClosing({
    if ($stopButton.Enabled) { Stop-Scan -Message 'Closing.' }
})

[void]$form.ShowDialog()
$form.Dispose()
