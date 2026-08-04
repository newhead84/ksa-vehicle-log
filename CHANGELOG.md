# CHANGELOG

KSA 업무용 차량 운행정보 관리 시스템 (`index.html`) 변경 이력.

형식: 각 항목은 `요청내용 요약 | 변경: 함수/영역`

## 2026-08-04

- "사업장별 차량 가동율 운행거리 비교차트"·"월별 가동율 및 운행거리" 표·차량 상세 모달·엑셀 내보내기(월별가동율 시트)에서 연평균 가동율·운행거리가 실제보다 낮게 표시되던 버그 수정: 기존 monthlyUtilForPlate()가 아직 도래하지 않은 미래 월(예: 8월 현재 시점의 9~12월)도 rate/distance를 0으로 채워 반환했는데, 각 화면의 "연평균" 집계 로직이 이 0값을 그대로 평균에 포함시켜(예: 8월 한 달만 실적이 있어도 12개월로 나눠짐) 실제 값보다 크게 축소된 수치가 표시됨(예: 경남지역본부 8월 평균 308km/대 → 화면엔 26km로 표시). monthlyUtilForPlate()에 futureMonth 플래그를 추가해 미래 월을 beforeService(차량개시일 이전)와 동일하게 "데이터 없음"으로 표시하고 모든 연평균 집계에서 제외하도록 수정 | 변경: monthlyUtilForPlate()(futureMonth 플래그 신규), monthCellHtml()(futureMonth 인자 추가), renderMonthly()(validMonths 필터), renderMonthlyCompareChart()(branchSummary/vehicleSummary 집계 필터), openVehicle()(월별 가동율 미니표 noData 조건), exportToExcel()(월별가동율 시트 validMonths/noData 조건)
- (위 항목 보강) 실제 운행기록이 단 한 건도 없는 달(수기기록 미입력 포함, 예: 시스템 실사용 개시 전인 1~7월)도 "0%/0km"가 아니라 "미입력(데이터없음)"으로 간주해 연평균 집계에서 제외하도록 수정. monthlyUtilForPlate()에 해당 월 운행기록 0건 여부를 나타내는 noData 필드를 추가하고, 비교차트/월별표/모달/엑셀 4개 소비처 모두 beforeService·futureMonth와 동일하게 이 경우도 함께 제외 | 변경: monthlyUtilForPlate()(noData 필드 추가), monthCellHtml()(noData 인자 추가), renderMonthly(), renderMonthlyCompareChart(), openVehicle(), exportToExcel()
- QR 스캔으로 진입 시 사업장/차량번호 임의 변경 방지: URL의 ?plate= 파라미터로 사업장·차량이 자동선택된 경우, 두 선택창(사업장 선택/차량번호 선택)을 비활성화(disabled)하고 "🔒 QR 스캔으로 연동된 사업장·차량입니다" 안내문구를 노출해 QR로 지정된 것과 다른 차량으로 잘못 전환·제출되는 것을 방지. 임시저장(초안) 복원 시에도 QR로 잠긴 차량과 다른 차량의 초안이면 복원 배너를 띄우지 않도록 하여 잠금이 우회되지 않게 함(초안 데이터 자체는 삭제하지 않고 유지). 관리자 대시보드 등 QR을 거치지 않은 경로는 영향 없음(선택창 계속 활성 상태 유지) | 변경: proceedEnterUserMode()(QR 진입 시 잠금 함수 호출 추가, checkDraftBanner() 호출을 잠금 판정 이후로 이동), lockVehicleSelectionForQr()(신규), checkDraftBanner()(잠긴 차량과 다른 초안이면 배너 표시 스킵), exitToRole()(역할 종료 시 잠금 해제 및 초기화), CSS(.plate-select:disabled 신규), HTML(#qrLockNote 신규)
- 수기기록(1~7월) 업로드 양식에 연도 중 재배치(소속 변경) 반영 기능 추가. ① 양식에 "지역구분"·"조정배치일자(선택)"·"사유(선택)" 열 신규 추가 — 연도 중간에 소속이 바뀐 차량은 같은 차량번호로 행을 나눠(구간별) 입력, ② 지역구분+조정배치일자가 함께 기재된 행은 업로드 시 자동으로 해당 차량의 "재배치 이력"에도 반영(날짜 오름차순 적용, 동일 일자+동일 소속 중복 방지), ③ 월별 가동율 데이터(manualMonthly)에 그 달 기준 지역구분을 함께 저장 — 차량 상세보기의 월별 가동율 표에서 현재 소속과 다른 달은 🔀 표시로 구분(마우스오버 시 당시 소속 확인), ④ 기존 "재배치 이력" 관리자 입력 기능(차량 상세보기)에 재배치 사유 입력을 필수 항목으로 추가, 이력 표시에도 사유 함께 노출, ⑤ 양식에 "작성법" 안내 시트 신규 추가 | 변경: pushBranchReassignment()(신규, changeBranch()/handleManualMonthlyUpload() 공유 로직), changeBranch()(사유 필수 검증 추가), downloadManualMonthlyTemplate()(열 추가·작성법 시트·예시 2행으로 확장), handleManualMonthlyUpload()(plate별 행 그룹핑 후 재배치 적용·월별 branch 태깅), monthlyUtilForPlate()(branch 필드 반환 추가), openVehicle()(재배치 이력에 사유 표시, 재배치 사유 입력란 신설, 월별 가동율 미니표 🔀 표시), triggerManualMonthlyUpload()(안내문구 갱신)
- "📊 엑셀 업로드(수기기록)" 버튼에 샘플 양식 다운로드 기능 추가 — 연도 입력 배너에 "📥 샘플 양식 다운로드" 버튼을 신설하여, 현재 등록된 활성 차량번호가 채워지고 1~7월 가동율(%)·거리(km) 열이 빈칸으로 준비된 엑셀(예시행 포함)을 즉시 내려받아 업로드 서식을 미리 확인할 수 있도록 함. 기존 업로드 파싱 로직 자체는 변경 없음 | 변경: downloadManualMonthlyTemplate()(신규), triggerManualMonthlyUpload()(배너 안내문구·버튼 추가)
- 엑셀 내보내기 서식 개선 + 전체운행기록 엑셀 업로드(복원/병합) 기능 신규 추가. ① 전체운행기록·개인사용현황 시트의 "일자" 단일열(예: "7/31~3"처럼 월이 바뀌면 잘못 표기되던 문제 포함)을 시작일자/종료일자 두 열로 분리, ② 모든 날짜열(계약시작일/종료일, 시작일자/종료일자, 최근운행일 등)을 텍스트가 아닌 실제 Date 타입 셀(yy-mm-dd 서식)로 저장, ③ 대여료·운행건수·주행거리·주유비 등 숫자열에 천단위 구분(#,##0) 서식 적용(신규 excelDateCell()/applyCellFormats() 헬퍼로 시트별 일괄 처리), ④ 관리자 툴바에 "🚗 전체기록 업로드" 버튼 신규 추가 — [엑셀 내보내기]로 받은 파일의 '전체운행기록' 시트만 인식하여, 이미 데이터가 있는 차량+일자 조합은 건너뛰고 없는 일자만 새 운행기록으로 추가(덮어쓰기 없음, 반영 전 확인 팝업 표시). 기존 "📊 엑셀 업로드"는 1~7월 수기기록 전용 별개 기능이라 이름에 "(수기기록)"을 덧붙여 구분(월별가동율 시트 반영은 이번 범위 제외, 추후 별도 요청 예정) | 변경: excelDateCell()/applyCellFormats()(신규), exportToExcel()(ws1~ws6 서식/열 구성), openTripRecordImportModal()/handleTripRecordImportFromModal()/applyTripRecordImport()/parseUploadDateCell()/existingDateSetForPlate()/dateRangeIntersects()(모두 신규), HTML(#tripRecordUploadBtn 신규, #manualUploadBtn 라벨 수정)
- 차량 상세 모달 3건 폰트/표시 조정: ① 계약기간 표시를 YYYY-MM-DD → YY-MM-DD(shortYMD())로 축약하고 옆 다른 통계값(총 주행거리 등)과 동일한 폰트 크기로 통일(개별 font-size:14px 오버라이드 제거), ② "건별 운행거리 추이" 스파크라인의 X축(월)·Y축(수치) 라벨 폰트를 9px→7px로 축소해 위쪽 "월별 가동율" 미니표 대비 과도하게 커 보이던 균형 조정, ③ "월별 가동율" 미니표(.mini-month-cell) 값 폰트를 9px→11px로 확대 | 변경: openVehicle()(계약기간 표시, sparkGridSvg/sparkMonthGridSvg font-size), CSS(.mini-month-cell)
- "사업장별 차량 가동율 운행거리 비교차트"의 '차량별' 보기 라벨 표기 개선: 차량번호만 표시하던 것을 "사업장약칭 차량번호 차종"으로 확장 (예: "대전세종충남 231호4132 아반떼"). 사업장명은 "○○지역본부"/"○○지부" 접미사를 생략하고 앞 지역명칭만 표시(신규 함수 branchShortLabel()), "국가기술표준원(파견)"은 "국표원"으로 단축. 차종은 기존 modelShort() 재사용(그랜저/소나타/아반떼). 라벨 폭 부족 방지를 위해 '차량별' 모드일 때만 labelW를 112→190으로 확대 | 변경: renderMonthlyCompareChart(), branchShortLabel()(신규)
- "사업장별 차량 가동율 운행거리 비교차트" 개선 3건: ① 사업장 라벨 폰트를 12px→11px로 소폭 축소해 "대전세종충남지역본부" 등 긴 사업장명 좌측 앞글자가 잘려 보이던 문제 해결, ② 막대 클릭 동작을 기존 "해당 사업장만 강조"에서 "해당 사업장 소속 차량별 가동율/운행거리를 막대 바로 아래에 펼치기(재클릭 시 접기)"로 변경(순위 정렬로 강조 기능의 실효성이 낮다는 피드백 반영), ③ 상단 탭에 '사업장별'/'차량별' 보기 전환 버튼 신규 추가 — '차량별' 선택 시 전체 차량(46~47대)을 사업장 구분 없이 연평균 기준 1등~꼴찌 flat 순위로 나열(색상은 소속 사업장 색상 유지, 차량번호·막대 클릭 시 하단 공용차량 현황으로 이동) | 변경: renderMonthlyCompareChart()(bodySvg 동적 높이 계산으로 재작성, vehicleSummary 신규 집계), mccGroupBy/mccExpandedBranch(신규, 기존 mccHighlight/toggleMccHighlight() 대체), setMccGroupBy()/toggleMccBranchExpand()(신규), setMccMetric()(그룹 전환 시 확장 상태 초기화 추가), HTML(.mcc-btn-divider 및 사업장별/차량별 버튼, #mccCaption id 추가), CSS(.mcc-groupby-btn, .mcc-btn-divider 신규)
- 공용차량 현황 카드(차량 상세 모달) 내 "월별 가동율" 1~12월 미니표(.mini-month-row, 카드 가로폭 전체 사용)와 아래쪽 "건별 운행거리 추이" 스파크라인(.sparkline-wrap, max-width:640px)의 x축 위치가 서로 어긋나 보이던 문제 수정: 미니표는 기존 가로폭(카드 전체)을 그대로 유지하고, 대신 폭이 좁은 스파크라인 쪽을 margin:auto로 카드 내 가운데 정렬해 시각적 균형을 맞춤(스파크라인 SVG 크기·비율은 기존과 동일, 변경 없음) | 변경: CSS(.sparkline-wrap)

## 2026-07-26

- 제출완료 팝업 2줄 표시(차량·건수 / 기간 분리), 완료 팝업·토스트 한글 keep-all 줄바꿈 적용 | 변경: .done-modal-msg, .submitted-notice p, showSubmitSuccess(), rangeMsg(라인 ~4234)
- 내 제출 기록 조회: 조회기간 미지정 시 최신 5건만 표시, 조회기간은 최대 3개월까지만 허용 | 변경: loadUserEditable() (라인 ~4493)
- 관리자 대시보드 '개인사용 현황' 제목 → '주말 및 공휴일 개인사용 현황'으로 변경, (가동율 미반영) 문구 추가 | 변경: #personalUseWrap 상단 section-head (라인 ~913)
- 10개 지역본부별 열람전용 링크(?view=readonly&r=토큰) 신설, 지역외 정보 비노출 | 변경: REGION_GROUPS, applyRegionViewerFilter(), openRegionUrlModal(), copyRegionUrl(), #regionUrlBtn

## 2026-07-27

- 개별 QR 선택 인쇄 시안을 QR 일괄 PDF 카드 규격(63.25mm x 90mm, QR 49.5mm)과 동일하게 mm 단위로 통일 | 변경: printQr()
- 지역본부별 열람URL 모달, 데스크탑에서 넓은 .modal 기본폭에 짧은 목록이 들어가 우측 여백이 크게 보이던 문제 수정 | 변경: .region-url-list, .modal:has(.region-url-list), openRegionUrlModal()

## 2026-07-28

- 운행기록 삭제 버튼이 확인 없이 즉시 삭제되던 문제 수정, 임시저장 삭제·운행 입력행 삭제(입력값 있을 때)에도 확인 팝업 추가 | 변경: deleteTrip(), clearDraft(), removeTripRow()

## 2026-07-29

- 관리자 로그인에 이메일 OTP 2차 인증 추가(비밀번호 확인 후 관리자 이메일로 6자리 코드 발송, 5분 유효) | 변경: #adminOtpWrap, tryAdminLogin(), sendAdminOtp(), verifyAdminOtp(), resendAdminOtp(), cancelAdminOtp(), completeAdminLogin()
- OTP 화면에 "이 기기에서 30일간 인증코드 생략" 체크박스 추가, 체크 시 신뢰 기기로 등록되어 다음 로그인부터 OTP 생략(서버측 만료시간 기준 검증) | 변경: #trustDeviceChk, isDeviceTrusted(), trustThisDevice(), generateDeviceId(), tryAdminLogin(), verifyAdminOtp(), cancelAdminOtp(), exitToRole()

## 2026-07-30

- 공공데이터포털 API키 없이 국경일/대체공휴일 자동 갱신 기능 추가: GitHub Actions(update-kr-holidays.yml)가 Nager.Date 무료 API에서 연 1회+ 공휴일을 가져와 Firebase(kr-holidays-remote)에 기록, 앱은 로드 시 이를 읽어 기존 수기 KR_HOLIDAYS(임시공휴일·선거일 등 예외 유지용)와 병합 | 변경: KR_HOLIDAYS_REMOTE, loadRemoteHolidays(), isHoliday(), loadData()
- 운행기간 날짜선택 네이티브 달력이 다크모드에서 어둡게 표시되던 문제 수정(항상 라이트 테마 강제), 달력 자체에 공휴일 표시는 브라우저 네이티브 UI 한계로 불가하여 대신 안내문구를 "업무일 기준 N일 가동율 반영"으로 축약하고 해당기간 포함 공휴일을 "공휴일 포함: M/D~M/D" 형식(연속일 구간 압축)으로 문구 뒤에 표기 | 변경: input[type="date"]{color-scheme:light}, formatHolidayRanges(), onDateRangeChange(), onDateFromChange(), #daterange-${id}
- 운행기간 1일(당일)인 경우에도 "업무일 기준 N일 가동율 반영" 안내문구 표기되도록 수정(기존엔 시작일=종료일이면 미표기), 종료일이 시작일보다 빠른 날짜로 선택되어 자동 보정될 때 사유를 알려주는 오류 안내문구(빨간색, 4초 후 자동 소멸) 추가 | 변경: onDateRangeChange(), #dateErr-${id}
- 관리자 OTP 화면 "이 기기에서 30일간 인증코드 생략" 체크박스가 모바일 등에서 탭해도 체크 표시가 보이지 않던 문제 수정: 전역 규칙(button,input,select,textarea{appearance:none})으로 네이티브 체크박스 렌더링이 제거되어 있었는데 :checked 상태의 대체 시각 표시가 없었음 → 기존 native-chk/check-icon 패턴과 동일하게 실제 input은 숨기고 형제 span(.otp-trust-icon)으로 체크 아이콘 표시(기능 로직은 변경 없음) | 변경: .otp-trust-label input[type="checkbox"], .otp-trust-icon, #trustDeviceChk
- ① 공휴일 매칭 버그 수정: isHoliday()가 UTC 기반 iso()를 써서 KST 자정 Date가 하루 전으로 밀려 매칭되던 문제(예: 2026년 광복절 대체휴일 8/17이 8/16·8/18로 잘못 표시) → 로컬 날짜 기준 localDateKey() 도입. ② 안내문구를 "업무일 기준 N일 가동율 반영됩니다./(공휴일 포함 : 명칭-날짜)" 2줄 형식으로 변경, 공휴일명 표기 추가(KR_HOLIDAY_NAMES 신규, 원격 데이터는 KR_HOLIDAYS_REMOTE_NAMES로 이름 보존). ③ 차량 선택 시 최초 생성되는 운행 카드(기본값 오늘~오늘)에서도 날짜를 직접 건드리지 않아도 안내문구가 바로 표시되도록 addTripRow()에서 onDateRangeChange() 즉시 호출 | 변경: localDateKey(), isHoliday(), holidayName(), KR_HOLIDAY_NAMES, KR_HOLIDAYS_REMOTE_NAMES, formatHolidayRanges(), onDateRangeChange(), onDateFromChange(), addTripRow(), #daterange-${id}
- ① 운행기간을 10일 이상(달력일수)으로 설정 시 몰아서 임의 입력하는 것을 방지하기 위해 종료일을 시작일+8일(최대 9일)로 자동 조정하고 사유 안내문구 표시. ② 선택 기간이 연휴 중간에서 끊겨도(예: 추석 9/24~26 중 9/25까지만 선택) 실제 공휴일명이 이어지는 한 선택기간 밖으로 확장해 연휴 전체 구간을 온전히 표시하도록 수정 | 변경: MAX_TRIP_RANGE_DAYS(신규), onDateRangeChange(), formatHolidayRanges()
- ① 가동율 계산에 개인사용(주말·공휴일) 건의 인접 업무일이 잘못 포함되던 버그 수정: calcUtilization()·monthlyUtilForPlate()가 isCommute만 제외하던 것을 isPersonal도 함께 제외하도록 수정(지역별 현황과 정책 일치). ② 미사용 dead function onDateFromChange() 제거(실제 경로는 onDateRangeChange()). ③ <b id="lastOdoVal"> 중복 id(5건) 제거(참조하는 코드 없어 id 속성만 삭제) | 변경: calcUtilization(), monthlyUtilForPlate(), onDateFromChange()(삭제), #lastOdoVal(id 삭제 5건)
- 실제운행정보입력 화면의 운행기간 안내문구가 개인사용/출퇴근사용 체크와 무관하게 항상 "업무일 기준 N일 가동율 반영됩니다"로만 표시되어 정책(①번 항목)과 불일치하던 문제 수정: 개인사용 체크 시 파란색 "개인사용(주말·공휴일) 건은 가동율에 반영되지 않습니다" 문구로, 출퇴근 선택 시 보라색 "출퇴근사용 건은 가동율에 반영되지 않습니다" 문구로 즉시 전환 표시(체크박스/버튼 클릭 즉시 반영, 날짜 재입력 불필요) | 변경: onDateRangeChange(), togglePersonalUse(), setCommuteDirection()
- 운행기간 최대 설정 일수 기준을 "달력일수 10일 미만(최대 9일)"에서 "업무일 기준 10일 이하(주말·공휴일 제외)"로 변경: 기간 내 주말·공휴일이 포함되어도 업무일수만으로 10일까지 허용하고, 초과 시 업무일 기준 10일째 날짜로 종료일 자동 조정 | 변경: MAX_TRIP_RANGE_DAYS(9→10), onDateRangeChange()

## 2026-07-31

- 임시저장 입력내역 삭제 시 확인(confirm) 팝업 재노출 문제로 팝업 제거 요청 반영 | 변경: clearDraft()
- 5초 이내 자동 소멸되던 오류·경고 안내문구 표시시간을 15초로 연장(운행기간 오류 4초→15초, 폼 입력 오류 5초→15초) | 변경: onDateRangeChange() #dateErr-${id} 타이머, showUserFormErr()
- "내 제출 기록 수정" 화면의 조회기간 date input(#searchDateFrom, #searchDateTo)이 회색 테두리(var(--line))+배경 미지정으로 클릭 가능한 입력창인지 구분이 잘 안 되던 문제 수정: 실제운행정보입력 화면의 운행기간 인풋과 동일한 톤(초록 테두리 var(--good) + 흰 배경)으로 변경, 크기(padding/font-size)는 기존 값 유지 | 변경: #searchDateFrom, #searchDateTo
- DT센터 주차안내 팝업의 카리프트 운영시간을 평일 07:30~21:00에서 07:00~20:00으로 변경 | 변경: openParkingModal() 카리프트 운행 정보 박스
- 기존 등록 차량 중 운행 기간 중간에 신규 배정/개시되는 차량(예: 183호5250, 26.5.12 개시)의 가동율이 개시 이전 기간까지 분모(전체 업무일)에 포함되어 부당하게 낮게 계산되던 문제를 위한 "차량개시일" 필드 신규 추가: 차량 상세 모달(관리자)에서 개시일 입력/해제 가능, 개시일 이전 월은 월별 가동율표·모달 미니셀·엑셀 내보내기에서 "–"(데이터없음)로 표시되고 연평균 계산에서 제외되며, 개시월은 개시일부터의 업무일만 분모로 반영 | 변경: monthlyUtilForPlate(), monthCellHtml(), renderMonthly(), openVehicle() 모달(branch-edit 신규 행, 미니 월별 셀), exportToExcel(), setServiceStartDate()(신규), clearServiceStartDate()(신규)
- ① 롯데렌터카 계약관리 엑셀 DB 반영: 46대 전체에 계약시작일·계약종료일(F/G열)과 월대여료(K열, 천원단위→원 환산) 필드 추가, 차량개시일(가동율 계산용)은 실제 신규개시 차량인 183호5250·181호6175 2대에만 한정 반영(나머지 44대의 2025-08-31은 일괄 재계약일로 판단해 미반영). 모달에 계약기간·월대여료 표시, 엑셀 차량현황 시트에 계약시작일·계약종료일·월대여료(원) 컬럼 추가. ② 지역구분 재배치 반영 시 재배치 일자를 함께 입력·기록하도록 개선(예: 181호6065 경기→강원 재배치 이력 관리): branchHistory 배열 신규 도입, 재배치 반영 모달에 날짜 입력란 추가, 이미 반영된 재배치를 소급 기록하는 경우(현재 소속과 동일 선택 시)에는 최초배정을 출발점으로 기록 | 변경: FLEET_REGISTRY(fee/contractStartDate/contractEndDate 필드 추가), loadData()·refreshDataFromStorage() 백필 로직, openVehicle() 모달(계약기간/월대여료 표시, 재배치일자 입력란, 재배치 이력 표시), changeBranch(), exportToExcel()
- 계약시작일=차량개시일이라는 확인에 따라, ①번 항목에서 183호5250·181호6175 2대로 한정했던 차량개시일(serviceStartDate)을 46대 전체에 계약시작일과 동일 값으로 반영(FLEET_REGISTRY 데이터만 수정, 로직 변경 없음) → 이제 44대의 2025-08-31도 가동율 계산 기준 개시일로 반영되어, 개시 이전 월은 월별 가동율표·엑셀에서 "–"(데이터없음) 처리됨 | 변경: FLEET_REGISTRY(serviceStartDate 46건 추가/일치화)
- 월대여료(fee) 단위 오류 수정: 롯데렌터카 원본 단가가 천원단위였는데 원단위로 그대로 반영되어 실제보다 10배 높게 표시되던 문제(예: 그랜저 5,280,000원→528,000원) → 46대 전체 fee 값을 1/10로 정정 | 변경: FLEET_REGISTRY(fee 46건 정정)
- QR 스캔 등 일반 접속 화면(역할선택 오버레이)에서 "관리자 대시보드" 버튼·로그인/OTP 폼이 항상 노출되어 운전자 입력 화면에 불필요한 요소로 보이던 문제 개선 → 해당 UI 전체를 신규 컨테이너(#adminEntryWrap, 기본 display:none)로 감싸 기본 화면에서 제거하고, 별도 진입 URL(?admin=1)로 접속했을 때만 노출되도록 변경. 운전자용 "차량 운행정보 입력" 버튼·운전중 조작금지 경고문구는 기존과 동일하게 유지 . 이에 따라 상단 안내문구 "사용 목적을 선택해 주세요"도 버튼이 1개(일반)/2개(admin=1) 모두에 어울리도록 "아래 버튼을 눌러 시작해 주세요"로 수정 | 변경: #adminEntryWrap(신규), roleOverlay 마크업, 하단 초기화 스크립트(admin=1 파라미터 체크 추가), 안내문구 텍스트
- 재배치 이력(branchHistory) 개별 항목 수정/삭제 기능 신규 추가: 기존에는 changeBranch()로 새 이력을 추가만 할 수 있어, 이미 기록된 이력의 날짜가 잘못된 경우 정정할 방법이 없었음(현재 소속을 재선택하면 새 이력이 중복 추가됨) → 관리자 모달 재배치 이력 각 항목에 날짜 입력란·저장 버튼·삭제 버튼(확인 팝업 포함) 추가 | 변경: openVehicle() 모달(재배치 이력 영역), saveBranchHistoryDate()(신규), deleteBranchHistoryEntry()(신규)
- ① showAdminToast() 저장 완료 안내가 statStrip 앞(배경 페이지)에 삽입되어, 차량 상세 모달(z-index:50)이 열려 있는 동안은 모달에 가려 실제로는 저장이 됐는데도 "반응 없음"처럼 보이던 버그 수정 → 모달 열림 여부와 무관하게 화면 최상단에 고정 표시(position:fixed, z-index:200)되도록 변경. ② 월대여료 단가 정정(FLEET_REGISTRY) 이후에도, 기존 백필 로직은 Firebase에 이미 저장된 fee 값(정정 전 잘못된 값 포함)은 건너뛰어 실제 반영이 안 되던 문제 → FLEET_REGISTRY 최신값으로 강제 덮어쓰는 1회성 관리자 유틸리티 resyncFleetFees() 및 "💰 월대여료 재동기화" 버튼 신규 추가 | 변경: showAdminToast(), resyncFleetFees()(신규), 관리자 툴바(resyncFeeBtn 버튼)
- 관리자가 운행기록을 수정할 때마다 마지막 수정시각을 기록하는 lastEditedAt 필드 신규 추가(최초 제출시각 submittedAt과 별개, 값은 매 저장 시 최신 시각으로 덮어씀), 엑셀내보내기 '전체운행기록' 시트에 '입력일시'(submittedAt)·'최종수정일시'(lastEditedAt) 2개 컬럼으로 노출 | 변경: saveTripEdits(), exportToExcel()
- "💰 월대여료 재동기화"(1회성 단가 정정용) 버튼을 제거하고 "📋 차량계약정보 관리" 버튼으로 교체: 지정 엑셀 양식(차량번호·차종·지역구분·계약시작일·계약종료일·월대여료·이전차량번호) 업로드로 계약정보 변경을 상시 반영할 수 있도록 개선. 기존 차량번호는 계약 연장(단가·계약기간 변경)으로 처리되어 contractHistory에 변경 전/후 값이 기록되고, 신규 차량번호는 등록으로 처리되며 '이전차량번호' 열을 채우면 반납되는 차량을 자동 운용중지 처리하고 replacedFrom/replacedBy로 상호 연결(차량 교체 시나리오, 대수 증감 모두 지원). 반영 전 변경 내역 확인 팝업 표시, 차량 상세 모달에 계약갱신·교체 이력 표시 | 변경: 관리자 툴바(resyncFeeBtn→contractMgmtBtn 버튼), resyncFleetFees()(삭제), openContractImportModal()(신규), downloadContractTemplate()(신규), handleContractExcelUpload()(신규), applyContractImport()(신규), openVehicle() 모달(계약/차량교체 이력 표시 영역)
- 신규 "📋 차량계약정보 관리" 버튼이 열람전용 URL(전체·지역별 공통)에도 그대로 노출되던 문제 수정. 근본 원인: applyViewerModeUI()가 "숨길 버튼 id"를 블랙리스트로 나열하는 방식이라 새 관리자 버튼을 추가할 때마다 id를 빠뜨리기 쉬웠음(반복되어 온 패턴) → 관리자 툴바(admin-topbar-actions)는 "허용할 버튼 id"만 나열하는 화이트리스트 방식(VIEWER_ALLOWED_TOOLBAR_BTN_IDS=['refreshBtn','exportExcelBtn'])으로 전환하여, 앞으로 툴바에 어떤 버튼이 추가되어도 명시적으로 허용하지 않는 한 열람전용 모드에서 자동으로 숨겨지도록 구조 변경. 툴바 밖의 차량목록 영역 버튼(차량추가/QR PDF)은 기존과 동일하게 개별 숨김 유지 | 변경: exportToExcel 버튼(id="exportExcelBtn" 부여), applyViewerModeUI(), VIEWER_ALLOWED_TOOLBAR_BTN_IDS(신규)

## 2026-08-01

- "내 제출 기록 수정" 화면의 이름검색 방식이 타인 이름을 알면 누구나 조회·수정 가능한 구조였던 보안 문제 개선: ① 제출 시 브라우저 기기별 임의 토큰(editToken)을 생성해 트립에 함께 저장, ② 본인수정 조회 시 이름이 일치해도 이 기기의 토큰이 함께 일치해야만(=제출 당시 사용한 바로 그 기기) 결과에 노출되도록 필터링, ③ 제출일(submittedAt) 기준 3일(USER_EDIT_WINDOW_DAYS)이 지난 기록은 본인수정 화면에서 제외하고 관리자 문의 안내로 전환(과거 데이터는 editToken이 없어 자동으로 이 규칙에 포함되어 별도 마이그레이션 불필요) | 변경: getDeviceEditToken()(신규), USER_EDIT_WINDOW_DAYS·EDIT_DEVICE_TOKEN_KEY(신규), doSubmit()(editToken 저장), loadUserEditable()(기기토큰·기간 필터링, 안내문구), #userEditWrap 안내문구
- "내 제출 기록 수정" 화면 안내문구가 "조회기간 지정 시에도 3일만 조회 가능"한 것으로 오인될 소지가 있어, 조회기간 지정 UI 자체를 제거하고 기기+제출일 기준 창을 3일→10일로 확대: ① #searchDateFrom/#searchDateTo 인풋과 "기간 초기화" 버튼 제거, ② loadUserEditable()에서 조회기간 검증·필터링 로직 제거, ③ USER_EDIT_WINDOW_DAYS 3→10 | 변경: USER_EDIT_WINDOW_DAYS, loadUserEditable(), clearUserEditDateRange()(제거), #userEditWrap 안내문구
- 위 변경 시 남아있던 "최신 5건만 표시" 건수 제한 제거: 10일 이내 기록은 건수 제한 없이 전부 표시(최신순 정렬만 적용) | 변경: loadUserEditable()
- 지역구분별 가동현황 표 오른쪽에 렌탈계약정보 3개 컬럼 추가: 계약개시일·계약종료일(YY-MM-DD, 지역 내 대수가 가장 많은 대표 계약기간 1건), 월대여료(원, 지역 내 전체 차량 합계, 천단위 구분) | 변경: shortYMD()(신규), renderRegionSummary()
- 변경이력 관리 방식을 CHANGELOG.md 분리 방식으로 전환: index.html 상단 블록에는 최근 항목만 남기고, 과거 전체 이력(2026-07-26~08-01, 36건)은 CHANGELOG.md로 이전 | 변경: 문서 구조(코드 변경 없음)
- 지역구분별 가동현황 표 UI 조정: ① 가동율(막대바+%)·총주유비 컬럼 우측정렬, ② 운행건수 헤더의 괄호 설명문구가 컬럼 폭을 과도하게 넓히던 문제 수정(설명문구 줄바꿈+최대폭 제한, 다른 표에는 영향 없도록 .region-table 범위로 한정) | 변경: CSS(.region-table td:nth-child(5), .region-table .util-bar-wrap, .region-table th .region-th-note)
- 월별 가동율 표에서 지역본부명·차량번호 클릭 시 하단 공용차량 현황의 해당 지역그룹/차량카드로 스크롤 이동하는 기능 추가(지역구분별 가동현황 표의 기존 지역본부 클릭 이동 기능과 동일한 사용성 제공) | 변경: renderMonthly()(클릭 핸들러 추가), scrollToVehicleCard()(신규), vcardHtml()(data-plate 속성 추가)
- 지역구분별 가동현황 표 UI 2차 조정: ① 운행건수 헤더 괄호설명 "당시소속 기준, 개인·출퇴근사용 제외"→"개인사용제외"로 축약(데스크탑에서 줄바꿈되어 어긋나 보이던 문제 해소, white-space:nowrap 적용), ② 월대여료(원) 컬럼 우측정렬 누락 수정, ③ 총주유비 컬럼에 우측 패딩 추가 및 가동율 막대를 우측정렬→가운데정렬로 변경해 두 컬럼이 붙어 보이던 문제 해소 | 변경: CSS(.region-table td:nth-child(5), .region-table td:nth-child(9)(신규), .region-table .util-bar-wrap, .region-table th .region-th-note), renderRegionSummary() 헤더 텍스트
- 지역구분별 가동현황 표 열 정렬 규칙 재정비: ① 차량대수·운행건수·총주행거리·가동율·계약개시일·계약종료일은 제목 포함 중간맞춤, ② 총주유비·월대여료는 제목만 중간맞춤(내용은 기존 우측맞춤 유지) | 변경: CSS(.region-table th:nth-child(2/3/4/6/7/8)(신규), .region-table td:nth-child(2/3/4/6/7/8)(신규), .region-table th:nth-child(5/9)(신규))

## 2026-08-01
- 지역구분별 가동현황 표 모바일 화면 깨짐(계약개시일/계약종료일/월대여료 텍스트 겹침) 수정
  - 원인: 8/1 신규 추가된 3개 컬럼(계약개시일·계약종료일·월대여료)이 모바일 전용 `table-layout:fixed` 규칙에 폭 미지정 상태로 남아있어, min-width 560px 내에서 남은 여백을 3개 컬럼이 나눠쓰며 텍스트 겹침 발생
  - 수정: 7/8/9번째 컬럼 폭 지정(78px/78px/90px) + white-space:nowrap 추가, 컨테이너 min-width 560px→790px로 확대
  - 변경 영역: CSS(.region-table th:nth-child(7/8/9), .region-table td:nth-child(7/8/9), .table-scroll .region-table)
- 차량별 "주사용자"(운행건수 기준 1~3위) 표기 기능 신규 추가
  - 월별 가동율 표: 차량번호 컬럼 오른쪽(1월 컬럼 왼쪽)에 "주사용자" 컬럼 신규 추가, 순위·이름·건수를 줄바꿈으로 표기(예: `1위 홍길동(12)`), 운행기록 없으면 "–"
  - 공용차량 현황 카드: ① 모델명 아래 표시되던 지역구분(사업자명)이 상단 지역그룹 제목과 중복되어 제거, ② "최근 운행 YYYY-MM-DD" 옆에 최근운행자명 추가 표기, ③ 하단 상태 배지 중 "운행기록없음"/"정상"이 표시되던 케이스를 주사용자(1~3위) 라벨로 대체(단, "점검필요 N건"·"운용중지" 배지는 기존과 동일하게 유지)
  - 집계 기준: 차량별 전체 운행기록(trips)의 운행자(t.user) 필드를 건수 기준 내림차순 정렬(동률 시 이름 가나다순), 개인사용·출퇴근사용 건도 포함하여 집계(가동율 계산과는 별개 지표)
  - 변경 영역: `topDriversForPlate()`(신규), `topDriversCellHtml()`(신규), `topDriversTagHtml()`(신규), `renderMonthly()`, `vcardHtml()`, CSS(`.top-driver-cell`, `.top-drivers-tag`, `.month-table` 컬럼폭 재조정)
- 주사용자 표기 간소화 및 간격 조정
  - 월별 가동율 표·공용차량 현황 카드 모두에서 "N위" 순위 표현과 이름 뒤 운행건수(괄호) 표시를 제거, 이름만 쉼표로 나열(예: `홍길동, 김철수, 이영희`). 정렬 순서는 기존과 동일하게 운행건수 많은 순 유지
  - 공용차량 현황 카드 라벨은 "주사용자 : 이름, 이름, 이름" 형식으로 콜론 추가
  - 월별 가동율 표에서 차량번호 컬럼과 주사용자 컬럼 사이 간격이 과도하게 떨어져 보이던 문제 수정: 차량번호 컬럼 폭 축소(17%→11%, 모바일 130px→90px) 및 우측 패딩 축소(6px→2px), 주사용자 컬럼 폭 확대(13%→19%, 모바일 90px→130px)로 균형 조정. 데스크탑/모바일 미디어쿼리 모두 반영
  - 변경 영역: `topDriversCellHtml()`, `topDriversTagHtml()`, CSS(`.month-table th:first-child`, `.month-table th:nth-child(2)`, `.month-table td:first-child`, 모바일 미디어쿼리 동일 항목)
- 공용차량 현황 카드 모델명 표기 위치 변경
  - 기존: 차량번호 아래 별도 줄에 회색 보조텍스트(.region)로 모델명 표시
  - 변경: 차량번호 줄에 병합하여 "차량번호 - 모델명" 형식으로 표기(예: `181호6175 - 그랜저`). 폰트 크기·색상은 기존 차량번호(.plate 클래스, Paperlogy 16px navy) 그대로 유지
  - 변경 영역: `vcardHtml()`
- 공용차량 현황 카드 모델명 축약 미적용 버그 수정
  - 증상: 위 항목에서 병합 표시한 모델명이 "그랜저/소나타/아반떼"가 아니라 원본 계약 모델명 전체(예: `AVANTE CN7 (G)1.6 모던 2WD AT`)가 그대로 노출됨
  - 원인: 월별 가동율 표(`renderMonthly()`)는 이미 `modelShort()`로 축약해 표시하고 있었으나, 공용차량 현황 카드(`vcardHtml()`)는 `v.model` 원본 문자열을 축약 없이 그대로 출력하고 있었음
  - 조치: `vcardHtml()`에서도 동일하게 `modelShort(v.model)`을 거치도록 통일 → 카드에 `181호6175 - 그랜저`처럼 축약 모델명만 표시
  - 변경 영역: `vcardHtml()` (`v.model` → `modelShort(v.model)`)
- 모바일에서 월별 가동율 표 차량번호 셀(차량번호+차종) 잘림 수정
  - 증상: 좁은 화면에서 차종명(예: 그랜저/소나타 등)이 대부분 잘려 한두 글자만 노출
  - 원인: 모바일 미디어쿼리에서 `.plate-cell`이 가로(flex-row)로 차량번호+차종을 배치하는데, 첫 컬럼 폭이 90px로 고정되어 있어 차량번호 텍스트만으로 폭이 거의 소진되고 차종명에 남는 공간이 거의 없었음(overflow:hidden으로 인해 말줄임표 없이 그대로 잘림)
  - 조치: 모바일에서만 `.plate-cell`을 세로(flex-column)로 배치하여 차량번호/차종이 각각 한 줄씩 컬럼 폭 전체를 사용하도록 변경, 각 줄에 `text-overflow:ellipsis` 적용해 실제로 넘칠 경우에도 "..."으로 자연스럽게 표시되도록 개선(데스크탑 레이아웃은 변경 없음)
  - 변경 영역: CSS(모바일 미디어쿼리 `.plate-cell`, `.plate-cell .plate-num`, `.plate-cell .plate-model`)

## 2026-08-02

- 공용차량 현황 카드 운행기록 표(관리자 수정모드 / 열람전용 URL 공통) 레이아웃 조정
  - 시작거리·종료거리·거리(누계) 표시값에 천단위 구분기호(`,`) 미적용 문제 수정 (기존 주유비 컬럼만 `toLocaleString()` 적용되어 있었음)
  - 컬럼 폭 재배분: 운행기간 15%→13%, 구분 15%→11%, 대차번호 6%→13%. 대차번호 내용이 잘려 보이던 문제 및 구분 컬럼(출퇴근 버튼)이 필요 이상으로 넓게 보이던 문제 완화
  - 관리자 수정모드 기간(시작/종료일자) 입력창을 부모 컬럼 전체 폭에 맞춰 늘어나던 방식(`width:100%`)에서 고정 최대폭(88px)으로 축소해 입력창이 과도하게 커 보이던 문제 수정
  - 헤더(제목)와 셀 내용의 정렬 기준 통일: 헤더 전체 가운데정렬, 시작거리·종료거리·거리(누계)·제출자·상태·구분·대차번호는 내용도 가운데정렬(제목 포함 중간맞춤), 주유비는 기존과 같이 내용 우측정렬 유지
  - 변경 영역: CSS(`.trip-table th/td:nth-child` 폭, `.trip-table td.trip-period .adm-date-from/.adm-date-to`, `.trip-table th`, `.trip-table td[data-label="..."]`(신규)), 운행기록 표 렌더링(시작거리/종료거리/거리(누계) `view-val` 표시부)
- 공용차량 현황 카드 운행기록 표 잔여 이슈 보강 (위 항목에서 놓친 부분)
  - 증상 1: 행 높이가 다른 컬럼(운행기간의 시작/종료 2줄, 구분의 체크박스 2개+출퇴근 버튼 2개)보다 짧은 셀들(시작거리·종료거리·제출자 등)이 세로 방향으로 상단에 붙어 보임(중간맞춤 아님)
    - 원인: `.trip-table th,td`에 `vertical-align`이 명시되어 있지 않았음
    - 조치: `.trip-table th,.trip-table td`에 `vertical-align:middle` 명시 적용
  - 증상 2: 관리자 수정모드로 전환해 시작거리·종료거리를 수정하려 할 때, 입력창에는 여전히 콤마 없는 원본 숫자(예: `22286`)만 표시됨 — 바로 위 항목에서 적용한 천단위 구분기호는 조회(view-val) 상태에만 반영되고, 수정모드 입력창(edit-inp)에는 반영되지 않았던 것
    - 조치: 시작거리·종료거리·거리(누계) 입력창의 최초 렌더값에도 `toLocaleString()` 적용, 타이핑 중에도 실시간으로 콤마가 반영되도록 신규 함수 `formatOdoInput()`(기존 `formatFuelInput()`의 자릿수 그룹핑 로직 재사용) 연결, 콤마가 포함된 입력값을 저장/재계산 시 올바르게 숫자로 파싱하도록 `recalcModalDist()`·`saveTripEdits()`에서 콤마 제거 후 `Number()` 변환하도록 보정
  - 변경 영역: CSS(`.trip-table th,td` vertical-align), 시작거리/종료거리/거리(누계) 렌더링(edit-inp value), `recalcModalDist()`, `formatOdoInput()`(신규), `saveTripEdits()`
- 공용차량 현황 카드 운행기록 표 정렬 재신고 재조사 — 실제 원인은 세로가 아니라 가로 정렬이었음
  - 증상: 수정모드에서 운행기간·운행자·행선지·주유비·상태·대차번호 값이 컬럼 가운데로 안 맞고 좌측에 치우쳐 보임
  - 원인: 입력창(`input.edit-inp`)이 `width:100%`로 셀을 꽉 채우고 있어, 부모 `<td>`에 준 `text-align:center`는 "입력창 박스의 위치"에만 영향을 줄 뿐 입력창 "안의 텍스트"는 계속 브라우저 기본값(좌측정렬)로 보였음. 운행기간은 시작/종료 줄(`.trip-date-row`)이 `display:flex`로 좌측정렬되어 있어 블록 전체가 왼쪽으로 붙어 보였음
  - 조치: 운행자·행선지·상태·대차번호 `input.edit-inp`에 `text-align:center`, 주유비 `input.edit-inp`에는 기존 컨벤션대로 `text-align:right` 직접 지정. 운행기간 `.trip-date-row`에 `justify-content:center` 추가
  - 변경 영역: CSS(`.trip-table td[data-label="..."] input.edit-inp`, `.trip-table td.trip-period .trip-date-row`)

## 2026-08-03

- 월별 가동율 및 운행거리 표에 틀고정(제목행 sticky) 적용
  - 표 영역(`.month-table-wrap`)에 세로 스크롤(`max-height:70vh`, `overflow-y:auto`) 부여, 기존 좌우 스크롤(`overflow-x:auto`)은 유지
  - `.month-table thead th`에 `position:sticky;top:0`(+구분선용 `box-shadow`) 적용해 차량 수가 많아 표가 길어져도 스크롤 시 "차량번호/주사용자/1월~12월/연평균" 제목행이 항상 보이도록 함
  - 변경 영역: CSS(`.month-table-wrap`, `.month-table thead th`)

- 차량 상세 모달 "건별 운행거리 추이" 스파크라인 그래프 x축 및 렌더링 버그 수정
  - 증상: 운행건이 실제로는 7/31, 8/3 등 며칠 간격밖에 안 되는데도, 그래프 선이 상단 월별 가동율 바의 4월~9월 구간에 걸쳐 그려지는 것처럼 보임
  - 원인 ①(x축 설계): 기존 로직은 `trips` 배열의 순번(몇 번째 운행건인지)만으로 등간격 배치했고 실제 날짜 간격은 전혀 반영하지 않았음
  - 원인 ②(렌더링): `<svg viewBox="0 0 560 80" width="100%" height="80">`에 `preserveAspectRatio`를 지정하지 않아 기본값(`xMidYMid meet`)이 적용됨. 실제 렌더링 박스(모달 폭 기준 약 800px대 × 80px)가 viewBox 비율(560:80=7:1)보다 훨씬 넓어, 그래프가 중앙 일부 폭에만 축소되어 그려지고 그 여백이 우연히 상단 월별 바의 특정 월과 겹쳐 보였음(실제 날짜와는 무관한 착시)
  - 조치: `openVehicle()`에서 각 운행건의 `isoDate`를 이용해 x좌표를 실제 날짜 간격에 비례하도록 재계산(날짜 정보가 없거나 모든 날짜가 동일해 구간폭이 0이 되는 경우에는 기존 등간격 방식으로 안전하게 대체). `<svg>`에 `preserveAspectRatio="none"` 추가로 항상 컨테이너 전체 폭을 채우도록 수정
  - 변경 영역: `openVehicle()` (x좌표 계산 로직), sparkline-wrap 내 `<svg>` 태그
- 개인사용(주말·공휴일) 체크 시 주행거리 기준 예상 최소 유류비 안내문구를 주유비 미입력 상태에서도 즉시 표시하도록 개선
  - 증상: 기존 `checkFuelVsDistance()`는 주유비 입력값이 있어야만 최소 유류비를 계산해 경고를 표시했음. 그 결과 개인사용 체크 직후에는 아무 안내도 보이지 않고, 사용자가 주유비 숫자를 입력한 뒤에야 비로소 안내(혹은 경고)가 나타나는 구조였음
  - 조치: 개인사용 체크박스 안내 영역(`personal-notice`) 안에 신규 안내 영역(`fuelminguide-${id}`)을 추가. `checkFuelVsDistance()`에서 주유비 입력 여부와 무관하게 개인사용 체크 + 주행거리(시작/종료거리) 확정 시점에 "현재 주행거리 OOkm 기준 예상 최소 유류비는 약 OOO원" 안내를 우선 표시하도록 분리. 실제 주유비를 입력한 뒤 그 금액이 최소 유류비에 못 미치는 경우의 기존 경고(`fuelwarn`)는 그대로 유지되어, 체크 시점의 사전 안내 → 입력 후 과소입력 경고로 자연스럽게 이어짐
  - 변경 영역: HTML(개인사용 체크박스 안내 템플릿, `fuelminguide-${id}` 신규), `checkFuelVsDistance()`
- 공용차량 현황 카드 운행기록 표(뷰모드): 이전에 입력창(edit-inp)에만 적용됐던 가운데정렬이 조회 상태(view-val, 수정모드 진입 전)의 운행자·행선지 셀에는 반영되지 않아 여전히 좌측정렬로 보이던 문제 수정 | 변경: CSS(`.trip-table td[data-label="운행자"]`, `.trip-table td[data-label="행선지"]`에 `text-align:center` 추가)
- 운행기간 표기 버그 수정 및 형식 통일
  - 증상: 월이 바뀌는 운행기간(예: 7/31~8/3)이 종료일의 "일"만 이어붙여져 `7/31~3`으로 잘못 표기됨
  - 원인: `doSubmit()`/`saveTripEdits()`/`saveUserEdits()` 3곳에 동일한 버그 로직(종료월 없이 종료일만 문자열에 이어붙임)이 중복 존재
  - 조치: 표기 형식을 `YY-MM-DD`(시작=종료 시) / `YY-MM-DD~YY-MM-DD`(기간)로 통일한 공용 함수 `formatTripDateDisplay(fromISO,toISO)`를 신설하고, 위 3개 함수의 중복 로직을 모두 이 함수 호출로 교체. 운행기록 표 렌더링도 저장된 `t.date` 문자열 그대로 쓰지 않고 `isoDate`/`dateTo`로 즉시 재계산해서 표시하도록 변경 — 과거에 이미 잘못 저장된 기존 데이터도 별도 마이그레이션 없이 화면에서 정상 표기됨. 차량카드 상단 "최근 운행"(`vehicleStatsOf()`의 `lastDate`)도 동일 원인의 버그가 있어 함께 수정
  - 변경 영역: `formatTripDateDisplay()`(신규), `doSubmit()`, `saveTripEdits()`, `saveUserEdits()`, `vehicleStatsOf()`, 운행기록 표 렌더링(트립기간 `view-val`)
- 공휴일 자동 갱신 데이터 소스 이중화(공공데이터포털 특일정보 우선 + Nager.Date 폴백)
  - 배경: 기존 `update-kr-holidays.yml`은 공공데이터포털 API키 발급 절차 없이 쓸 수 있는 Nager.Date만 사용 중이었음. 공공데이터포털 API키를 발급받아 정식 공공 데이터 소스로 전환 요청
  - 방식(사용자 선택): 완전 대체가 아닌 **이중화** — 한국천문연구원_특일정보 `getRestDeInfo`(관공서 공휴일, 대체·임시공휴일 반영)를 주 소스로 사용하고, 서비스키 미설정·API 인증오류·네트워크 오류·응답 0건 등 실패 상황에서는 자동으로 기존 Nager.Date 조회로 폴백
  - 연도(당해년+익년) × 월(1~12) 단위로 순회 조회 후 병합, `isHoliday=="Y"` 항목만 필터링해 기존과 동일한 `{"YYYY-MM-DD":"공휴일명"}` 포맷으로 Firebase(`kr-holidays-remote`)에 기록 — index.html 소비 로직(`loadRemoteHolidays()`, `isHoliday()`, `holidayName()` 등)은 변경 없음
  - **운영 반영 필요 조치**: GitHub 저장소 Secret에 `DATA_GO_KR_API_KEY`(공공데이터포털에서 발급받은 서비스키, Decoding 값) 등록 필요. 미등록 시에도 자동으로 Nager.Date 폴백되어 기능 자체는 계속 정상 동작함
  - 변경 영역: `.github/workflows/update-kr-holidays.yml`(전면 재작성), `index.html` 주석(`KR_HOLIDAYS`, `KR_HOLIDAYS_REMOTE` 상단, 코드 로직 변경 없음)
- 차량 상세 모달 "건별 운행거리 추이" 스파크라인에 Y축 정보 추가
  - 증상: 그래프 선만 그려지고 축/눈금/단위가 전혀 없어, 27~30km 같은 소량 데이터든 큰 값이든 선의 높낮이가 무엇을 의미하는지 알 수 없었음
  - 조치: 신규 함수 `sparklineNiceStep()`으로 해당 차량의 실제 건별 거리 최댓값을 기준으로 1/2/5×10^n 단위의 "보기 좋은" 눈금 간격을 자동 산출(약 4개 안팎 눈금), 고정 상한(예: 전 차량 공통 0~4,000km) 없이 차량별 실제 데이터 범위에 맞춰 동적 스케일링. 좌측에 km 눈금선+텍스트 라벨 표시, 각 운행 데이터 포인트에 점(dot) 표시, 운행기록이 없는 차량은 그래프 대신 "운행 기록 없음" 문구로 대체
  - 참고: 운행정보가 없는 구간(월)은 애초에 이 그래프의 좌표 계산 대상이 아니므로(실제 trips 배열 기준으로만 점을 찍음) 별도 처리 불필요했음 — 축 정보 부재만이 실제 원인
  - 변경 영역: `sparklineNiceStep()`(신규), `openVehicle()`(Y축 스케일/그리드/점 계산, svg 마크업)
- "월별 가동율" 표에 운행거리(km) 병기 및 차량별 비교 차트 신설
  - 제목 변경: "월별 가동율" → "월별 가동율 및 운행거리"
  - 표 각 월 셀에 기존 가동율(%) 아래 해당 월 운행거리(km)를 함께 표시(연평균 열에는 연간 총 운행거리 병기) | 변경: `monthCellHtml()`, `renderMonthly()`
  - 표 하단에 "차량별 가동율·운행거리 비교 차트" 섹션 신설(기본 접힘, 펼쳐야 확인 가능). 지역구분별로 그룹핑해 차량마다 연평균 가동율(%) 막대와 연간 총 운행거리(km) 막대를 나란히 표시. 운행거리 막대는 (상세 모달 스파크라인의 차량별 동적 스케일과 달리) 차량 간 비교가 목적이므로 전체 차량 공통 최댓값 기준으로 스케일링 | 변경: `renderMonthlyCompareChart()`(신규), HTML(`#monthlyCompareChartWrap`, `#monthlyCompareChart` 신규 섹션), CSS(`.month-cell-km`, `.mcc-*`)

- [2026-08-03] 차량별 월별 가동율·운행거리 비교 차트를 X축=1~12월 고정 라인차트로 전면 개편
  - 기존: 차량마다 "가동율(연평균%) vs 운행거리(연간합계km)" 두 막대를 나란히 비교 → 요청 취지는 월별 비교(X축=월)였음
  - 변경: 상단에 가동율(%)/운행거리(km) 전환 탭 버튼 추가, 지역본부별 그룹핑된 차량마다 1~12월 추이선(라인차트)+범례 표시
  - 가동율 축은 0~100% 고정, 운행거리 축은 전체 차량의 "월별" 최댓값 기준(연간 합계 아님)으로 스케일링해 지역본부 간에도 비교 가능
  - 변경: `renderMonthlyCompareChart()`(라인차트로 재작성), `setMccMetric()`(신규), `mccMetric`/`MCC_LINE_COLORS`(신규), HTML(`#monthlyCompareChartWrap` 상단 탭 버튼), CSS(`.mcc-chart-block`/`.mcc-svg-wrap`/`.mcc-legend*`/`.mcc-metric-btn` 신규, 미사용 `.mcc-row`/`.mcc-label`/`.mcc-bars`/`.mcc-bar-line`/`.mcc-bar-tag`/`.mcc-bar`/`.mcc-km-val` 제거)

- [2026-08-03] 차량 상세 모달 "건별 운행거리 추이" 스파크라인 x축을 달력(월별) 기준으로 재변경
  - 기존: 실제 운행일자의 최소~최대 범위에만 비례 배치되어, 데이터가 7·8월 두 건뿐이어도 그래프 전체 폭에 걸쳐 그려져 위쪽 "월별 가동율" 표와 달 위치가 대응되지 않는 것처럼 보임
  - 변경: 위쪽 표와 동일한 `monthlyYear`(선택 연도) 1/1~12/31 전체를 x축으로 고정, 해당 연도의 운행 건만 표시. 데이터 없는 달(1~6월)은 빈 공간, 실제 운행일이 있는 달(7월·8월)에만 정확한 위치에 점 표시. 월 구분 점선+1~12월 라벨 하단 추가
  - 변경: `openVehicle()`(sparkYear/yearTrips 기준 x좌표 재계산, sparkMonthGridSvg 신규, 안내문구에 연도 표기)

- [2026-08-03] "차량별 월별 가동율·운행거리 비교차트" 섹션명을 "월별 차량 가동율·운행거리 비교차트"로 변경
  - 변경: HTML(`#monthlyCompareChartWrap` 상단 `<h2>` 텍스트)

- [2026-08-03] "건별 운행거리 추이" 스파크라인에서 일부 운행 건이 실제 발생 월이 아닌 좌측 끝(1월 위치)에 찍히는 문제 수정
  - 원인: isoDate 필드가 비어있는 예외 데이터가 연도 필터링(yearTrips) 단계에서부터 아예 제외되거나, 제외되지 않더라도 위치 계산 단계에서 날짜를 알 수 없어 균등분산 fallback(첫 건은 좌측 끝=1월 위치)으로 배치되던 구조적 문제
  - 수정: 실효 날짜 계산 함수 `resolveTripIsoForSpark()`를 신규 도입해, isoDate가 비어있어도 원본 날짜 텍스트(`t.date`)를 `parseTripDateField()`로 재파싱한 값을 연도 필터링과 좌표 계산 모두에 동일하게 사용하도록 변경(기존에는 이 복구 로직이 좌표 계산 단계에만 있어 필터링 단계에서 이미 누락된 건은 복구되지 못했음)
  - 부가 개선: 월 구분 라벨(1~12월) 가독성 향상(색상 var(--muted)→var(--ink), 크기 8→9px), 비교차트 쪽 월 라벨도 동일하게 개선하고 양끝(1월/12월) 라벨이 잘리지 않도록 정렬 보정(anchor: start/middle/end)
  - 변경: `openVehicle()`(resolveTripIsoForSpark 신규, yearTrips/xs 계산 로직), `renderMonthlyCompareChart()`(monthGridSvg 라벨 스타일/정렬)

- [2026-08-03] "월별 차량 가동율·운행거리 비교차트"를 "사업장별 차량 가동율 운행거리 비교차트"로 개편
  - 기존: 15개 사업장별로 하위 차트를 분리하고, 각 하위 차트 안에서 소속 차량마다 개별 추이선을 그리는 방식(차량 단위 비교)이었음
  - 변경: 사업장별 하위 차트 분리를 없애고 하나의 차트에 15개 사업장을 각각 한 선으로 표시. 각 사업장 선의 월별 값은 해당 사업장 소속 차량들의 평균(평균 가동율%, 평균 운행거리km, 당월 beforeService 아닌 차량만 반영)
  - 운행거리 축도 차량 개별 최댓값이 아닌 사업장 평균값 기준 전체 공통 최댓값으로 스케일링
  - 범례는 차량번호 대신 사업장명으로 표시(클릭 시 기존과 동일하게 하단 공용차량 현황의 해당 사업장 그룹으로 스크롤)
  - 변경: `renderMonthlyCompareChart()`(사업장 평균 집계 로직 추가, 단일 차트로 재작성), `MCC_LINE_COLORS`(15개 사업장 대응 위해 10→15색 확장), HTML(섹션 `<h2>` 제목, 안내문구)

- [2026-08-03] 지역별 열람전용 링크(`?view=readonly&r=토큰`)에서 "사업장별 차량 가동율 운행거리 비교차트" 섹션 숨김 처리
  - 사유: 해당 차트는 15개 사업장 전체를 한 화면에서 비교하는 성격이라 단일 지역 스코프로 제한된 열람모드 취지에 맞지 않음
  - 전체 열람 링크(`?view=readonly`, 토큰 없음)에서는 기존과 동일하게 계속 노출됨
  - 변경: HTML(`.section-head`에 `id="mccSectionHead"` 추가), `applyViewerModeUI()`(viewerRegionToken 존재 시 `#mccSectionHead`·`#monthlyCompareChartWrap` display:none 처리)

- [2026-08-03] "사업장별 차량 가동율 운행거리 비교차트"가 데스크탑 화면에서 가로로 눌려 찌그러져 보이던 버그 수정
  - 원인: `<svg width="100%" height="${h}">`(h는 고정 280px)에 `preserveAspectRatio="none"`까지 겹쳐서, 실제 표시폭(컨테이너 100%, 데스크탑에서 640px보다 훨씬 넓음)과 viewBox(640x280) 비율이 달라도 그 차이를 그대로 강제로 늘려 채웠기 때문
  - 수정: viewBox를 실제 렌더링될 컨테이너 폭에 맞춰 동적으로 계산(기존 비율 640:280 유지)하도록 변경하고 `preserveAspectRatio="none"`을 제거해 항상 1:1로 그려지도록 함
  - 보완: 비교차트 섹션이 접힘 상태(폭 0)로 최초 렌더링되는 구조라, `toggleSection()`에서 이 섹션이 펼쳐질 때 폭을 재측정해 다시 그리도록 추가. 창 크기 변경 시에도 재측정하도록 디바운스 리사이즈 핸들러 신규 추가
  - 함께 요청된 폰트 확대 반영: 안내문구 11px→13px, 범례 11px→13px(스와치 10px→12px), 월별 가동율 표 "주사용자" 컬럼 10px→11.5px(모바일 9px→10.5px)
  - 변경: `renderMonthlyCompareChart()`(컨테이너 폭 측정 로직, svg 태그), `toggleSection()`(펼침 시 재렌더 추가), `initMccChartResize()`(신규), CSS(`.mcc-caption` 신규, `.mcc-legend`/`.mcc-legend-item`/`.mcc-legend-swatch`, `.top-driver-cell`)

- [2026-08-03] 상단 통계 카드(statStrip)에 "총대여료 합계" 카드 신규 추가
  - 위치: 누적 주유비 카드 바로 옆(오른쪽)에 배치
  - 집계 기준: 현재 화면에 노출된 차량(`plates`) 기준 `v.fee`(월대여료) 합계
  - 지역 스코프: 별도 지역 필터링 로직을 추가하지 않아도, 지역본부별 열람전용 링크(`?view=readonly&r=토큰`)는 `applyRegionViewerFilter()`가 이미 `data.vehicles` 자체를 해당 지역 소속 차량으로 제한해두므로 자동으로 해당 사업장 기준 합계만 표시됨
  - 변경: `renderStats()`(`totalFee` 집계 및 카드 마크업 추가), CSS(`.stat-strip` `grid-template-columns` 4열→5열 확장: `1.4fr 1fr 1fr 1fr` → `1.4fr 1fr 1fr 1fr 1fr`)
