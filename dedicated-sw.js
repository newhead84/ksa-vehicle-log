// KSA 전용차량 입력 페이지 전용 서비스워커 (최소 기능)
// 목적: Chrome/Android 등에서 "홈 화면에 추가/설치" 기능이 동작하기 위한 최소 요건 충족.
// 운행정보는 항상 Firebase 최신 상태를 반영해야 하므로 별도 오프라인 캐싱은 하지 않는다(네트워크 그대로 통과).
// 적용 범위: dedicated-driver-input.html 등록 시 scope를 해당 페이지 경로로 한정하므로
//           공용차량 시스템(index.html)이나 전용차량 관리자 대시보드에는 영향을 주지 않는다.

const SW_VERSION = 'ded-driver-sw-v1';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  // 캐싱 없이 네트워크로 그대로 전달(pass-through)
  event.respondWith(fetch(event.request));
});
