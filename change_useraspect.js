/*  Groupbots phantomjs-modules provide several functions to do stuff
    with an diaspora account. This file adds an user to or removes an
    user off an aspect.
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
		console.log('Adds an user to an aspect or removes off. Returns HTTP-statuscode of the action.');
		console.log('');
		console.log('Possible parameter: -a -u -v -d -h');
		console.log('');
		console.log('-a | -aspect <aspect-id>');
		console.log('           Tells the script wich aspect should be added or removed.');
		console.log('');
		console.log('-u | -user <user-id>');
		console.log('           Tells the script whos aspect should be added or removed.');
		console.log('');
		console.log('-m | -method <keyword>');
		console.log('           Tells the script if the aspect should be ADD or REMOVEd.');
		console.log('           Possible values: ADD, POST, CREATE, _POST, DELETE, DEL, LEAVE,');
		console.log('                                                                   REMOVE');
		console.log('');
		console.log('-v | -verbose');
		console.log('           Makes the script telling you what it is doing.');
		console.log('');
		console.log('-h | --help | -help | ? | -? | --?');
		console.log('           Shows this help and terminate.');
		console.log('');
		console.log('Returns:');
		console.log('    200    deleting worked');
		console.log('    201    adding worked');
		console.log('    400    adding failed (because the user was allready in the aspect');
		console.log('                                        or the aspact wasn\'t found.)');
		console.log('    404    adding failed (because the user-id is invalid or the user');
		console.log('                                                     wasn\'t found.)');
		console.log('    406    deleting failed (because the user wasn\'t in the aspect or');
		console.log('                                           the aspect wasn\'t found.)');
		console.log('    500    adding failed (because of invalid aspect-id or the aspect');
		console.log('                                                     wasn\'t found.)');
		console.log('');
		console.log('As a Table:');
		console.log('     ┏━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━━━━━┓');
		console.log('     ┃        ┃ success  ┃   failure   ┃');
		console.log('     ┣━━━━━━━━╃──────────╀─────────────┦');
		console.log('     ┃ ADD    │   201    │ 400 404 500 │');
		console.log('     ┣━━━━━━━━┽──────────┼─────────────┤');
		console.log('     ┃ DEL    │   200    │     406     │');
		console.log('     ┖━━━━━━━━┵──────────┴─────────────┘');
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
			
//			return 'POST '+post_value.join('&')+' to '+my_baseurl+'aspect_memberships.json'+"\n\n"+'status: '+my_ajaxrequest.status+' '+my_ajaxrequest.statusText+"\n\n"+my_ajaxrequest.responseText;
			return my_ajaxrequest.status;
		},my_settings.method,my_settings.aspectid,my_settings.userid,my_settings.base_url);
		
		console.log (my_return_value);
		phantom.exit();
	}
};


page.open(my_settings.base_url+'stream');
