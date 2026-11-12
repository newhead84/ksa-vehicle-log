# DB 자동 백업 (관리자 PC용)

- `install-backup.bat` 더블클릭 → Windows 작업 스케줄러에 매일 12:10 백업 등록 + 첫 백업 즉시 실행
- 저장 위치: `문서\KSA-vehicle-backup\ksa-vehicle-backup_YYYY-MM-DD.json` (최근 7일치 보관, 7일 지난 파일 자동 삭제 — `ksa-db-backup.ps1`의 `$KeepDays`로 변경)
- 형식: 대시보드 [데이터 백업]과 동일(version 4) → 대시보드 [데이터 복원]으로 복원
- 새 백업 저장에 성공한 경우에만 오래된 파일 삭제. 실패 시 기존 파일 유지 + `LAST-BACKUP-FAILED.txt` 생성, 기록은 `backup.log`
- PC가 꺼져 있어 예정 시각을 놓치면 다음에 켜질 때 실행
- 제거: `uninstall-backup.bat` 더블클릭 (백업 파일은 남음)
- 백업 범위: `fleet-data` + 2027년 이후 `fleet-data-{연도}` (대시보드 백업과 동일). 관리자 전용 노드(`dedicated-fleet-data` 등)는 제외
- 서버 측 안전망: Firebase RTDB 자동 백업(매일, 30일 보관)이 별도로 동작 중
- 복원 시 주의: 사진 원본(영수증·사고·대차)은 Firebase Storage에 있어 이 백업에 포함되지 않음(DB에는 파일 경로만 저장)
