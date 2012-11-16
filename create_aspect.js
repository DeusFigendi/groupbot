/*  Groupbots phantomjs-modules provide several functions to do stuff
    with an diaspora account. This file creates new aspects.
    Copyright (C) 2012  Deus Figendi

    Groupbot is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Groupbot is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
		console.log("Groupbot  Copyright (C) 2012  Deus Figendi");
		console.log("This program comes with ABSOLUTELY NO WARRANTY;");
		console.log("This is free software, and you are welcome to redistribute it");
		console.log("under certain conditions;");
		console.log(" ");
		phantom.exit(1);
	}
}


//publisher_textarea_wrapper
page.onLoadFinished = function () {
	var pagetitle   = getPageTitle(page);
	var pagecontent = page.content;
	var pageadress  = getPageuri(page);
	if (my_settings.verboselevel > 0) {
		//console.log(pagecontent);
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
		//if (my_settings.verboselevel > 0) {
//			console.log('creating aspect '+my_aspect);
		//}
		page.evaluate(function(my_aspect) {
			document.getElementById('aspect_name').value = my_aspect;
			document.getElementById('aspect_name').form.submit();			
		},my_settings.aspectname);
		
	} else if (pageadress.match(/\/contacts\?a_id\=\d+$/)){
		console.log(pageadress.match(/\/contacts\?a_id\=(\d+)$/)[1]);
		phantom.exit();
	} else {
		if (my_settings.verboselevel > 0) {
			console.log('unknown state');
		}
	}
};

page.open(my_settings.base_url+'aspects/new');
