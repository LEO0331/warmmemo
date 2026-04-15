{{flutter_js}}
{{flutter_build_config}}

(function bootstrapWarmMemo() {
  const loader = document.getElementById('wm-loader');
  const note = document.getElementById('wm-loader-note');

  const setNote = (text) => {
    if (note) {
      note.textContent = text;
    }
  };

  const hideLoader = () => {
    if (!loader) return;
    loader.classList.add('hidden');
    window.setTimeout(() => loader.remove(), 260);
  };

  window.setTimeout(() => {
    setNote('首次載入較慢屬正常，系統會快取後續資源。');
  }, 3500);

  const isChromiumLike =
      navigator.userAgent.includes('Chrome/') ||
      navigator.userAgent.includes('Edg/');
  const loaderConfig = {
    useLocalCanvasKit: true,
  };
  if (isChromiumLike) {
    loaderConfig.canvasKitVariant = 'chromium';
  }

  _flutter.loader.load({
    config: loaderConfig,
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
    onEntrypointLoaded: async (engineInitializer) => {
      setNote('即將完成，正在啟動 WarmMemo...');
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      hideLoader();
    },
  }).catch((error) => {
    console.error('WarmMemo bootstrap failed:', error);
    setNote('載入失敗，請重新整理頁面後再試。');
  });
})();
