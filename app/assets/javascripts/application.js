// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

;(function($){

	/* On the FAQ page, opens the right accordion item if the ID of the question is passed as the hash */
	/* This can only be done through the front-end, as the hash is never passed to the server. */
	$(document).ready(function(){
		if ($('article#faq').length != 0) {
			var hash = window.location.hash.substring(1);
			$('#'+hash).addClass("in").css('height', 'auto');
		}
	});

}( jQuery ));