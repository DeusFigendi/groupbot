/*  Groupbots phantomjs-modules provide several functions to do stuff
    with an diaspora account. This file loads all aspects within their
    IDs of a diaspora account OR all users in an aspect.
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

my_settings.aspectID = 0;
my_settings.verboselevel = 0;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-a' || system.args[i] == '-aspect') { my_settings.aspectID = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-d' || system.args[i] == '-demeter') { my_settings.outputdemeter = new Array(system.args[i+1],system.args[i+2],system.args[i+3],system.args[i+4]); }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━┓');
		console.log('              ┃     HELP    ┃');
		console.log('──────────────┨ get aspects ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Returns a list of aspects with their aspect-ID or all users in an aspect.');
		console.log('');
		console.log('Possible parameter: -a -v -d -h');
		console.log('');
		console.log('-a | -aspect <aspect id>');
		console.log('           Delivers all users of an aspect.');
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
		console.log("Groupbot  Copyright (C) 2012  Deus Figendi");
		console.log("This program comes with ABSOLUTELY NO WARRANTY;");
		console.log("This is free software, and you are welcome to redistribute it");
		console.log("under certain conditions;");
		console.log(" ");
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
		page.open(my_settings.base_url+'contacts');
	} else if (pageadress.match(/\/contacts\/?$/)){
		if (my_settings.verboselevel > 0) {
			console.log('contacts-page, collecting aspects…');
		}
		var aspect_array = page.evaluate(function() {
			if (document.getElementById('aspect_nav')) {
				var aspect_ul = document.getElementById('aspect_nav').getElementsByTagName('ul')[0];
				var return_object = new Array();
				var temp_value1 = 0;
				var temp_value2 = 0;
				for (var i = 0; i < aspect_ul.getElementsByTagName('li').length; i++) {
					temp_value1 = aspect_ul.getElementsByTagName('li')[i].getAttribute('data-aspect_id');
					if (temp_value1 != null) {							
						temp_value2 = aspect_ul.getElementsByTagName('li')[i].getElementsByTagName('a')[0].firstChild.data;
						//temp_value2 = 'foobar';
						return_object.push(new Array(temp_value1,temp_value2));
					}
				}
				return return_object;
			} else {
				return 0;
			}
		});
		if (my_settings.verboselevel > 0) {
			console.log('found '+aspect_array.length+' aspects:');
		}
		for (var i = 0; i < aspect_array.length; i++) {
			console.log(my_settings.outputdemeter[0]+aspect_array[i][0]+my_settings.outputdemeter[1]+my_settings.outputdemeter[0]+trim(aspect_array[i][1])+my_settings.outputdemeter[1]);
		}
			
		phantom.exit();
	} else if (pageadress.match(/\/contacts\?a_id\=\d+\/?$/)){
		if (my_settings.verboselevel > 0) {
			console.log('specified aspect... ');			
		}
		var user_array = page.evaluate(function() {
			var return_object = new Array();
			var temp_object = new Object();
			var user_divs = document.getElementById('people_stream');
			if (user_divs != null) {
				user_divs = user_divs.getElementsByTagName('div');
				for (var i = 0; i < user_divs.length; i++) {
					if (user_divs[i].id.match(/^\d+$/)) {
						temp_object = new Object();
						temp_object.lid = user_divs[i].id;
						temp_object.guid = user_divs[i].getElementsByTagName('div')[1].getElementsByTagName('div')[0].getElementsByTagName('a')[0].href.match(/\w+$/);
						temp_object.avatar = user_divs[i].getElementsByTagName('div')[1].getElementsByTagName('div')[0].getElementsByTagName('a')[0].getElementsByTagName('img')[0].src;
						temp_object.nick = user_divs[i].getElementsByTagName('div')[1].getElementsByTagName('div')[0].getElementsByTagName('a')[0].getElementsByTagName('img')[0].alt;
						temp_object.d_id = user_divs[i].getElementsByTagName('div')[1].getElementsByTagName('div')[1].getElementsByTagName('div')[0].firstChild.data;
					
						return_object.push(temp_object);
					}
				}
			}
			return (return_object);
		});
		if (my_settings.verboselevel > 0) {
			console.log('found '+user_array.length+' users in that aspect:');
		}
		if (user_array.length <= 0) {
			console.log('-1');
			phantom.exit();
		}
		var outputstring = '';
		for (var i = 0; i < user_array.length; i++) {
			outputstring = my_settings.outputdemeter[0];
			outputstring += trim(user_array[i].d_id);
			outputstring += my_settings.outputdemeter[1];
			outputstring += my_settings.outputdemeter[0];
			outputstring += trim(user_array[i].lid);
			outputstring += my_settings.outputdemeter[1];
			outputstring += my_settings.outputdemeter[0];
			outputstring += trim(user_array[i].nick);
			outputstring += my_settings.outputdemeter[1];
			outputstring += my_settings.outputdemeter[0];
			outputstring += trim(user_array[i].avatar);
			outputstring += my_settings.outputdemeter[1];
			outputstring += my_settings.outputdemeter[0];
			outputstring += user_array[i].guid;
			outputstring += my_settings.outputdemeter[1];
			console.log(outputstring);
		}
		phantom.exit();		
	} else {
		if (my_settings.verboselevel > 0) {
			console.log('unbekannter Zustand... ');
		}
		//console.log(stripHTML(pagecontent));
		console.log(pagecontent);
		//console.log(pageadress);
	}
	if (my_settings.verboselevel > 0) {
		console.log('/loaded');	
	}
}

if (my_settings.aspectID == 0) {
	page.open(my_settings.base_url+'contacts');
} else {
	page.open(my_settings.base_url+'contacts?a_id='+my_settings.aspectID);
}
