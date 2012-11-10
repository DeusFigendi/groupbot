phantom.injectJs('json_sans_eval.js');
phantom.injectJs('generic_functions.js');


my_settings.aspectname = 'new';
my_settings.is_sent = false;
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-a' || system.args[i] == '-aspect') { my_settings.aspectname = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━━━┓');
		console.log('              ┃      HELP     ┃');
		console.log('──────────────┨ create aspect ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Returns the ID of the new aspect');
		console.log('');
		console.log('Possible parameter: -a -v -d -h');
		console.log('');
		console.log('-a | -aspect <aspect-name>');
		console.log('           Tells the script the name of the new aspect.');
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


//publisher_textarea_wrapper
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
		if (my_settings.verboselevel > 0) {
			console.log('stream page, joining aspect-creation');
		}		
		page.open(my_settings.base_url+'aspects/new');		
	} else if (pageadress.match(/\/aspects\/new\/?$/)){
		
		page.evaluate(function(my_aspect) {
			document.getElementById('aspect_name').value = my_aspect;
			document.getElementById('aspect_name').form.submit();			
		},my_settings.aspectname);
		
	} else if (pageadress.match(/\/contacts\?a_id\=\d+$/)){
		console.log(pageadress.match(/\/contacts\?a_id\=(\d+)$/)[1]);
		phantom.exit();
	}
};

page.open(my_settings.base_url+'aspects/new');
