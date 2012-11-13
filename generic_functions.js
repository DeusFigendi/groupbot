/*  Groupbots phantomjs-modules provide several functions to do stuff
    with an diaspora account. This file provides basic functions and
    settings to use within other files.
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

page = require('webpage').create();
system = require('system');
page.settings.loadImages = false;

my_settings = new Object();
my_settings.base_url = 'https://example.org/';
my_settings.loginname = 'groupbot';
my_settings.loginpass = 'FDzEaHWusThHnyAw';

phantom.injectJs('override_logindata.js');
/*
override_logindata.js contains just that lines above with new data:

my_settings.base_url = 'https://example.com/';
my_settings.loginname = 'groupbot';
my_settings.loginpass = 'c6mh7RhGhVfsamAg';
*/

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
function trim (str) {
	//from http://javascript.jstruebig.de/javascript/35 copyright unknown
    return str.replace(/[\n\r]/g, '').replace(/ +/g, ' ').replace(/^\s+/g, '').replace(/\s+$/g, '');

}

function stripHTML(str){
	//from http://javascript.jstruebig.de/javascript/35 copyright unknown
	// remove all string within tags
	var tmp = str.replace(/(<.*['"])([^'"]*)(['"]>)/g, 
	function(x, p1, p2, p3) { return  p1 + p3;}
	);
	// now remove the tags
	return tmp.replace(/<\/?[^>]+>/gi, '');
}

function signin(webpageobject,this_settings) {
	webpageobject.evaluate(function(this_settings) {
		document.getElementById('user_username').value = this_settings.loginname;
		document.getElementById('user_password').value = this_settings.loginpass;
		document.getElementById('new_user').submit();
	},this_settings);
}
