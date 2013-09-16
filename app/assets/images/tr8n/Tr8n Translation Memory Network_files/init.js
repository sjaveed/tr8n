Tr8n.host = 'http://localhost:3000';

VKI_default_layout = '\u0420\u0443\u0441\u0441\u043a\u0438\u0439';

Tr8n.source = '/tr8n/app/settings/email_template';
Tr8n.default_locale = 'en-US';
Tr8n.app_key = 'default';


  Tr8n.page_locale = 'en-US';

Tr8n.locale = 'ru';

  Tr8n.google_api_key = 'AIzaSyBvL_IjAhFwoC2oixepTmju9UHZnZiA7YI';


shortcut.add('Ctrl+Shift+S', function() {
  Tr8n.UI.Lightbox.show('/tr8n/help/lb_shortcuts', {width:400});
});

shortcut.add('Ctrl+Shift+I', function() {
  Tr8n.UI.LanguageSelector.toggleInlineTranslations();
});

shortcut.add('Ctrl+Shift+L', function() {
  Tr8n.UI.LanguageSelector.show(true);
});

shortcut.add('Ctrl+Shift+N', function() {
  Tr8n.UI.Lightbox.show('/tr8n/translator/notifications/lb_notifications', {width:600});
});

shortcut.add('Ctrl+Shift+K', function() {
  Tr8n.Utils.toggleKeyboards();
});

shortcut.add('Ctrl+Shift+C', function() {
  Tr8n.UI.Lightbox.show('/tr8n/help/lb_source?source=' + Tr8n.source, {width:420});
});

shortcut.add('Ctrl+Shift+T', function() {
  Tr8n.UI.Lightbox.show('/tr8n/help/lb_stats', {width:420});
});

shortcut.add('Ctrl+Shift+D', function() {
  Tr8n.SDK.Proxy.debug();
});

shortcut.add('Alt+Shift+C', function() {
  window.location = Tr8n.host + '/tr8n/help/credits';
});

shortcut.add('Alt+Shift+D', function() {
  window.location = Tr8n.host + '/tr8n/translator/dashboard';
});

shortcut.add('Alt+Shift+M', function() {
  window.location = Tr8n.host + '/tr8n/app/sitemap';
});

shortcut.add('Alt+Shift+P', function() {
  window.location = Tr8n.host + '/tr8n/app/phrases';
});

shortcut.add('Alt+Shift+T', function() {
  window.location = Tr8n.host + '/tr8n/app/translations';
});

shortcut.add('Alt+Shift+A', function() {
  window.location = Tr8n.host + '/tr8n/app/awards';
});

shortcut.add('Alt+Shift+B', function() {
  window.location = Tr8n.host + '/tr8n/app/forum';
});

shortcut.add('Alt+Shift+G', function() {
  window.location = Tr8n.host + '/tr8n/app/glossary';
});

shortcut.add('Alt+Shift+H', function() {
  window.location = Tr8n.host + '/tr8n/help';
});

