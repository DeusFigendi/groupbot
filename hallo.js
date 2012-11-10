page = require('webpage').create();
page.settings.loadImages = false;

my_settings = new Object();
my_settings.base_url = 'https://pod.orkz.net/';
my_settings.loginname = 'groupbot';
my_settings.loginpass = 'p6Y8Hsg3X8dgnvqq';
globalcounter = 0;
my_action = 0;

guid_array = new Object();

phantom.injectJs('json_sans_eval.js');

page.onConsoleMessage = function (msg) { console.log('## '+msg); };
noch
page.onLoadFinished = function () {	
    console.log('~ ...loaded ('+globalcounter+')');
}
page.onLoadStarted = function () {
	globalcounter++;
    console.log('~ Start loading...');
};

function getPageTitle(webpageobject) {
    var pagetitle = webpageobject.evaluate(function () {
        return document.title;
    });
    
    return pagetitle
}

function getPageuri(webpageobject) {
    var pagetitle = webpageobject.evaluate(function () {
        return document.URL;
    });
    
    return pagetitle
}

function signin(webpageobject,this_settings) {
	webpageobject.evaluate(function(this_settings) {
		document.getElementById('user_username').value = this_settings.loginname;
		document.getElementById('user_password').value = this_settings.loginpass;
		document.getElementById('new_user').submit();
	},this_settings);
}

function dosomething() {
	var pagetitle = getPageTitle(page);
	var pageurl = getPageuri(page);
	if (pagetitle.match(/Sign\sin/)) {
		console.log('~ Sign in -page, signing in...');
		signin(page,my_settings);
	} else if (pagetitle.match(/DIASPORA\*/) || pagetitle == '') {
		//any usual content-page, let's check what kind an do something
		console.log('~ some usual content-page, checking for action...');
		if (my_action == 0) { // 0 = nothing to do, crawl around
			console.log('~ Action is "idle" (0), checking for URL...');
			if (pageurl.match(/\/(stream|\#)?(.json)?$/)) {
				//no action and on stream, nothing to do but hit some
				//             button like /mention or /conversations
				console.log('~ Stream...');
				if (Math.random() < 0.5) {
					console.log('~ ...calling mentions');
					page.open(my_settings.base_url+'mentions.json');
				} else {
					console.log('~ ...calling conversations');
					page.open(my_settings.base_url+'conversations.json');
				}
			} else if (pageurl.match(/\/mentions(.json)?$/)) {
				//no action is set and mentions-page is open, let's
				//     check if there are any commands since last check.
				console.log('~ mentions-json found, parsing...');
				var pure_json = page.content;
				pure_json = pure_json.slice(+pure_json.indexOf('['),pure_json.lastIndexOf(']')+1);
				var mention_object = jsonParse(pure_json);
				console.log('~ ...parsed');
				console.log('~ mentions-page ('+typeof(mention_object)+' '+mention_object.length+')');
				//okay, json is parsed now, we can check if the command
				//               was handled allready and if not do so.
				for (var message_no in mention_object) {
					if (checkguid(mention_object[message_no].guid)) {
						create_job_frum_mention(mention_object[message_no]);
					}
				}
				phantom.exit();
			} else if (pageurl.match(/\/conversations(.json)?$/)) {
				//no action is set and mentions-page is open, let's
				//     check if there are any commands since last check.
				console.log('~ conversations-json found, parsing...');
				var pure_json = page.content;
				pure_json = pure_json.slice(+pure_json.indexOf('['),pure_json.lastIndexOf(']')+1);
				var conversations_object = jsonParse(pure_json);
				console.log('~ ...parsed');
				console.log('~ conversations-page ('+typeof(conversations_object)+' '+conversations_object.length+')');
				//okay, json is parsed now, we can check if the command
				//               was handled allready and if not do so.
				for (var message_no in conversations_object) {
					if (checkguid(conversations_object[message_no].conversation.guid)) {
						create_job_frum_conversation(conversations_object[message_no].conversation);
					}
				}
			} else {
				console.log('~ Erm okay, action is zero but the pageURL ('+pageurl+') does not match anything');
			}
		} else {
			console.log('~ unknown action: '+my_action);
		}
		
	} else {
		console.log(pagetitle);	
	}
    //phantom.exit();
}

function create_job_frum_mention(mention_object) {
	//check what type of job
	var firstline = mention_object.text.match(/^[^\n\r]*/);
	firstline = new String(firstline).replace(/@\{[^\}]+\}/,'');
	if (firstline.match(/create\s+\w+/)) {
		//user tries to create a new group
	} else if (firstline.match(/(subscribe|join)\s+\w+/)) {
		//user tries to join a group
	} else if (firstline.match(/(unsubscribe|leave|part)\s+\w+/)) {
		//user tries to leave a group
	} else if (firstline.match(/(@\s|send\s|#)\w+/)) {
		//user tires to send a message to a group
	} else {
		//no match, error
	}
	console.log('~~ '+firstline);
}
function create_job_frum_conversation(conversation_object) {
	console.log('~~ bar');
}

function checkguid(this_guid) {
	console.log('~~ checking guid '+this_guid+' ...');
	if (typeof(guid_array[this_guid]) == 'undefined') {
		console.log('~~ ... guid not found, creating.');
		guid_array[this_guid] = true;
		return true;
	} else {
		console.log('~~ ... guid found');
		return false;
	}
}

window.setInterval('dosomething();',5000);

page.open(my_settings.base_url+'users/sign_in');
