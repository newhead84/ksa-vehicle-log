# DB·사진 자동 백업 (관리자 PC용)

- `install-backup.bat` 더블클릭 → Windows 작업 스케줄러에 **매일 11:00, 23:00** 백업 등록 + 첫 백업 즉시 실행 (다시 실행하면 기존 예약을 새 설정으로 교체)
- 저장 위치: `문서\KSA-vehicle-backup\ksa-vehicle-backup_YYYY-MM-DD_HHmm.json` (최근 7일치 보관, 7일 지난 파일 자동 삭제 — `ksa-db-backup.ps1`의 `$KeepDays`로 변경)
- 형식: 대시보드 [데이터 백업]과 동일(version 4) → 대시보드 [데이터 복원]으로 복원
- 새 백업 저장에 성공한 경우에만 오래된 파일 삭제. 실패 시 기존 파일 유지 + `LAST-BACKUP-FAILED.txt` 생성, 기록은 `backup.log`
- PC가 꺼져 있어 예정 시각을 놓치면 다음에 켜질 때 실행(놓친 횟수와 관계없이 1회)
- 제거: `uninstall-backup.bat` 더블클릭 (백업 파일·사진은 남음)
- 백업 범위: `fleet-data` + 2027년 이후 `fleet-data-{연도}` (대시보드 백업과 동일). 관리자 전용 노드(`dedicated-fleet-data` 등)는 제외
- **사진 원본**(Storage `receipts/`·`accidents/`·`daecha-photos/`): DB 백업 직후 DB에 기록된 사진 중 아직 받지 않은 파일만 `photos\{구분}\{차량번호}_{원래 파일명}`으로 저장(사고사진은 `{차량번호}_{사고ID}_{번호}.jpg`, 차량번호를 못 찾으면 `차량미상_`). 원본 Storage 경로와의 대응표는 `photos\index.csv`(엑셀로 열림). 이전 방식(원래 경로 그대로)으로 받아 둔 파일은 다시 받지 않고 새 이름으로 옮김. 로컬 사진은 지우지 않음(누적). 1회 실행당 최대 40분(`$PhotoMinutes`, 설치 시 첫 실행은 10분) — 남은 사진은 다음 실행 때 이어서 받음. 실패 시 `LAST-PHOTO-BACKUP-FAILED.txt`(DB 백업에는 영향 없음)
- 사진 복원: 자동 복원 기능 없음. Storage 원본이 사라진 경우 `photos\index.csv`의 '원본경로(Storage)' 위치(폴더·파일명)로 Firebase 콘솔 > Storage에 업로드하면 화면에서 다시 열림
- 서버 측 안전망: Firebase RTDB 자동 백업(매일, 30일 보관)이 별도로 동작 중(사진은 미포함)
