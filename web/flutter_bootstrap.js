{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();

    // Chi an man hinh splash khi Flutter Engine va widget da mount xong
    const loader = document.getElementById('app-splash-loader');
    if (loader) {
      loader.style.opacity = '0';
      setTimeout(function() {
        loader.style.visibility = 'hidden';
        loader.remove();
      }, 350);
    }
  }
});
