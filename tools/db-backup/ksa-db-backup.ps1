# KSA 차량 운행정보 DB 자동 백업 (작업 스케줄러가 매일 11:00·23:00 실행)
# - 대시보드 [데이터 백업]과 같은 형식(version 4)으로 저장 → 대시보드 [데이터 복원]으로 그대로 복원 가능
# - 최근 7일치 보관. 새 백업이 정상 저장된 경우에만 7일 지난 파일을 지운다(실패하면 기존 파일 유지)
# - 사진 원본(Storage: 영수증·사고·대차): DB에 기록된 경로 중 아직 받지 않은 파일만 내려받아 photos 폴더에 보관(지우지 않음)
# - 저장 위치: 문서\KSA-vehicle-backup
param(
  [int]$KeepDays = 7,        # 최근 N일치 보관, 그보다 오래된 DB 백업 파일은 자동 삭제
  [int]$PhotoMinutes = 40    # 1회 실행당 사진 받기 최대 시간(분). 남은 사진은 다음 실행 때 이어서 받음
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

$ApiKey        = 'AIzaSyAGS2iP6VVLpsdbxGgaE1V5eIu-IHWNrH8'   # 웹앱(index.html)에 이미 공개된 Firebase 웹 키
$DbUrl         = 'https://ksa-vehicle-log-default-rtdb.asia-southeast1.firebasedatabase.app'
$Referer       = 'https://newhead84.github.io/ksa-vehicle-log/'
$LegacyMaxYear = 2026                                         # index.html LEGACY_DATA_MAX_YEAR 와 동일
$Bucket        = 'ksa-vehicle-log.firebasestorage.app'          # index.html FIREBASE_STORAGE_BUCKET 와 동일
$BackupDir     = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'KSA-vehicle-backup'
$TokenFile     = Join-Path $BackupDir '.refresh-token'
$LogFile       = Join-Path $BackupDir 'backup.log'
$FailFlag      = Join-Path $BackupDir 'LAST-BACKUP-FAILED.txt'
$PhotoDir      = Join-Path $BackupDir 'photos'
$PhotoFailFlag = Join-Path $BackupDir 'LAST-PHOTO-BACKUP-FAILED.txt'
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$Http = New-Object System.Net.Http.HttpClient
$Http.Timeout = [TimeSpan]::FromSeconds(120)
$Http.DefaultRequestHeaders.Referrer = [Uri]$Referer

function Write-Log([string]$msg) {
  $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
  Add-Content -Path $LogFile -Value $line -Encoding UTF8
  Write-Host $line   # Write-Output을 쓰면 함수 반환값(토큰)에 섞이므로 화면 출력만
}

function Read-Response($resp) {
  $text = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
  if (-not $resp.IsSuccessStatusCode) { throw ('HTTP {0}: {1}' -f [int]$resp.StatusCode, $text) }
  return $text
}

function Http-Get([string]$url) { return Read-Response ($Http.GetAsync($url).GetAwaiter().GetResult()) }

function Http-Post([string]$url, [string]$body, [string]$type) {
  $content = New-Object System.Net.Http.StringContent($body, [Text.Encoding]::UTF8, $type)
  return Read-Response ($Http.PostAsync($url, $content).GetAwaiter().GetResult())
}

# 읽기 권한용 토큰. 익명 로그인 계정 1개를 만들어 두고 다음부터는 갱신만 한다(계정이 매일 늘지 않도록).
function Get-IdToken {
  if (Test-Path $TokenFile) {
    try {
      $rt = (Get-Content $TokenFile -Raw).Trim()
      $r = Http-Post "https://securetoken.googleapis.com/v1/token?key=$ApiKey" ('grant_type=refresh_token&refresh_token=' + [Uri]::EscapeDataString($rt)) 'application/x-www-form-urlencoded' | ConvertFrom-Json
      Set-Content -Path $TokenFile -Value $r.refresh_token -Encoding ASCII
      return $r.id_token
    } catch {
      Write-Log ('토큰 갱신 실패, 새로 발급합니다: ' + $_.Exception.Message)
    }
  }
  $r = Http-Post "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey" '{"returnSecureToken":true}' 'application/json' | ConvertFrom-Json
  Set-Content -Path $TokenFile -Value $r.refreshToken -Encoding ASCII
  return $r.idToken
}

# DB 백업 데이터를 훑어 사진 경로마다 차량번호를 찾는다
#  - vehicles/{차량번호}/... 아래 → 그 차량번호 / plate 필드가 있는 항목 → plate / 사고(ourVehicle.plate) → 그 차량번호
function Add-PhotoPath([string]$s, [string]$plate) {
  if ($s -match '^(receipts|daecha-photos|accidents)/' -and -not $PhotoMap.ContainsKey($s)) { $PhotoMap[$s] = $plate }
}
function Find-Photos($o, [string]$plate, [string]$parentKey) {
  if ($o -is [System.Collections.IDictionary]) {
    $p = $plate
    if ($o.ContainsKey('plate') -and ($o['plate'] -is [string]) -and $o['plate']) { $p = $o['plate'] }
    elseif ($o.ContainsKey('ourVehicle') -and ($o['ourVehicle'] -is [System.Collections.IDictionary]) -and $o['ourVehicle']['plate']) { $p = [string]$o['ourVehicle']['plate'] }
    foreach ($k in @($o.Keys)) {
      $v = $o[$k]
      $cp = $p; if ($parentKey -eq 'vehicles') { $cp = [string]$k }
      if ($v -is [string]) { Add-PhotoPath $v $cp }
      elseif (($v -is [System.Collections.IDictionary]) -or ($v -is [System.Collections.IList])) { Find-Photos $v $cp ([string]$k) }
    }
  } elseif ($o -is [System.Collections.IList]) {
    foreach ($v in $o) {
      if ($v -is [string]) { Add-PhotoPath $v $plate }
      elseif (($v -is [System.Collections.IDictionary]) -or ($v -is [System.Collections.IList])) { Find-Photos $v $plate '' }
    }
  }
}
$exitCode = 0
try {
  $idToken = Get-IdToken
  $auth = [Uri]::EscapeDataString($idToken)

  $main = Http-Get "$DbUrl/fleet-data.json?auth=$auth"
  if ($main -notmatch '"vehicles"') { throw '메인 데이터(fleet-data)에 차량 정보가 없습니다. 기존 백업을 유지합니다.' }

  # 2027년 이후 연도별 노드(있는 연도만)
  $yearParts = @()
  for ($y = $LegacyMaxYear + 1; $y -le (Get-Date).Year; $y++) {
    $yd = Http-Get "$DbUrl/fleet-data-$y.json?auth=$auth"
    if ($yd -and $yd.Trim() -ne 'null' -and $yd -match '"vehicles"') { $yearParts += ('"{0}":{1}' -f $y, $yd) }
  }

  $exportedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH':'mm':'ss'.'fff'Z'", [Globalization.CultureInfo]::InvariantCulture)
  $out = '{"version":4,"exportedAt":"' + $exportedAt + '","source":"auto-backup","fleetData":' + $main + ',"yearData":{' + ($yearParts -join ',') + '}}'

  $file = Join-Path $BackupDir ('ksa-vehicle-backup_{0}.json' -f (Get-Date -Format 'yyyy-MM-dd_HHmm'))
  $tmp  = "$file.tmp"
  [IO.File]::WriteAllText($tmp, $out, (New-Object Text.UTF8Encoding($false)))
  if ((Get-Item $tmp).Length -lt 1000) { Remove-Item $tmp -Force; throw '백업 파일 크기가 비정상적으로 작습니다. 기존 백업을 유지합니다.' }
  Move-Item -Force $tmp $file

  # 새 백업 저장이 끝난 뒤에만 오래된 백업 정리 (파일명 날짜 기준 $KeepDays일 지난 파일 삭제, 방금 만든 파일은 항상 유지)
  $cutoff = (Get-Date).Date.AddDays(-($KeepDays - 1))
  $old = @(Get-ChildItem $BackupDir -Filter 'ksa-vehicle-backup_*.json' | Where-Object {
    $_.FullName -ne $file -and $_.Name -match '^ksa-vehicle-backup_(\d{4}-\d{2}-\d{2})(_\d{4})?\.json$' -and
    [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture) -lt $cutoff
  })
  foreach ($f in $old) { Remove-Item $f.FullName -Force }

  if (Test-Path $FailFlag) { Remove-Item $FailFlag -Force }
  Write-Log ('백업 성공: {0} ({1} KB), 연도별 노드 {2}개, 이전 백업 {3}개 삭제' -f (Split-Path $file -Leaf), [math]::Round((Get-Item $file).Length / 1KB), $yearParts.Count, $old.Count)

  # ── 사진 원본 백업 (DB 백업이 저장된 뒤 별도 진행 — 여기서 실패해도 DB 백업은 유지)
  # 저장 이름: photos\{구분}\{차량번호}_{원래 파일명}.jpg (사고사진은 {차량번호}_{사고ID}_{번호}.jpg)
  # 원본 Storage 경로와의 대응표: photos\index.csv
  try {
    $PhotoMap = New-Object 'System.Collections.Generic.Dictionary[string,string]'   # Storage 경로 -> 차량번호
    Add-Type -AssemblyName System.Web.Extensions
    $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $ser.MaxJsonLength = [int]::MaxValue
    $ser.RecursionLimit = 1000
    Find-Photos ($ser.DeserializeObject($out)) '차량미상' ''
    $got = 0; $moved = 0; $have = 0; $missing = 0; $fail = 0; $later = 0
    $csv = New-Object System.Collections.Generic.List[string]
    $csv.Add('차량번호,구분,파일명,원본경로(Storage)')
    $deadline = (Get-Date).AddMinutes($PhotoMinutes)
    foreach ($p in $PhotoMap.Keys) {
      if ($p -match '\.\.|[<>:|?*\\]') { $missing++; Write-Log ('사진 경로 형식 오류로 건너뜀: ' + $p); continue }   # 폴더 밖 저장·잘못된 파일명 방지
      $plate = $PhotoMap[$p] -replace '[\\/:*?"<>|\s]', ''
      if (-not $plate) { $plate = '차량미상' }
      $cat  = $p.Split('/')[0]
      $name = $plate + '_' + ($p.Substring($cat.Length + 1) -replace '/', '_')
      $local = Join-Path (Join-Path $PhotoDir $cat) $name
      $csv.Add(('"{0}","{1}","{2}","{3}"' -f $plate, $cat, $name, $p))
      $fi = New-Object IO.FileInfo($local)
      if ($fi.Exists -and $fi.Length -gt 0) { $have++; continue }
      # 이전 방식(원래 경로 그대로)으로 받아 둔 파일이 있으면 다시 받지 않고 새 이름으로 옮김
      $oldLocal = Join-Path $PhotoDir ($p -replace '/', '\')
      $ofi = New-Object IO.FileInfo($oldLocal)
      if ($ofi.Exists -and $ofi.Length -gt 0) {
        try {
          [void][IO.Directory]::CreateDirectory($fi.DirectoryName)
          if ($fi.Exists) { [IO.File]::Delete($local) }
          [IO.File]::Move($oldLocal, $local)
          $moved++; continue
        } catch { Write-Log ('사진 이름 변경 실패, 다시 받습니다: {0} ({1})' -f $p, $_.Exception.Message) }
      }
      if ((Get-Date) -gt $deadline) { $later++; continue }
      try {
        $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, ('https://firebasestorage.googleapis.com/v0/b/{0}/o/{1}?alt=media' -f $Bucket, [Uri]::EscapeDataString($p)))
        [void]$req.Headers.TryAddWithoutValidation('Authorization', ('Firebase ' + $idToken))
        $resp = $Http.SendAsync($req).GetAwaiter().GetResult()
        try {
          if ([int]$resp.StatusCode -eq 404) {
            $missing++
          } elseif (-not $resp.IsSuccessStatusCode) {
            throw ('HTTP {0}' -f [int]$resp.StatusCode)
          } else {
            $bytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
            if ($bytes.Length -eq 0) { throw '빈 파일' }
            [void][IO.Directory]::CreateDirectory($fi.DirectoryName)
            $ptmp = $local + '.tmp'
            [IO.File]::WriteAllBytes($ptmp, $bytes)
            if ([IO.File]::Exists($local)) { [IO.File]::Delete($local) }
            [IO.File]::Move($ptmp, $local)
            $got++
          }
        } finally { $resp.Dispose(); $req.Dispose() }
      } catch {
        $fail++
        if ($fail -le 5) { Write-Log ('사진 받기 실패: {0} ({1})' -f $p, $_.Exception.Message) }
      }
    }
    # 대응표 저장(엑셀에서 바로 열리도록 UTF-8 BOM), 이름 변경 후 비어 버린 이전 폴더 정리
    [IO.File]::WriteAllLines((Join-Path $PhotoDir 'index.csv'), $csv, (New-Object Text.UTF8Encoding($true)))
    Get-ChildItem -LiteralPath $PhotoDir -Directory -Recurse | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
      if (-not (Get-ChildItem -LiteralPath $_.FullName -Force | Select-Object -First 1)) { Remove-Item -LiteralPath $_.FullName -Force }
    }
    Write-Log ('사진 백업: 새로 받음 {0}, 이름 변경 {1}, 이미 있음 {2}, 서버에 없음·건너뜀 {3}, 실패 {4}, 다음 실행으로 넘김 {5} (총 {6}건)' -f $got, $moved, $have, $missing, $fail, $later, $PhotoMap.Count)
    if ($fail -gt 0) {
      Set-Content -Path $PhotoFailFlag -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + "`r`n사진 원본 $fail 건을 받지 못했습니다(다음 실행 때 다시 시도). 자세한 내용은 backup.log 참고") -Encoding UTF8
    } elseif (Test-Path $PhotoFailFlag) { Remove-Item $PhotoFailFlag -Force }
  } catch {
    Write-Log ('사진 백업 오류(DB 백업은 정상 저장됨): ' + $_.Exception.Message)
    Set-Content -Path $PhotoFailFlag -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + "`r`n사진 백업 오류: " + $_.Exception.Message) -Encoding UTF8
  }
} catch {
  $exitCode = 1
  $msg = '백업 실패: ' + $_.Exception.Message + ' (기존 백업 파일은 그대로 유지)'
  Write-Log $msg
  Set-Content -Path $FailFlag -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm') + "`r`n" + $msg + "`r`n자세한 내용은 backup.log 참고") -Encoding UTF8
} finally {
  $Http.Dispose()
  $lines = @(Get-Content $LogFile -Encoding UTF8)
  if ($lines.Count -gt 300) { $lines | Select-Object -Last 300 | Set-Content $LogFile -Encoding UTF8 }
}
exit $exitCode
