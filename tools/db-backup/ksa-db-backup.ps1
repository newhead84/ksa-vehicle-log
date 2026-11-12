# KSA 차량 운행정보 DB 자동 백업 (작업 스케줄러가 매일 1회 실행)
# - 대시보드 [데이터 백업]과 같은 형식(version 4)으로 저장 → 대시보드 [데이터 복원]으로 그대로 복원 가능
# - 새 백업이 정상 저장된 경우에만 오래된 백업을 지운다(실패하면 기존 파일 유지)
# - 저장 위치: 문서\KSA-vehicle-backup
param([int]$KeepCount = 1)   # 남길 백업 개수 (예: 7로 바꾸면 최근 7일치 보관)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

$ApiKey        = 'AIzaSyAGS2iP6VVLpsdbxGgaE1V5eIu-IHWNrH8'   # 웹앱(index.html)에 이미 공개된 Firebase 웹 키
$DbUrl         = 'https://ksa-vehicle-log-default-rtdb.asia-southeast1.firebasedatabase.app'
$Referer       = 'https://newhead84.github.io/ksa-vehicle-log/'
$LegacyMaxYear = 2026                                         # index.html LEGACY_DATA_MAX_YEAR 와 동일
$BackupDir     = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'KSA-vehicle-backup'
$TokenFile     = Join-Path $BackupDir '.refresh-token'
$LogFile       = Join-Path $BackupDir 'backup.log'
$FailFlag      = Join-Path $BackupDir 'LAST-BACKUP-FAILED.txt'
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

$exitCode = 0
try {
  $auth = [Uri]::EscapeDataString((Get-IdToken))

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

  $file = Join-Path $BackupDir ('ksa-vehicle-backup_{0}.json' -f (Get-Date -Format 'yyyy-MM-dd'))
  $tmp  = "$file.tmp"
  [IO.File]::WriteAllText($tmp, $out, (New-Object Text.UTF8Encoding($false)))
  if ((Get-Item $tmp).Length -lt 1000) { Remove-Item $tmp -Force; throw '백업 파일 크기가 비정상적으로 작습니다. 기존 백업을 유지합니다.' }
  Move-Item -Force $tmp $file

  # 새 백업 저장이 끝난 뒤에만 오래된 백업 정리 (파일명 날짜 기준 최신 $KeepCount개 유지)
  $old = @(Get-ChildItem $BackupDir -Filter 'ksa-vehicle-backup_*.json' | Sort-Object Name -Descending | Select-Object -Skip $KeepCount)
  foreach ($f in $old) { Remove-Item $f.FullName -Force }

  if (Test-Path $FailFlag) { Remove-Item $FailFlag -Force }
  Write-Log ('백업 성공: {0} ({1} KB), 연도별 노드 {2}개, 이전 백업 {3}개 삭제' -f (Split-Path $file -Leaf), [math]::Round((Get-Item $file).Length / 1KB), $yearParts.Count, $old.Count)
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
