/* Registrasi Service Worker + tombol "Pasang Aplikasi" (Android/Chrome) + petunjuk iPhone */
(function () {
  'use strict';
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
      navigator.serviceWorker.register('/sw.js').catch(function () {});
    });
  }

  var standalone = window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
  if (standalone) return;

  var KEY = 'mgmp_install_dismissed', WEEK = 7 * 864e5;
  function dismissed() {
    try { var t = +localStorage.getItem(KEY) || 0; return Date.now() - t < WEEK; } catch (e) { return false; }
  }
  function remember() { try { localStorage.setItem(KEY, String(Date.now())); } catch (e) {} }

  var bar = null;
  function show(html, onOk) {
    if (bar || dismissed()) return;
    bar = document.createElement('div');
    bar.setAttribute('role', 'dialog');
    bar.style.cssText = 'position:fixed;left:12px;right:12px;bottom:calc(12px + env(safe-area-inset-bottom,0px));' +
      'z-index:2147483600;max-width:460px;margin:0 auto;background:#fff;color:#0f1d3a;border-radius:16px;' +
      'box-shadow:0 12px 40px rgba(0,20,85,.35);border:1px solid #cdd9ee;padding:12px 14px;display:flex;' +
      'gap:12px;align-items:center;font:600 13px/1.4 "Plus Jakarta Sans",system-ui,sans-serif';
    bar.innerHTML = '<img src="/icons/icon-192.png" alt="" width="40" height="40" style="border-radius:10px;flex:none">' +
      '<div style="flex:1;min-width:0">' + html + '</div>';
    if (onOk) {
      var ok = document.createElement('button');
      ok.textContent = 'Pasang';
      ok.style.cssText = 'border:0;background:linear-gradient(135deg,#0147ac,#001455);color:#fff;font:700 13px inherit;' +
        'padding:9px 16px;border-radius:10px;cursor:pointer;flex:none';
      ok.onclick = function () { onOk(); };
      bar.appendChild(ok);
    }
    var x = document.createElement('button');
    x.setAttribute('aria-label', 'Tutup');
    x.textContent = '\u2715';
    x.style.cssText = 'border:0;background:transparent;color:#64748b;font-size:16px;cursor:pointer;flex:none;padding:4px';
    x.onclick = function () { remember(); hide(); };
    bar.appendChild(x);
    document.body.appendChild(bar);
  }
  function hide() { if (bar) { bar.remove(); bar = null; } }

  // Android / Chrome / Edge
  var deferred = null;
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferred = e;
    show('Pasang <b>Portal MGMP</b> di layar utama agar terbuka seperti aplikasi.', function () {
      if (!deferred) return;
      deferred.prompt();
      deferred.userChoice.finally(function () { deferred = null; hide(); });
    });
  });
  window.addEventListener('appinstalled', function () { hide(); deferred = null; });

  // iPhone / iPad (Safari tidak punya tombol pasang otomatis)
  var ua = navigator.userAgent;
  var isIOS = /iphone|ipad|ipod/i.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var isSafari = /safari/i.test(ua) && !/crios|fxios|edgios/i.test(ua);
  if (isIOS && isSafari) {
    setTimeout(function () {
      show('Untuk memasang: ketuk tombol <b>Bagikan</b> (\u2B06\uFE0F) lalu pilih <b>Tambah ke Layar Utama</b>.', null);
      setTimeout(hide, 15000);
    }, 2500);
  }
})();
