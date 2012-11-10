phantom.injectJs('json_sans_eval.js');
phantom.injectJs('generic_functions.js');

//sorting parameter…
my_settings.action = 'stream';
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-a' || system.args[i] == '-action') { my_settings.action = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-d' || system.args[i] == '-demeter') { my_settings.outputdemeter = new Array(system.args[i+1],system.args[i+2],system.args[i+3],system.args[i+4]); }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━━━━┓');
		console.log('              ┃       HELP     ┃');
		console.log('──────────────┨ get streamlike ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Returns posts of a given stream-like page.');
		console.log('');
		console.log('Possible parameter: -a -v -d -h');
		console.log('');
		console.log('-a | -action <action>');
		console.log('           Tells the script what type of content it should get. Possible');
		console.log('           values are stream, mentions, followed_tags, aspects, activity.');
		console.log('           Default is stream.');
		console.log('');
		console.log('-v | -verbose');
		console.log('           Makes the script telling you what it is doing.');
		console.log('');
		console.log('-d | -demeter <d1> <d2> <r1> <r2>');
		console.log('           Defines what type of character(s) should be used to demeter');
		console.log('           data-fields in output. The replacements r1 and r2 replace the d1');
		console.log('           and d2 if it is in the data itself.');
		console.log('           Default is: d1=" d2=" r1=» r2=«');
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
	var targetRegExp = new RegExp();
	if (pagetitle.match(/Sign\sin/)) {
		if (my_settings.verboselevel > 0) {
			console.log('sign-in page, signing in...');
		}
		signin(page,my_settings);
	} else if (stripHTML(pagecontent) == '{"error":"You need to sign in or sign up before continuing."}') {
		if (my_settings.verboselevel > 0) {
			console.log ('Not loged in, loading login page');
		}
		page.open(my_settings.base_url+'users/sign_in');
	} else if (pageadress.match(/\/stream\/?$/)){
		if (my_settings.verboselevel > 0) {
			console.log('"Stream" found, loading default of this script...'+my_settings.base_url+my_settings.action+'.json');
		}
		page.open(my_settings.base_url+my_settings.action+'.json');
	} else {
		if (my_settings.verboselevel > 0) {
			console.log('unbekannter Zustand... vermutlich Zielzustand...');
		}
		//console.log(stripHTML(pagecontent));
		var output_string = '';
		var replacer0 = new RegExp(my_settings.outputdemeter[0]);
		var replacer1 = new RegExp(my_settings.outputdemeter[1]);
		var content_object = jsonParse(stripHTML(pagecontent));
		for (var i in content_object) {
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['id'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['guid'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['text'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['author']['id'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['author']['guid'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['author']['name'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['author']['diaspora_id'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['author']['avatar']['small'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += my_settings.outputdemeter[1];
			console.log(output_string);
		}
		if (my_settings.verboselevel > 0) {
			console.log('3');
			console.log(pageadress);
		}
		phantom.exit();
	}
	if (my_settings.verboselevel > 0) {
		console.log('/loaded');	
	}
}

page.open(my_settings.base_url+my_settings.action+'.json');
