phantom.injectJs('json_sans_eval.js');
phantom.injectJs('generic_functions.js');


my_settings.content = 'foobar';
my_settings.postid = 0;
my_settings.is_sent = false;
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-p' || system.args[i] == '-post') { my_settings.postid = system.args[i+1]; }
	//if(system.args[i] == '--' || system.args[i] == '-comment') { my_settings.content = system.args.slice([i+1]).join (' '); }
	if(system.args[i] == '--' || system.args[i] == '-comment') { my_settings.content = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━━┓');
		console.log('              ┃     HELP     ┃');
		console.log('──────────────┨ post comment ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Possible parameter: -p -u -v -d -h');
		console.log('');
		console.log('-p | -post <post-id>');
		console.log('           Tells the script wich post should be commented.');
		console.log('');
		console.log('-- | -comment <text>');
		console.log('           Tells the script what\'s the content.');
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
		var my_return_value = page.evaluate(function(my_postid,my_comment,my_baseurl) {
			var my_ajaxrequest = new XMLHttpRequest();
			my_ajaxrequest.open('POST',my_baseurl+'posts/'+my_postid+'/comments',false);
			my_ajaxrequest.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
			my_ajaxrequest.setRequestHeader('X-CSRF-Token', document.getElementsByName('csrf-token')[0].getAttribute('content'));
			my_ajaxrequest.send('{"text":"'+my_comment+'"}');
			
			//return 'POST '+post_value.join('&')+' to '+my_baseurl+'aspect_memberships.json'+"\n\n"+'status: '+my_ajaxrequest.status+' '+my_ajaxrequest.statusText+"\n\n"+my_ajaxrequest.responseText;
			return my_ajaxrequest.status;
		},my_settings.postid,my_settings.content,my_settings.base_url);
		
		console.log (my_return_value);
		phantom.exit();
	}
};


page.open(my_settings.base_url+'stream');
//page.open(my_settings.base_url+'posts/'+my_settings.postid+'.json');
