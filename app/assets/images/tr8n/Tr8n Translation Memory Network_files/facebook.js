/* Facebook Login And Forward Support */


var fb_session_ready_url = null;
var fb_status = null;
var fb_session = null;
var fb_scope = null;

function fbRequireSession() {
  FB.login(function(response) {
    if (response.authResponse) {
      // alert(response.scope);
      fbOnSessionReadyCallback();
    } else {
      fbOnSessionCanceledCallback();
    }
  }, {scope:"email"});
}

function fbOnSessionReadyCallback() {
  if (fb_session_ready_url != null) {
    window.location = fb_session_ready_url;
  }  
}

function fbOnSessionCanceledCallback() {
  fb_session_ready_url = null;
}

function fbLoginAndForward(source, forward_to) {
  fb_session_ready_url = "/facebook/login_and_forward?source=" + source + "&forward_to=" + forward_to;
  fbRequireSession();
}

function fbAutoLoginAndForward(source, forward_to) {
  window.location = "/facebook/login_and_forward?source=" + source + "&forward_to=" + forward_to;
}

function fbLinkAndForward(source, forward_to) {
  fb_session_ready_url = "/facebook/link_and_forward?source=" + source + "&forward_to=" + forward_to;
	if (fbConnected()) {
		 window.location = fb_session_ready_url;
	} else {
	  fbRequireSession();
	}
}

function fbCallGraphApi(params, callback) {
	FB.api(params, callback);
}

function fbConnected() {
  return (fb_status == "connected");	
}

function fbNotConnected() {
  return (fb_status == "notConnected");  
}

function fbUnknown() {
  return (fb_status == "unknown");  
}

/* Newsfeed Stories Support */

function fbPromptNewsfeedStory() {
  
}
;
