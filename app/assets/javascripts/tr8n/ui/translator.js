/****************************************************************************
  Copyright (c) 2013 Michael Berkovich, tr8nhub.com

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
****************************************************************************/

Tr8n.UI.Translator = {
  options: {},
  translation_key_id: null,
  suggestion_tokens: null,
  container_width: 400,
  container_origin: null,
  click_coords: null,
  container_min_size: {height: 70, width: 400},
  container: null,
  stem_image: null, 
  content_frame: null,
  resize_control: null,
  move_control: null,
  drag_event: null,

  init: function() {
    var self = this;

    Tr8n.Utils.addEvent(document, Tr8n.Utils.isOpera() ? 'click' : 'contextmenu', function(e) {
      if (Tr8n.Utils.isOpera() && !e.ctrlKey) return;

      var translatable_node = Tr8n.Utils.findElement(e, ".tr8n_translatable");
      var language_case_node = Tr8n.Utils.findElement(e, ".tr8n_language_case");

      var link_node = Tr8n.Utils.findElement(e, "a");

      if (translatable_node == null && language_case_node == null) return;

      // We don't want to trigger links when we right-mouse-click them
      if (link_node) {
        var temp_href = link_node.href;
        var temp_onclick = link_node.onclick;
        link_node.href='javascript:void(0);';
        link_node.onclick = void(0);
        setTimeout(function() { 
          link_node.href = temp_href; 
          link_node.onclick = temp_onclick; 
        }, 500);
      }

      if (e.stop) e.stop();
      if (e.preventDefault) e.preventDefault();
      if (e.stopPropagation) e.stopPropagation();

      if (language_case_node)
        self.show(e, language_case_node, true);
      else 
        self.show(e, translatable_node, false);

      return false;
    });
  },

  initContainer: function() {
    if (this.container) return;

    this.container                = document.createElement('div');
    this.container.className      = 'tr8n_translator';
    this.container.id             = 'tr8n_translator';
    this.container.style.display  = "none";
    this.container.style.width    = this.container_width + "px";

    this.stem_image = document.createElement('img');
    this.stem_image.src = Tr8n.host + '/assets/tr8n/top_left_stem.png';
    this.container.appendChild(this.stem_image);

    this.content_frame = document.createElement('iframe');
    this.content_frame.src = 'about:blank';
    this.content_frame.style.border = '0px';
    this.container.appendChild(this.content_frame);

    this.move_control = document.createElement('div');
//    this.move_control.style.backgroundColor = "red";
    this.move_control.style.position = "absolute";
    this.move_control.style.zIndex = "9999";
    this.move_control.style.cursor = "move";
    this.move_control.style.left = "0px";
    this.move_control.style.top = "0px";
    this.move_control.style.width = "350px";
    this.move_control.style.height = "30px";
    this.container.appendChild(this.move_control);
    Tr8n.Utils.addEvent(this.move_control, 'mousedown', this.initMoveDrag.bind(this));

    this.resize_control = document.createElement('div');
//    this.resize_control.style.backgroundColor = "red";
    this.resize_control.style.position = "absolute";
    this.resize_control.style.zIndex = "9999";
    this.resize_control.style.cursor = "se-resize";
    this.resize_control.style.right = "0px";
    this.resize_control.style.bottom = "0px";
    this.resize_control.style.width = "50px";
    this.resize_control.style.height = "50px";
    this.container.appendChild(this.resize_control);
    Tr8n.Utils.addEvent(this.resize_control, 'mousedown', this.initResizeDrag.bind(this));

    Tr8n.Utils.addEvent(document.documentElement, 'mousemove', this.doDrag.bind(this));
    Tr8n.Utils.addEvent(document.documentElement, 'mouseup', this.stopDrag.bind(this));

    document.body.appendChild(this.container);
  },

  preventDefault: function(e) {
    if (e.stop) e.stop();
    if (e.preventDefault) e.preventDefault();
    if (e.stopPropagation) e.stopPropagation();
  },

  initMoveDrag: function(e) {
    this.drag_event = {type:'move', eventX: e.clientX, eventY: e.clientY, startX: parseInt(this.container.style.left), startY: parseInt(this.container.style.top)};
    this.preventDefault(e);
  },

  initResizeDrag: function(e) {
    this.drag_event = {type:'resize', eventX: e.clientX, eventY: e.clientY, startWidth: parseInt(this.container.style.width), startHeight: parseInt(this.container.style.height)};
    this.preventDefault(e);
  },

  doDrag: function(e) {
    if (this.drag_event == null) return;

    if (this.drag_event.type == 'resize') {
      if (this.drag_event.startHeight + e.clientY - this.drag_event.eventY > this.container_min_size.height) {
        this.container.style.height = (this.drag_event.startHeight + e.clientY - this.drag_event.eventY) + 'px';
      }

      if (this.drag_event.startWidth + e.clientX - this.drag_event.eventX > this.container_min_size.width) {
        this.container.style.width = (this.drag_event.startWidth + e.clientX - this.drag_event.eventX) + 'px';
      }

      this.content_frame.style.width = this.container.style.width;
      this.content_frame.style.height = this.container.style.height;
      this.container_width = parseInt(this.container.style.width);
      this.move_control.style.width = (this.container_width - 50) + "px";
    } else if (this.drag_event.type == 'move') {
      this.container.style.left = (this.drag_event.startX + e.clientX - this.drag_event.eventX) + 'px';
      this.container.style.top = (this.drag_event.startY + e.clientY - this.drag_event.eventY) + 'px';
    }
    this.preventDefault(e);
  },

  stopDrag: function(e) {
    this.drag_event = null;
    this.preventDefault(e);
  },

  hide: function() {
    if (!this.container) return;

    this.container.style.display = "none";
    this.content_frame.src = 'about:blank';
    Tr8n.Utils.showFlash();
  },

  mousePosition:  function(e) {
    var coords = {x: 0, y: 0};
    if (e.pageX || e.pageY) 	{
        coords.x = e.pageX;
        coords.y = e.pageY;
    } else if (e.clientX || e.clientY) 	{
        coords.x = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
        coords.y = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }
    return coords;
  },

  show: function(event, translatable_node, is_language_case) {
    this.initContainer();

    var self = this;
    Tr8n.UI.LanguageSelector.hide();
    Tr8n.UI.Lightbox.hide();
    Tr8n.Utils.hideFlash();

    var stem = {v: "top", h: "left", width: 10, height: 12};
    var label_rect = Tr8n.Utils.elementRect(translatable_node);
    this.click_coords = this.mousePosition(event);

    this.container_origin = {left: this.click_coords.x - 60, top: (label_rect.top + label_rect.height + stem.height)};
    var stem_offset = 60;

    if (this.click_coords.x > window.innerWidth / 2) {
      this.container_origin.left = this.container_origin.left - this.container_width + 120;
      stem.h = "right";
    }

    this.stem_image.className = 'stem ' + stem.v + "_" + stem.h;
    
    if (stem.h == 'left') {
      this.stem_image.style.left = stem_offset + 'px';
      this.stem_image.style.right = '';
    } else {
      this.stem_image.style.right = stem_offset + 'px';
      this.stem_image.style.left = '';
    }

    window.scrollTo(label_rect.left, label_rect.top - 100);

    this.container.style.left     = this.container_origin.left + "px";
    this.container.style.top      = this.container_origin.top + "px";
    this.container.style.display  = "block";

    var url = '';
    self.translation_key_id = translatable_node.getAttribute('data-translation_key_id');   // switch to data

    var params = {};

    if (is_language_case) {
      params = {
        type: 'language_case',
        case_id:  translatable_node.getAttribute('data-case_id'),
        rule_id:  translatable_node.getAttribute('data-rule_id'),
        case_key: translatable_node.getAttribute('data-case_key')
      }
    } else {
      params = {
        type: 'translator',
        id: self.translation_key_id
      }
    }

    this.content_frame.style.width = '100%';
    this.content_frame.style.height = '10px';
    this.content_frame.src = Tr8n.Utils.toUrl('/tr8n/tools/translator/splash_screen', params);
  },

  resize: function(size) {
    if (size.width != null) {
      this.content_frame.style.width = size.width + 'px';
      this.container.style.width = size.width + 'px';
//      alert(this.container_width + " " + size.width);
      if (this.click_coords.x > window.innerWidth / 2 && this.container_width != size.width) {
        if (this.container_width < size.width)
          this.container_origin.left  = this.container_origin.left - (size.width/2) + 100;
        else
          this.container_origin.left  = this.container_origin.left + (size.width/2);

        this.container.style.left   = this.container_origin.left + "px";
      }
      this.container_width = size.width;
      this.move_control.style.width = (this.container_width - 50) + "px";
    }
    if (size.height != null) {
      this.content_frame.style.height = size.height + 'px';
      this.container.style.height = size.height + 'px';
    }
  }

}
