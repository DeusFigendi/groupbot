phantom.injectJs('json_sans_eval.js');
phantom.injectJs('generic_functions.js');


my_settings.method = 'ADD';
my_settings.userid = 0;
my_settings.aspectid = 0;
my_settings.is_sent = false;
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-a' || system.args[i] == '-aspect') { my_settings.aspectid = system.args[i+1]; }
	if(system.args[i] == '-u' || system.args[i] == '-user') { my_settings.userid = system.args[i+1]; }
	if(system.args[i] == '-m' || system.args[i] == '-method') { my_settings.method = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━━━━━━━━━┓');
		console.log('              ┃         HELP        ┃');
		console.log('──────────────┨ change users aspect ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Possible parameter: -a -u -v -d -h');
		console.log('');
		console.log('-a | -aspect <aspect-id>');
		console.log('           Tells the script wich aspect should be added or removed.');
		console.log('           Possible values: ADD, POST, CREATE, _POST, DELETE, DEL, LEAVE,');
		console.log('                                                                   REMOVE');
		console.log('');
		console.log('-u | -user <user-id>');
		console.log('           Tells the script whos aspect should be added or removed.');
		console.log('');
		console.log('-m | -method <keyword>');
		console.log('           Tells the script if the aspect should be ADD or REMOVEd.');
		console.log('           Possible values: POST, CREATE, ADD, _POST');
		console.log('');
		console.log('-v | -verbose');
		console.log('           Makes the script telling you what it is doing.');
		console.log('');
		console.log('-h | --help | -help | ? | -? | --?');
		console.log('           Shows this help and terminate.');
		console.log('');
		phantom.exit(1);
	}
}

page.onLoadFinished = function () {
	var pagetitle   = getPageTitle(page);
	var pagecontent = page.content;
	var pageadress  = getPageuri(page);
	if (my_settings.verboselevel > 0) {
		console.log(pagetitle);
		console.log(pageadress);
	}
	
	if (pagetitle.match(/Sign\sin/)) {
		if (my_settings.verboselevel > 0) {
			console.log('sign-in page, signing in...');
		}
		signin(page,my_settings);
	} else if (pageadress.match(/\/stream\/?$/)){
		var my_return_value = page.evaluate(function(my_method,my_aspect,my_user,my_baseurl) {
			var post_value = new Array();
			var my_script_url = 'aspect_memberships.json';
			post_value.push('aspect_id='+my_aspect);
			post_value.push('person_id='+my_user);
			if (my_method.toLowerCase() == 'add' || my_method.toLowerCase() == 'post' || my_method.toLowerCase() == 'create' || my_method.toLowerCase() == '_post') {
				post_value.push ('_method=POST');
				my_script_url = 'aspect_memberships.json';
			} else if (my_method.toLowerCase() == 'delete' || my_method.toLowerCase() == 'leave' || my_method.toLowerCase() == 'remove' || my_method.toLowerCase() == 'del' ) {
				post_value.push ('_method=DELETE');
				my_script_url = 'aspect_memberships/42.json';
			}
			var my_ajaxrequest = new XMLHttpRequest();
			my_ajaxrequest.open('POST',my_baseurl+my_script_url,false);
			my_ajaxrequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
			my_ajaxrequest.setRequestHeader('X-CSRF-Token', document.getElementsByName('csrf-token')[0].getAttribute('content'));
			my_ajaxrequest.send(post_value.join('&'));
			
			//return 'POST '+post_value.join('&')+' to '+my_baseurl+'aspect_memberships.json'+"\n\n"+'status: '+my_ajaxrequest.status+' '+my_ajaxrequest.statusText+"\n\n"+my_ajaxrequest.responseText;
			return my_ajaxrequest.status;
		},my_settings.method,my_settings.aspectid,my_settings.userid,my_settings.base_url);
		
		console.log (my_return_value);
		phantom.exit();
	}
};


page.open(my_settings.base_url+'stream');
