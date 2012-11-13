/*  Groupbots phantomjs-modules provide several functions to do stuff
    with an diaspora account. This file posts postings.
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


my_settings.posting = 'foooooobar';
my_settings.target = 1;
my_settings.is_sent = false;
my_settings.verboselevel = 1;
my_settings.outputdemeter = new Array('"','"','»','«');
for (var i=0; i < system.args.length; i++) {
	if(system.args[i] == '-t' || system.args[i] == '-target' || system.args[i] == '-g' || system.args[i] == '-group' || system.args[i] == '-a' || system.args[i] == '-aspect') { my_settings.target = system.args[i+1]; }
	if(system.args[i] == '--' || system.args[i] == '-content') { my_settings.posting = system.args[i+1]; }
	if(system.args[i] == '-v' || system.args[i] == '-verbose') { my_settings.verboselevel = 1; }
	if(system.args[i] == '-h' || system.args[i] == '--help'|| system.args[i] == '-help'|| system.args[i] == '?'|| system.args[i] == '-?'|| system.args[i] == '--?') {
		console.log('              ┏━━━━━━━━━━━━━━━┓');
		console.log('              ┃      HELP     ┃');
		console.log('──────────────┨  post content ┠──────────────');
		console.log('              ┗━━━━━━━━━━━━━━━┛');
		console.log('');
		console.log('Possible parameter: -a -v -d -h');
		console.log('');
		console.log('-a | -group | -target <aspect-ID>');
		console.log('           Tells the script to wich aspect the message should be send. Possible');
		console.log('           values are aspect-IDs and all_aspects and public.');
		console.log('');
		console.log('-v | -verbose');
		console.log('           Makes the script telling you what it is doing.');
		console.log('');
		console.log('-h | --help | -help | ? | -? | --?');
		console.log('           Shows this help and terminate.');
		console.log(" ");
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
	console.log(pagetitle);
	console.log(pageadress);
	
	if (pagetitle.match(/Sign\sin/)) {
		if (my_settings.verboselevel > 0) {
			console.log('sign-in page, signing in...');
		}
		signin(page,my_settings);
	} else if (pageadress.match(/\/stream\/?$/)){
		//foobar
		//Informationen, die an dieser Stelle gebraucht werden:
		//	Text, der gesendet werden soll
		//	Ziel-Aspekte (ggf. "public" oder "all_aspects"), vorläufig nur einer.
		//
		//Entscheidene Elemente:
		//	id=status_message_fake_text
		//	id=status_message_text
		//	id=aspect_ids_<fortlaufendeZahl> ++ name=aspect_ids[] (muss geschaffen werden, gültige Werte sind aspect-IDs sowie die Werte "all_aspects" und "public")
		
		page.evaluate(function(my_content,my_aspect) {
			document.getElementById('status_message_fake_text').value = my_content;
			document.getElementById('status_message_text').value = my_content;
			document.getElementById('aspect_ids_').value = my_aspect;
			document.getElementById('status_message_text').form.submit();			
		},my_settings.posting,my_settings.target);
		
		if (my_settings.is_sent) {	phantom.exit();	} else { my_settings.is_sent = true; }
	}
};

page.open(my_settings.base_url+'stream');
