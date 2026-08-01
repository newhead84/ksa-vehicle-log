# CHANGELOG

KSA 업무용 차량 운행정보 관리 시스템 (`index.html`) 변경 이력.

형식: 각 항목은 `요청내용 요약 | 변경: 함수/영역`

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
