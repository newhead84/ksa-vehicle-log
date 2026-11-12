# KSA 차량 운행정보 DB 자동 백업 — 작업 스케줄러에서 제거 (백업 파일은 지우지 않음)
try {
  Unregister-ScheduledTask -TaskName 'KSA-Vehicle-DB-Backup' -Confirm:$false -ErrorAction Stop
  Write-Host '자동 백업 작업을 제거했습니다. 기존 백업 파일은 그대로 남아 있습니다.' -ForegroundColor Green
} catch {
  Write-Host ('제거 실패 또는 등록된 작업 없음: ' + $_.Exception.Message) -ForegroundColor Yellow
}
Read-Host '엔터를 누르면 창이 닫힙니다'
