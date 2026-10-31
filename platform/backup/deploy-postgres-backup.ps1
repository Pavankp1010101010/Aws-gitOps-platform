param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^i-[0-9a-f]{17}$')]
  [string]$InstanceId,

  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$')]
  [string]$BackupBucket,

  [string]$Profile = 'Aws-GitOps-Profile',
  [string]$Region = 'us-east-1'
)

$ErrorActionPreference = 'Stop'
$accountId = & aws sts get-caller-identity --profile $Profile --region $Region --query Account --output text
if ($LASTEXITCODE -ne 0 -or $accountId -ne '507720142035') {
  throw 'The AWS profile must resolve to the approved project account.'
}

$instanceDocument = & aws ec2 describe-instances --profile $Profile --region $Region `
  --instance-ids $InstanceId --output json
if ($LASTEXITCODE -ne 0) {
  throw 'Could not verify the selected EC2 instance.'
}

$instance = $instanceDocument | ConvertFrom-Json
$matchingInstances = @(
  foreach ($reservation in $instance.Reservations) {
    foreach ($candidate in $reservation.Instances) {
      $nameTag = $candidate.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -First 1
      if ($candidate.State.Name -eq 'running' -and $nameTag.Value -eq 'agtp-demo-k3s') {
        $candidate
      }
    }
  }
)
if ($matchingInstances.Count -ne 1) {
  throw 'The selected instance must be the single running agtp-demo-k3s host.'
}

$tar = Get-Command tar.exe -ErrorAction SilentlyContinue
if ($null -eq $tar) {
  throw 'tar.exe is required to package the backup service for SSM.'
}

$temporaryDirectory = Join-Path $env:TEMP ('agtp-backup-deploy-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null
try {
  $archive = Join-Path $temporaryDirectory 'backup-service.tar.gz'
  & $tar.Source -czf $archive -C $PSScriptRoot `
    backup-postgres.sh install-postgres-backup.sh `
    agtp-postgres-backup.service agtp-postgres-backup.timer
  if ($LASTEXITCODE -ne 0) {
    throw 'Could not package the checked-in backup service files.'
  }

  $encodedArchive = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($archive))
  $remoteCommand = @(
    'set -eu'
    'temporary_directory="$(mktemp -d /tmp/agtp-backup-install.XXXXXX)"'
    'cleanup() { rm -f -- "$temporary_directory/backup-postgres.sh" "$temporary_directory/install-postgres-backup.sh" "$temporary_directory/agtp-postgres-backup.service" "$temporary_directory/agtp-postgres-backup.timer"; rmdir -- "$temporary_directory"; }'
    'trap cleanup EXIT'
    'printf %s ' + $encodedArchive + ' | base64 --decode | tar -xz -C "$temporary_directory"'
    'bash "$temporary_directory/install-postgres-backup.sh" ' + $BackupBucket
  )

  $request = @{
    DocumentName   = 'AWS-RunShellScript'
    InstanceIds    = @($InstanceId)
    TimeoutSeconds = 180
    Comment        = 'Install the reviewed PostgreSQL backup service'
    Parameters     = @{ commands = $remoteCommand }
  } | ConvertTo-Json -Depth 8 -Compress
  $requestPath = Join-Path $temporaryDirectory 'ssm-request.json'
  [System.IO.File]::WriteAllText(
    $requestPath,
    $request,
    (New-Object System.Text.UTF8Encoding($false))
  )

  $dispatch = & aws ssm send-command --profile $Profile --region $Region `
    --cli-input-json "file://$requestPath" --output json
  if ($LASTEXITCODE -ne 0) {
    throw 'SSM could not dispatch the backup service installation.'
  }
  $commandId = ($dispatch | ConvertFrom-Json).Command.CommandId

  $deadline = (Get-Date).AddMinutes(4)
  do {
    Start-Sleep -Seconds 5
    $invocation = & aws ssm get-command-invocation --profile $Profile --region $Region `
      --command-id $commandId --instance-id $InstanceId --output json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
      continue
    }
  } while ($invocation.Status -in @('Pending', 'InProgress', 'Delayed') -and (Get-Date) -lt $deadline)

  if ($null -eq $invocation -or $invocation.Status -ne 'Success') {
    if ($null -ne $invocation) {
      Write-Output $invocation.StandardOutputContent
      Write-Output $invocation.StandardErrorContent
    }
    throw 'The backup service installation did not complete successfully.'
  }

  Write-Output $invocation.StandardOutputContent
} finally {
  Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
