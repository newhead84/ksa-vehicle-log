#!/usr/bin/env python3
"""
KSA 차량 운행정보 시스템 — 구글 캘린더 양방향 동기화
================================================================
GitHub Actions에서 주기적으로 실행됩니다(수동 실행도 가능).

방향1 (시스템→구글, Firebase가 원본):
  각 전용차량의 휴가 일정(vacationSchedule)을 회사 공용 구글 캘린더에
  종일(all-day) 이벤트로 반영합니다. 매 실행마다 "구글에 있는 우리 휴가
  이벤트 집합"과 "Firebase의 휴가 일정"을 비교해 생성/수정/삭제를
  자동으로 맞춥니다(상태를 별도 저장하지 않는 멱등적 재조정 방식).
  우리가 만든 이벤트는 extendedProperties.private에
  ksaVehiclePlate/ksaVehicleDate/ksaVehicleType 마커를 남겨 식별합니다.

  수행기사가 입력페이지에서 직접 등록하는 일반 일정(customEvents, 연차/반차 외
  회의·병원 등)도 동일한 방식(방향1)으로 반영됩니다. 휴가와 달리 날짜가 아닌
  이벤트 고유 id로 식별하며(다중일/시간 지정 일정 지원), 마커는
  ksaVehiclePlate/ksaVehicleEventId/ksaVehicleType('custom')을 사용합니다.

방향2 (구글→시스템, 구글이 원본):
  구글 캘린더의 일반 일정(위 마커가 없는 이벤트)을 읽어와
  Firebase(dedicated-fleet-data/googleCalendarEvents)에 캐싱합니다.
  화면(관리자 대시보드 등)에서 이 값을 읽어 참고용으로 표시할 수 있습니다.

Firebase 인증: 클라이언트 HTML이 쓰는 "브라우저 API 키 + 익명 로그인" 방식은
  API 키에 걸린 HTTP 리퍼러 제한(브라우저 요청만 허용) 때문에 서버(GitHub Actions)에서는
  차단됩니다. 이 스크립트는 대신 Firebase 서비스 계정(관리자 자격 증명)으로 인증하며,
  이는 보안 규칙 자체를 우회하는 서버 전용 자격 증명이라 브라우저 키와는 별개입니다.

필요한 GitHub Secrets:
  GCAL_CLIENT_ID, GCAL_CLIENT_SECRET, GCAL_REFRESH_TOKEN, FIREBASE_URL,
  FIREBASE_SERVICE_ACCOUNT_JSON (Firebase 콘솔 > 프로젝트 설정 > 서비스 계정에서 발급한 JSON 전체)
================================================================
"""

import os
import sys
import json
import datetime
import urllib.request
import urllib.parse
import urllib.error

from google.oauth2 import service_account
from google.auth.transport.requests import Request as GoogleAuthRequest

# ── 고정 설정 (하드코딩 값은 클라이언트 index.html/dedicated-*.html과 동일 — 공개 가능한 값) ──
DEDICATED_STORAGE_KEY = "dedicated-fleet-data"
CALENDAR_ID = os.environ.get("GCAL_CALENDAR_ID") or "primary"  # 별도 지정 없으면(빈 값 포함) 공용 계정의 기본 캘린더 사용

VACAL_LABEL = {"full": "연차", "am": "반차(오전)", "pm": "반차(오후)"}

VEHICLES = [
    {"key": "hoegjang", "plate": "177호1673", "driver": "이왕희"},
    {"key": "jeonmu1",  "plate": "222호7779", "driver": "이경근"},
    {"key": "jeonmu2",  "plate": "222호7780", "driver": "이동석"},
]

# 재조정(reconcile) 대상 기간: 과거 실수 정정도 반영하되, 오래된 과거 기록은 건드리지 않음
WINDOW_PAST_DAYS = 30
WINDOW_FUTURE_DAYS = 365
# 일반 일정(방향2) 캐싱 기간
GENERAL_WINDOW_PAST_DAYS = 1
GENERAL_WINDOW_FUTURE_DAYS = 60


def http_json(method, url, headers=None, body=None):
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        print(f"HTTP {e.code} 오류 ({method} {url}):\n{err_body}", file=sys.stderr)
        raise


# ── 인증 ──────────────────────────────────────────────────
def get_google_access_token():
    client_id = os.environ["GCAL_CLIENT_ID"]
    client_secret = os.environ["GCAL_CLIENT_SECRET"]
    refresh_token = os.environ["GCAL_REFRESH_TOKEN"]
    body = urllib.parse.urlencode({
        "client_id": client_id,
        "client_secret": client_secret,
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }).encode("utf-8")
    req = urllib.request.Request(
        "https://oauth2.googleapis.com/token", data=body, method="POST"
    )
    req.add_header("Content-Type", "application/x-www-form-urlencoded")
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read())
    return res["access_token"]


def get_firebase_admin_token():
    # 서비스 계정(관리자 자격 증명)으로 인증 — 보안 규칙을 우회하는 서버 전용 방식.
    # 클라이언트 HTML의 "익명 로그인"과는 별개이며, 브라우저 API 키의 리퍼러 제한과 무관하게 동작.
    sa_json = os.environ["FIREBASE_SERVICE_ACCOUNT_JSON"]
    info = json.loads(sa_json)
    creds = service_account.Credentials.from_service_account_info(
        info,
        scopes=[
            "https://www.googleapis.com/auth/firebase.database",
            "https://www.googleapis.com/auth/userinfo.email",
        ],
    )
    creds.refresh(GoogleAuthRequest())
    return creds.token


# ── Firebase RTDB ─────────────────────────────────────────
def fb_get(firebase_url, access_token, path):
    url = f"{firebase_url}/{path}.json?access_token={access_token}"
    try:
        return http_json("GET", url) or {}
    except urllib.error.HTTPError:
        return {}


def fb_put(firebase_url, access_token, path, value):
    url = f"{firebase_url}/{path}.json?access_token={access_token}"
    return http_json("PUT", url, body=value)


# ── Google Calendar API ───────────────────────────────────
def gcal_list_events(access_token, time_min, time_max, private_extended_property=None):
    params = {
        "singleEvents": "true",
        "timeMin": time_min,
        "timeMax": time_max,
        "maxResults": "2500",
        "orderBy": "startTime",
    }
    if private_extended_property:
        params["privateExtendedProperty"] = private_extended_property
    cal_id = urllib.parse.quote(CALENDAR_ID, safe="")
    url = f"https://www.googleapis.com/calendar/v3/calendars/{cal_id}/events?{urllib.parse.urlencode(params)}"
    events, page_token = [], None
    while True:
        u = url + (f"&pageToken={page_token}" if page_token else "")
        res = http_json("GET", u, headers={"Authorization": f"Bearer {access_token}"})
        events.extend(res.get("items", []))
        page_token = res.get("nextPageToken")
        if not page_token:
            break
    return events


def gcal_insert_event(access_token, event_body):
    cal_id = urllib.parse.quote(CALENDAR_ID, safe="")
    url = f"https://www.googleapis.com/calendar/v3/calendars/{cal_id}/events"
    return http_json("POST", url, headers={"Authorization": f"Bearer {access_token}"}, body=event_body)


def gcal_patch_event(access_token, event_id, event_body):
    cal_id = urllib.parse.quote(CALENDAR_ID, safe="")
    eid = urllib.parse.quote(event_id, safe="")
    url = f"https://www.googleapis.com/calendar/v3/calendars/{cal_id}/events/{eid}"
    return http_json("PATCH", url, headers={"Authorization": f"Bearer {access_token}"}, body=event_body)


def gcal_delete_event(access_token, event_id):
    cal_id = urllib.parse.quote(CALENDAR_ID, safe="")
    eid = urllib.parse.quote(event_id, safe="")
    url = f"https://www.googleapis.com/calendar/v3/calendars/{cal_id}/events/{eid}"
    req = urllib.request.Request(url, method="DELETE")
    req.add_header("Authorization", f"Bearer {access_token}")
    try:
        urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        if e.code != 410:  # 410 Gone = 이미 삭제됨(정상 취급)
            raise


def iso_date(d):
    return d.strftime("%Y-%m-%d")


# ── 방향1: 시스템(Firebase) → 구글 캘린더 ──────────────────
def sync_vacation_to_google(access_token, firebase_url, fb_token):
    today = datetime.date.today()
    time_min = iso_date(today - datetime.timedelta(days=WINDOW_PAST_DAYS)) + "T00:00:00Z"
    time_max = iso_date(today + datetime.timedelta(days=WINDOW_FUTURE_DAYS)) + "T00:00:00Z"

    created = updated = deleted = 0

    for v in VEHICLES:
        plate, driver = v["plate"], v["driver"]
        fb_path = f"{DEDICATED_STORAGE_KEY}/vehicles/{urllib.parse.quote(plate, safe='')}/vacationSchedule"
        vacation = fb_get(firebase_url, fb_token, fb_path) or {}
        vacation = {k: v2 for k, v2 in vacation.items() if isinstance(v2, dict) and v2.get("type") in VACAL_LABEL}

        gcal_events = gcal_list_events(
            access_token, time_min, time_max,
            private_extended_property=f"ksaVehiclePlate={plate}"
        )
        gcal_by_date = {}
        for ev in gcal_events:
            props = (ev.get("extendedProperties") or {}).get("private") or {}
            d = props.get("ksaVehicleDate")
            if d:
                gcal_by_date[d] = ev

        # Firebase에 있는데 구글에 없거나 유형이 다르면 생성/수정
        for date_str, rec in vacation.items():
            vtype = rec.get("type")
            label = VACAL_LABEL.get(vtype, vtype)
            summary = f"[휴가] {rec.get('driver') or driver} · {label}"
            try:
                d = datetime.date.fromisoformat(date_str)
            except ValueError:
                continue
            end_date = iso_date(d + datetime.timedelta(days=1))
            event_body = {
                "summary": summary,
                "start": {"date": date_str},
                "end": {"date": end_date},
                "extendedProperties": {
                    "private": {
                        "ksaVehiclePlate": plate,
                        "ksaVehicleDate": date_str,
                        "ksaVehicleType": vtype,
                    }
                },
            }
            existing = gcal_by_date.get(date_str)
            if existing is None:
                gcal_insert_event(access_token, event_body)
                created += 1
            else:
                existing_type = ((existing.get("extendedProperties") or {}).get("private") or {}).get("ksaVehicleType")
                if existing_type != vtype or existing.get("summary") != summary:
                    gcal_patch_event(access_token, existing["id"], event_body)
                    updated += 1

        # 구글에는 있는데 Firebase에서 삭제된 날짜 → 이벤트 삭제
        for date_str, ev in gcal_by_date.items():
            if date_str not in vacation:
                gcal_delete_event(access_token, ev["id"])
                deleted += 1

    print(f"[방향1: 시스템→구글] 생성 {created}건, 수정 {updated}건, 삭제 {deleted}건")


# ── 방향1(확장): 시스템(Firebase customEvents) → 구글 캘린더 ──
# 수행기사가 입력페이지에서 직접 등록한 일반 일정(연차/반차 외). 휴가와 달리
# 이벤트 고유 id(ksaVehicleEventId)로 식별하며, 여러 날에 걸치거나 시간이 지정된
# 일정도 지원한다. 재조정 방식은 휴가 동기화와 동일(멱등적, 별도 상태 미저장).
def sync_custom_events_to_google(access_token, firebase_url, fb_token):
    today = datetime.date.today()
    time_min = iso_date(today - datetime.timedelta(days=WINDOW_PAST_DAYS)) + "T00:00:00Z"
    time_max = iso_date(today + datetime.timedelta(days=WINDOW_FUTURE_DAYS)) + "T00:00:00Z"

    created = updated = deleted = 0

    for v in VEHICLES:
        plate, driver = v["plate"], v["driver"]
        fb_path = f"{DEDICATED_STORAGE_KEY}/vehicles/{urllib.parse.quote(plate, safe='')}/customEvents"
        custom = fb_get(firebase_url, fb_token, fb_path) or {}
        custom = {k: v2 for k, v2 in custom.items() if isinstance(v2, dict) and v2.get("title") and v2.get("startDate")}

        gcal_events = gcal_list_events(
            access_token, time_min, time_max,
            private_extended_property=f"ksaVehiclePlate={plate}"
        )
        gcal_by_eventid = {}
        for ev in gcal_events:
            props = (ev.get("extendedProperties") or {}).get("private") or {}
            eid = props.get("ksaVehicleEventId")
            if eid:
                gcal_by_eventid[eid] = ev

        for event_id, rec in custom.items():
            start_date = rec.get("startDate")
            end_date = rec.get("endDate") or start_date
            all_day = rec.get("allDay") is not False
            title = rec.get("title")
            summary = f"[일정] {rec.get('driver') or driver} · {title}"
            try:
                s_d = datetime.date.fromisoformat(start_date)
                e_d = datetime.date.fromisoformat(end_date)
            except ValueError:
                continue

            if all_day:
                event_body = {
                    "summary": summary,
                    "start": {"date": start_date},
                    "end": {"date": iso_date(e_d + datetime.timedelta(days=1))},
                }
            else:
                start_time = rec.get("startTime") or "09:00"
                end_time = rec.get("endTime") or start_time
                event_body = {
                    "summary": summary,
                    "start": {"dateTime": f"{start_date}T{start_time}:00+09:00", "timeZone": "Asia/Seoul"},
                    "end": {"dateTime": f"{end_date}T{end_time}:00+09:00", "timeZone": "Asia/Seoul"},
                }
            event_body["extendedProperties"] = {
                "private": {
                    "ksaVehiclePlate": plate,
                    "ksaVehicleEventId": event_id,
                    "ksaVehicleType": "custom",
                }
            }

            existing = gcal_by_eventid.get(event_id)
            if existing is None:
                gcal_insert_event(access_token, event_body)
                created += 1
            else:
                ex_start = existing.get("start", {})
                ex_end = existing.get("end", {})
                changed = (
                    existing.get("summary") != summary
                    or ex_start.get("date") != event_body["start"].get("date")
                    or ex_start.get("dateTime") != event_body["start"].get("dateTime")
                    or ex_end.get("date") != event_body["end"].get("date")
                    or ex_end.get("dateTime") != event_body["end"].get("dateTime")
                )
                if changed:
                    gcal_patch_event(access_token, existing["id"], event_body)
                    updated += 1

        for event_id, ev in gcal_by_eventid.items():
            if event_id not in custom:
                gcal_delete_event(access_token, ev["id"])
                deleted += 1

    print(f"[방향1 확장: 내 일정→구글] 생성 {created}건, 수정 {updated}건, 삭제 {deleted}건")


# ── 방향2: 구글 캘린더 → 시스템(Firebase) ──────────────────
def sync_general_events_from_google(access_token, firebase_url, fb_token):
    today = datetime.date.today()
    time_min = iso_date(today - datetime.timedelta(days=GENERAL_WINDOW_PAST_DAYS)) + "T00:00:00Z"
    time_max = iso_date(today + datetime.timedelta(days=GENERAL_WINDOW_FUTURE_DAYS)) + "T00:00:00Z"

    all_events = gcal_list_events(access_token, time_min, time_max)
    general = []
    for ev in all_events:
        props = (ev.get("extendedProperties") or {}).get("private") or {}
        if props.get("ksaVehiclePlate"):
            continue  # 우리가 만든 휴가 이벤트는 제외(방향1에서 이미 관리)
        start = ev.get("start", {})
        end = ev.get("end", {})
        general.append({
            "id": ev.get("id"),
            "summary": ev.get("summary", "(제목 없음)"),
            "start": start.get("date") or start.get("dateTime"),
            "end": end.get("date") or end.get("dateTime"),
            "allDay": bool(start.get("date")),
        })

    fb_put(firebase_url, fb_token, f"{DEDICATED_STORAGE_KEY}/googleCalendarEvents", general)
    print(f"[방향2: 구글→시스템] 일반 일정 {len(general)}건 캐싱 완료")


def main():
    firebase_url = os.environ["FIREBASE_URL"]
    access_token = get_google_access_token()
    fb_token = get_firebase_admin_token()

    sync_vacation_to_google(access_token, firebase_url, fb_token)
    sync_custom_events_to_google(access_token, firebase_url, fb_token)
    sync_general_events_from_google(access_token, firebase_url, fb_token)


if __name__ == "__main__":
    main()
