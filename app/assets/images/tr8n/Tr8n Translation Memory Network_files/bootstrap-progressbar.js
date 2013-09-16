!function ($) {

	var ProgressBar = function (element, options) {
		this.element = $(element);
		this.position = 0;
		this.percent = 0;

		var hasOptions = typeof options == 'object';

		this.successMarker = $.fn.progressbar.defaults.successMarker;
		if (hasOptions && typeof options.successMarker == 'number') {
			this.setSuccessMarker(options.successMarker);
		}

		this.progressMarker = $.fn.progressbar.defaults.progressMarker;
		if (hasOptions && typeof options.progressMarker == 'number') {
			this.setProgressMarker(options.progressMarker);
		}

		this.maximum = $.fn.progressbar.defaults.maximum;
		if (hasOptions && typeof options.maximum == 'number') {
			this.setMaximum(options.maximum);
		}

		this.step = $.fn.progressbar.defaults.step;
		if (hasOptions && typeof options.step == 'number') {
			this.setStep(options.step);
		}

		this.element.html($(DRPGlobal.template));
	};

	ProgressBar.prototype = {
		constructor: ProgressBar,

		stepIt: function () {
			if (this.position < this.maximum)
				this.position += this.step;

			this.setPosition(this.position);
		},

		setProgressMarker: function (marker) {
			marker = parseInt(marker);
			if (marker > this.successMarker) {
				this.progressMarker = this.successMarker;
				return;
			}

			this.progressMarker = marker;
		},

		setSuccessMarker: function (marker) {
			this.successMarker = parseInt(marker);
		},

		setMaximum: function (maximum) {
			this.maximum = parseInt(maximum);
		},

		setStep: function (step) {
			step = parseInt(step);
			if (step <= 0)
				step = 1;

			this.step = parseInt(step);
		},

		setPosition: function (position) {
			position = parseInt(position);
			if (position < 0)
				position = 0;
			if (position > this.maximum)
				position = this.maximum;

			this.position = position;
			this.percent = Math.ceil((this.position / this.maximum) * 100);

      this.element.find('.bar-value').text(this.percent + '%');

		    try {
			    if (this.percent <= this.progressMarker) {
				    this.element.find('.bar-danger').css('width', this.percent + "%");
				    this.element.find('.bar-warning').css('width', "0%");
				    this.element.find('.bar-success').css('width', "0%");
				    return;
			    }

			    this.element.find('.bar-danger').css('width', this.progressMarker + "%");
			    if (this.percent > this.progressMarker && this.percent <= this.successMarker) {
				    this.element.find('.bar-warning').css('width', (this.percent - this.progressMarker) + "%");
				    this.element.find('.bar-success').css('width', "0%");
				    return;
			    }

			    this.element.find('.bar-warning').css('width', (this.successMarker - this.progressMarker) + "%");
			    this.element.find('.bar-success').css('width', (this.percent - this.successMarker) + "%");

		    } finally {
		        this._triggerPositionChanged();
		    }
		},

		reset: function () {
			this.position = 0;
			this.percent = 0;
			this._triggerPositionChanged();
			this.element.find('.bar-danger').css('width', "0%");
			this.element.find('.bar-warning').css('width', "0%");
			this.element.find('.bar-success').css('width', "0%");
		},

		_triggerPositionChanged: function () {
			this.element.trigger({
				type: "positionChanged",
				position: this.position,
				percent: this.percent
			});
		}
	};

	$.fn.progressbar = function (option) {
		var args = Array.apply(null, arguments);
		args.shift();
		return this.each(function () {
			var $this = $(this),
				data = $this.data('progressbar'),
				options = typeof option == 'object' && option;

			if (!data) {
				$this.data('progressbar', new ProgressBar(this, $.extend({}, $.fn.progressbar().defaults, options)));
			}
			if (typeof option == 'string' && typeof data[option] == 'function') {
				data[option].apply(data, args);
			}
		});
	};

	$.fn.progressbar.defaults = {
		progressMarker: 70,
		successMarker: 85,
		maximum: 100,
		step: 1
	};

	$.fn.progressbar.Constructor = ProgressBar;

	var DRPGlobal = {};

	DRPGlobal.template = '<div class="progress">' +
             '<div class="bar bar-danger" style="width: 0%;"></div>' +
             '<div class="bar bar-warning" style="width: 0%;"></div>' +
						 '<div class="bar bar-success" style="width: 0%;"></div>' +
             '<div class="bar bar-value" style="color:white;margin-left:-35px;"></div>' +
						 '</div>';

} (window.jQuery);
