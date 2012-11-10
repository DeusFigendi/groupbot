phantom.injectJs('json_sans_eval.js');
phantom.injectJs('generic_functions.js');

if (my_settings.verboselevel > 0) {
	console.log('Start Script, checking parameter');
}

my_settings.searchstring = 0;
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-u' || system.args[i] == '-user') { my_settings.searchstring = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-d' || system.args[i] == '-demeter') { my_settings.outputdemeter = new Array(system.args[i+1],system.args[i+2],system.args[i+3],system.args[i+4]); }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━┓');
		console.log('              ┃   HELP   ┃');
		console.log('──────────────┨ get user ┠──────────────');
		console.log('              ┗━━━━━━━━━━┛');
		console.log('');
		console.log('Searches for an user.');
		console.log('');
		console.log('Possible parameter: -u -v -d -h');
		console.log('');
		console.log('-u | -user <searchstring>');
		console.log('           Searchstring to find a user, usually the diaspora-handle');
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

if (my_settings.verboselevel > 0) {
	console.log('parameter checked, defining onLoad-callback');
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
			console.log('"Stream" found, loading default of this script...'+my_settings.base_url+'people.json?utf8=%E2%9C%93&q='+my_settings.searchstring);
		}
		page.open(my_settings.base_url+'people.json?utf8=%E2%9C%93&q='+my_settings.searchstring);
	} else if (pageadress.match(/\/people.json.+$/)){
		if (my_settings.verboselevel > 0) {
			console.log('got answer...'+stripHTML(pagecontent));
		}
		var content_object = jsonParse(stripHTML(pagecontent));
		
		var output_string='';
		for (var i in content_object) {
			output_string = my_settings.outputdemeter[0];
			output_string += content_object[i]['id'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			output_string += content_object[i]['guid'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			//output_string += content_object[i]['name'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += content_object[i]['name'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			//output_string += content_object[i]['handle'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += content_object[i]['handle'];
			output_string += my_settings.outputdemeter[1];
			output_string += my_settings.outputdemeter[0];
			//output_string += content_object[i]['avatar'].replace(replacer0,my_settings.outputdemeter[2]).replace(replacer1,my_settings.outputdemeter[3]);
			output_string += content_object[i]['avatar'];
			output_string += my_settings.outputdemeter[1];
			console.log(output_string);
		}
		phantom.exit();
	}
	
};

if (my_settings.verboselevel > 0) {
	console.log('onLoad done, loading the page...');
}

page.open(my_settings.base_url+'people.json?utf8=%E2%9C%93&q='+my_settings.searchstring);




// https://pod.orkz.net/people.json?utf8=%E2%9C%93&q=+faldrian%40pod.geraspora.de
// [{"id":808,"guid":"b956d9ae7b03c4ff","name":"Faldrian","avatar":"https://pod.geraspora.de/uploads/images/thumb_medium_2261d6a836108025ba66.jpg","handle":"faldrian@pod.geraspora.de","url":"/people/b956d9ae7b03c4ff"}]

// https://pod.orkz.net/people.json?utf8=%E2%9C%93&q=Faldrian
// [{"id":808,"guid":"b956d9ae7b03c4ff","name":"Faldrian","avatar":"https://pod.geraspora.de/uploads/images/thumb_medium_2261d6a836108025ba66.jpg","handle":"faldrian@pod.geraspora.de","url":"/people/b956d9ae7b03c4ff"},{"id":11580,"guid":"6d7d8b32f3f44ff8","name":"Faldrian","avatar":"https://pixelbits.de/photo/custom/100/9.jpg","handle":"faldrian@pixelbits.de","url":"/people/6d7d8b32f3f44ff8"}]

// https://pod.orkz.net/people.json?q=faldrian@pod.geraspora.de
// [{"id":808,"guid":"b956d9ae7b03c4ff","name":"Faldrian","avatar":"https://pod.geraspora.de/uploads/images/thumb_medium_2261d6a836108025ba66.jpg","handle":"faldrian@pod.geraspora.de","url":"/people/b956d9ae7b03c4ff"}]
