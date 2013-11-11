// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require ./vendor/shortcut.js
//= require ./vendor/keyboard_1_49.js
//= require ./base.js
//= require ./dispatcher.js
//= require ./utils/base.js
//= require ./utils/effects.js
//= require ./utils/logger.js
//= require ./ui/base.js
//= require ./ui/lightbox.js
//= require ./ui/translator.js
//= require ./ui/language_selector.js
//= require ./ui/translation.js

window.Tr8n = window.$tr8n = Tr8n.Utils.extend(Tr8n, {
  element     : Tr8n.Utils.element,
  value       : Tr8n.Utils.value,
  log         : Tr8n.Utils.Logger.log
});

Tr8n.UI.init();
Tr8n.Dispatcher.init();



