# KSA 차량 운행정보 시스템 — 작업 지침

> 작업 시작 전 이 문서를 먼저 읽고 진행한다. 지침이 바뀌면 이 파일을 수정해 커밋한다.
> 공개 저장소이므로 이 문서에 키·비밀번호·개인정보·관리자 연락처를 적지 않는다.

## 1. 역할
- 총무 + 코딩 전문가 관점에서 사내 시스템을 유지보수한다.
- 단일파일 구조(`index.html`, `accident-report.html`)는 의도된 설계다. 공통 로직을 별도 파일로 분리하지 않는다.

## 2. 작업 흐름
1. 작업 폴더: 사용자 PC의 로컬 저장소(`ksa-vehicle-log`)에서 직접 작업한다.
2. 시작 시 `git status` / `git log origin/main..HEAD`로 미반영 수정분·미푸시 커밋을 먼저 확인한다.
3. grep으로 위치 파악 → 필요한 라인만 확인(전체 열람 지양) → 요청 범위 내 최소 수정.
4. QA 체크(3장) 통과 후 변경 이력(5장) 갱신.
5. **커밋**: 작업 단위마다 직접 add/commit 한다. 커밋 후 항상 **미푸시 커밋 수**(`git rev-list --count origin/main..HEAD`)를 보고한다.
6. **푸시**: 임의로 하지 않는다. 커밋을 모아 두었다가 사용자가 명시적으로 요청할 때만 일괄 푸시한다.
- git 설정(저장소 로컬): 토큰 인증 `.git/.gh-cred`(커밋 대상 아님), `core.autocrlf=true`.

## 3. QA 체크 (매 수정 시)
1. HTML 태그 밸런스 (Python `HTMLParser`)
2. JS 문법 — `<script>` 블록 추출 후 `node --check`
3. CSS 중괄호 밸런스
4. 중복 id 검사 — `grep -o 'id="[^"]*"' | sort | uniq -c | awk '$1>1'`
5. `git diff --stat` / diff로 의도한 줄만 변경됐는지 확인
6. 버튼-핸들러 연결 검증 (onclick / addEventListener 실존 여부)
7. 죽은 함수 여부 (호출부 grep 교차검증)
8. CSS 변경 시 모바일(`max-width:640px`)·데스크톱(`min-width:1280px`) 모두 확인, `@media`는 항상 최하단
9. `<input style="width:100%">`는 input 자체에 text-align 지정 (td만으로는 안 됨)

## 4. 보안 체크 (신규기능/배포 시)
- Firebase Rules가 `read/write:true` 전면공개가 아닌지 확인 (인증 사용자 기준 규칙 유지)
- 민감정보를 클라이언트에 하드코딩하지 않는다
- EmailJS 등 API 키의 도메인 제한 여부 확인
- 인증활성화 → 배포 → 규칙강화 등 순서가 중요한 작업은 사전 확인 후 진행
- 사용자 입력을 innerHTML·속성값에 넣을 때는 `escapeHtml` 처리
- 공개 저장소: 과거 커밋에 남은 정보는 영구 노출로 간주, 재사용 금지가 핵심 대응

## 5. 변경 이력
- `index.html` 상단 CHANGELOG 주석(최근 ~5건) + 저장소 `CHANGELOG.md` 둘 다 갱신
- 형식: `[YYYY-MM-DD] 요청내용 요약 | 변경: 함수/영역`

## 6. 디자인 가이드
- 사내 도구는 기존 CSS 변수체계(`--navy`, `--ink`, `--line`, `--good`, `--bad`, Paperlogy) 우선
- 대외 가이드(KSA-DESIGN-GUIDE.md)는 신규 공지/배너 등 대외 콘텐츠이거나 명시 요청 시에만 적용

## 7. 모호성 처리
- UI/UX 요청이 여러 해석 가능하면 선택형 질문 1개로 방향 확정 후 작업
- 방향 전환 시 이전 구현을 완전히 되돌리고 재작업

## 8. 한글 줄바꿈
- 노출 안내문구: `word-break:keep-all; overflow-wrap:break-word;`
- 예외: 차량번호/ID 등 식별자
- 여러 항목 이어붙일 땐 `\n` + `white-space:pre-line`

## 9. DB 무손실 운영 (실사용 중)
- 매일 1회 이상 RTDB 전체 export 백업 (관리자 대시보드 백업 기능)
- 스키마 변경 배포 순서: 수동백업 → 배포 → 스모크테스트(write/read 1건)
- 필드 추가는 허용, 기존 필드명 변경/삭제 금지
- 배포 전 버전 태깅(롤백 대비)
- 운영 DB에 테스트 데이터 직접 입력 금지 (`/test/...` 또는 로컬 에뮬레이터)
- 저장은 해당 차량 노드(`fleet-data/vehicles/{차량번호}` 및 연도노드 해당 trips)만 읽고 쓴다. 전체 덮어쓰기 금지
- 2027년 이후 `fleet-data-{year}` 연도 분할 경로도 Rules 적용 대상에 포함

## 10. 구현 규칙 (재발 방지)
- 차량 정렬: 사업장(`ORG_ORDER`) → 차종(그랜저>소나타>아반떼, `modelOrder()`) → 차량번호
- 운행기록 정렬은 모든 위치에서 `tripChronoCompare()`(날짜 → submittedAt) 동일 사용 — 인덱스 매칭 기반 수정/삭제 데이터 손상 방지
- 날짜키는 `localDateKey()` 사용, `toISOString().slice(0,10)` 금지 (KST 날짜 밀림)
- Firebase 연속 정수 키 → 배열 자동변환(인덱스 0에 null) — 순회 시 null 가드
- 업무용 집계는 모두 `!isPersonal && !isCommute` 필터 일관 적용, 엑셀 내보내기는 전체 데이터 유지
- 뷰어 모드 버튼은 화이트리스트(`VIEWER_ALLOWED_TOOLBAR_BTN_IDS`) 방식 — 신규 버튼은 기본 숨김
- QR 카메라 진입 시 탭 폐기 대비: 사진 선택 즉시 `saveDraft()`, 재진입 시 임시저장 자동복원
- PDF는 html2canvas로 기존 HTML/CSS를 래스터화 (jsPDF 벡터 재구현 금지)
- GitHub Actions에서 빈 문자열 secret 대비: `os.environ.get("KEY") or "default"`

## 11. 범위 외 (재제안 금지)
- 차량 예약 시스템(사내 설비예약 사용), 소모품/정비 관리(렌터카사 담당), 관리자 권한 분리, 개인/출퇴근 사용 결재, 미제출 자동알림

## 12. 미결 이슈
- 과거 git 히스토리 내 평문 비밀번호 — 재사용 금지로 대응 완료(히스토리 클린업은 선택)
- (해소) 중복 `id="lastOdoVal"` — 현재 index.html에 없음
