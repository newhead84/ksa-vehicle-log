# KSA 차량 운행정보 DB 자동 백업 — 작업 스케줄러 등록 (install-backup.bat 더블클릭으로 실행)
$ErrorActionPreference = 'Stop'
$TaskName = 'KSA-Vehicle-DB-Backup'
$Script   = Join-Path $PSScriptRoot 'ksa-db-backup.ps1'

try {
  $action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f $Script)
  # 매일 11:00, 23:00 두 번 실행
  $trigger  = @((New-ScheduledTaskTrigger -Daily -At '11:00'), (New-ScheduledTaskTrigger -Daily -At '23:00'))
  # 예정 시각에 PC가 꺼져 있었으면 다음에 켜질 때 바로 실행
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 1)
  Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Description 'KSA 차량 운행정보 DB·사진 백업, 매일 11:00·23:00 (문서\KSA-vehicle-backup)' -Force | Out-Null
  Write-Host ''
  Write-Host '[1/2] 작업 스케줄러 등록 완료: 매일 11:00, 23:00 (PC가 꺼져 있었으면 켜진 뒤 실행)' -ForegroundColor Green
  Write-Host '[2/2] 첫 백업을 지금 실행합니다... (사진은 이번에 최대 10분만 받고, 나머지는 예약 실행 때 이어서 받습니다)'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Script -PhotoMinutes 10
  if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host '설치 완료. 첫 백업이 저장되었습니다.' -ForegroundColor Green
  } else {
    Write-Host ''
    Write-Host '작업은 등록됐지만 첫 백업이 실패했습니다. 위 메시지를 Claude에게 알려 주세요.' -ForegroundColor Yellow
  }
  Write-Host ('백업 폴더: ' + (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'KSA-vehicle-backup'))
} catch {
  Write-Host ('설치 실패: ' + $_.Exception.Message) -ForegroundColor Red
}
Write-Host ''
Read-Host '엔터를 누르면 창이 닫힙니다'
