#######################################################################
##                                                                   ##
##                            SETTINGS                               ##
##                                                                   ##
#######################################################################
## phantombin is the path to your phantomjs-binary. If this script   ##
## runs in the same directory as phantomjs the default entry         ##
## "./phantomjs" is fine. If you set up your phantom-bin-dir to your ##
## $PATH "phantomjs" would be correct. In other cases just set up    ##
## the whole path like "/etc/phantomjs/bin/phantomjs".               ##
#######################################################################
set phantombin "./phantomjs"
#######################################################################
## groupprefix defines what character marks a groupname in commands  ##
## in previous versions this was just # to use hashtags as groups    ##
## but for compatibility to status.net now ! is the default. You can ##
## set up any other sign. Take care the character is no special-char ##
## in regular expressions like * or ^ for example.                   ##
#######################################################################
set groupprefix "!"
#######################################################################
## checkfrequency defines in milliseconds how long the script should ##
## wait until it pulls new messages from the server. The script can  ##
## only pull SOME messages (as much as the pod delivers) so you have ##
## to find a balance of "getting every message" and load/performance ##
## 120000 ms are default. 0 means there is no repetation, the bot    ##
## terminates after doing his jobs. That might be usefull for        ##
## testing or use with cron, anachron etc.                           ##
#######################################################################
set checkfrequency 60000
#######################################################################

proc remove_user_from_group { aspectlist user_key user_value {remove_admin 0}} {
	if {$remove_admin} {
		set user_array [lindex $aspectlist 3]
	} else {
		set user_array [lindex $aspectlist 4]
	}
	if {$user_key == "id"} { set user_key 0
	} elseif {$user_key == "guid"} { set user_key 1
	} elseif {$user_key == "name"} { set user_key 2
	} elseif {$user_key == "handle"} { set user_key 3
	} elseif {$user_key == "did"} { set user_key 3
	} elseif {$user_key == "d_id"} { set user_key 3
	} elseif {$user_key == "avatar"} { set user_key 4
	} elseif {$user_key == "image"} { set user_key 4 }
	if {[string is digit $user_key]} {
		if {$user_key <= 4 && $user_key >=0} {
			for {set i [expr [llength $user_array] -1]} { $i >= 0} { set i [expr $i-1] } {
				if {[lindex [lindex $user_array $i] $user_key] == $user_value} {
					set user_array [lreplace $user_array $i $i]
				}
			}
		}
	}
	puts "aspectlist: $aspectlist"
	if {$remove_admin} {
		set aspectlist [lreplace $aspectlist 3 3 $user_array]
	} else {
		set aspectlist [lreplace $aspectlist 4 4 $user_array]
	}
	puts "check if admins left..."
	if {[llength [lindex $aspectlist 3]] == 0} {
		puts "#oh-oh no admin left..."
		
		if {[llength [lindex $aspectlist 4]] > 0} {
			puts "#phew, there are users left... good make the 'oldest' user an admin"
			add_user_to_group $aspectlist [lindex [lindex $aspectlist 4] 0] 1
		} else {
			puts "#no admin, no user? Drop the group"
			return "delete"
		}
	}
	return $aspectlist
}

proc add_user_to_group {aspectlist my_user {add_admin 0} } {
	global phantombin
	if {$add_admin} {
		set user_array [lindex $aspectlist 3]
	} else {
		set user_array [lindex $aspectlist 4]
	}
	if { [llength $my_user] != 5} {
		# get user-info from pod
		set user_search_answer [split [exec $phantombin "get_user.js" "-d" "Ŋ" "Ŋ" "N" "N" "-u" $my_user] "Ŋ"]
		if {[llength $user_search_answer] >= 5} {			
			set my_user [list [lindex $user_search_answer 1] [lindex $user_search_answer 3] [lindex $user_search_answer 5] [lindex $user_search_answer 7] [lindex $user_search_answer 9]]
		}
	}
	if { [llength $my_user] == 5} {
		lappend user_array $my_user
	}
	puts "aspectlist: $aspectlist"
	if {$add_admin} {
		set aspectlist [lreplace $aspectlist 3 3 $user_array]
	} else {
		set aspectlist [lreplace $aspectlist 4 4 $user_array]
	}
	return $aspectlist
}

proc get_aspectinfo {aspect} {
	if {[string is digit $aspect]} {
		if {[file exists "/aspects/$aspect"]} {
			set tempfile [open "/aspects/$aspect" r]
			set aspect [read $tempfile]
			close $tempfile
		}
	}
	if {[file exists "./aspects/$aspect"]} {
		set aspectfile [open "./aspects/$aspect" r]
		set aspectlist [read $aspectfile]
		close $aspectfile
		return $aspectlist
	} else {
		return 0
	}
}

## Aspect-List-Structure:
#0 name [string]
#1 id [integer]
#2 description [string]
#3 admins [list of persons]
# 3.0.0 id
# 3.0.1 guid
# 3.0.2 name
# 3.0.3 handle
# 3.0.4 avatar
#4 subscriber [list of persons]
# 4.0.0 id
# 4.0.1 guid
# 4.0.2 name
# 4.0.3 handle
# 4.0.4 avatar
#5 rules/settings [list of key/value]
# 5.0 invitation? (default:0)
# 5.1 external input? (default:0)
# 5.2 always public? (default:0)

proc save_aspectinfo {aspectname aspectlist} {
	if {[string is digit $aspectname]} {
		if {[file exists "./aspects/$aspectname"]} {
			set tempfile [open "./aspects/$aspectname" r]
			set aspectname [read $tempfile]
			close $tempfile
		}
	}
	
	set aspectfile [open "./aspects/$aspectname" w]
	puts $aspectfile $aspectlist
	close $aspectfile
}

proc send_post { my_command } {	
	puts "sending..."
	global phantombin
	global groupprefix
	##set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set my_postcontent [join [lrange [split [lindex $my_command 5] "\n"] 1 end] "\n"]
	set send_public [string first "public" $my_subcommand]
	set target_aspect [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	set post_header "!\[avatar\]([lindex $my_command 15]) @\{[lindex $my_command 11] ; [lindex $my_command 13]\} to $groupprefix\*$target_aspect\*"
	set my_postcontent "$post_header \n\n$my_postcontent"
	#set group_exists 0
	#set aspect_id 0
	#foreach {nothing1 a_id nothing2 a_name} $aspect_list {
	#	if { $a_name == $target_aspect } {
	#		set group_exists 1
	#		set aspect_id $a_id
	#	}
	#}
	set aspect_id [get_aspectid $target_aspect]
	if {$send_public >= 0}	{
		##adding mentionts...
		##getting all ppl in the aspect:
		set target_users [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $aspect_id] "Ŋ"]
		puts "$phantombin get_aspects.js -d Ŋ Ŋ N N -a $aspect_id"
		puts $target_users
		set my_postcontent "$my_postcontent\n\n"
		for { set i 1 } { $i < [llength $target_users] } { set i [expr $i+10] } {
			set my_postcontent "$my_postcontent @\{_ ; [lindex $target_users $i]\}"
		}
		set aspect_id "public"
	}
	
	if {$aspect_id != ""} {
		set post_answer [split [exec $phantombin "post_content.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $aspect_id "--" $my_postcontent] "Ŋ"]
	} else {
		puts "aspect_id is empty, didn't sent"
	}
	puts "$my_postcontent \n\n $aspect_id"
}

proc subscribe { my_command } {
	puts "(un)subscription..."
	global phantombin
	global groupprefix
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set new_aspectname [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	#set group_exists 0
	#set aspect_id 0
	#foreach {nothing1 a_id nothing2 a_name} $aspect_list {
	#	if { $a_name == $new_aspectname } {
	#		set group_exists 1
	#		set aspect_id $a_id
	#	}
	#}
	set aspect_id [get_aspectid $new_aspectname]
	if ($aspect_id) { set group_exists 1 } else { set group_exists 0 }
	if { $new_aspectname == "create"      } { set group_exists 2 }
	if { $new_aspectname == "found"       } { set group_exists 2 }
	if { $new_aspectname == "subscribe"   } { set group_exists 2 }
	if { $new_aspectname == "enter"       } { set group_exists 2 }
	if { $new_aspectname == "unsubscribe" } { set group_exists 2 }
	if { $new_aspectname == "leave"       } { set group_exists 2 }
	if { $new_aspectname == "set"         } { set group_exists 2 }
	if { $new_aspectname == "setup"       } { set group_exists 2 }
	if { $group_exists == 0 || $group_exists == 2} {
		if {[regexp -nocase {(^|\s)(unsubscribe|leave)(\s|$)} $my_subcommand] } {
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "You can't leave $groupprefix$new_aspectname there's no such group."]
		} elseif {[regexp -nocase {(^|\s)(subscribe|enter)(\s|$)} $my_subcommand] } {
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "You can't join $groupprefix$new_aspectname there's no such group."]
		} 
	} elseif { $group_exists == 1 } {
		set sender_id [lindex $my_command 7]
		set subscribemode "NOTHING"
		if {[regexp -nocase {(^|\s)(subscribe|enter)(\s|$)} $my_subcommand] } { set subscribemode "ADD" }
		if {[regexp -nocase {(^|\s)(unsubscribe|leave)(\s|$)} $my_subcommand] } { set subscribemode "DEL" }
		puts [info vars "*_id"]
		puts $aspect_id
		if {$subscribemode == "DEL"} {
			puts "$phantombin change_useraspect.js -d Ŋ Ŋ N N -a $aspect_id -m DEL -u $sender_id"
			set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $aspect_id "-m" "DEL" "-u" $sender_id] "Ŋ"]
		} elseif {$subscribemode == "ADD"} {
			puts "$phantombin change_useraspect.js -d Ŋ Ŋ N N -a $aspect_id -m ADD -u $sender_id"
			set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $aspect_id "-m" "ADD" "-u" $sender_id] "Ŋ"]
		} else {
			set adduser_answer -500
		}
		if {$adduser_answer == "201" || $adduser_answer == "200"} {
			if {$subscribemode == "ADD"} {
				puts "User added"
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n you just subscribed $groupprefix$new_aspectname"]
				set founder_array [list [lindex $my_command 7] [lindex $my_command 9] [lindex $my_command 11] [lindex $my_command 13] [lindex $my_command 15]]
				set my_groupinfo [get_aspectinfo $new_aspectname]
				set my_groupinfo [add_user_to_group $my_groupinfo $founder_array]
				save_aspectinfo $new_aspectname $my_groupinfo
			} elseif {$subscribemode == "DEL"} {
				puts "User removed"
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n you just unsubscribed $groupprefix$new_aspectname"]
				set my_groupinfo [get_aspectinfo $new_aspectname]
				puts "my_groupinfo $my_groupinfo"
				set my_groupid [lindex $my_groupinfo 1]
				puts "my_groupid $my_groupid"
				set my_groupinfo [remove_user_from_group $my_groupinfo "guid" [lindex $my_command 9]]
				set my_groupinfo [remove_user_from_group $my_groupinfo "guid" [lindex $my_command 9] 1]
				if {$my_groupinfo == "delete"} {
					file delete "./aspects/$new_aspectname"
					puts "\n$phantombin delete_aspect.js -a $my_groupid\n"
					set dropaspect_answer [exec $phantombin "delete_aspect.js" "-a" $my_groupid]
					if { $dropaspect_answer == 200 } {
						set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Oh, you've been the last subscriber, I deleted the group."]
					} else {
						puts "Could not delete group $my_groupid from server"
					}
				} else {
					save_aspectinfo $new_aspectname $my_groupinfo					
				}
			}
		} else {
			puts "User wasn't $subscribemode\ed for some reason ( $adduser_answer )"
			if  {$subscribemode == "DEL"} {
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, I couldn't remove you from $groupprefix$new_aspectname for some reason. Maybe you just try again in a few minutes?"]
			} elseif {$subscribemode == "ADD"} {
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, I couldn't add you to $groupprefix$new_aspectname for some reason. Maybe you just try again in a few minutes?"]
			}
		}
		
		
	}
	
}

proc get_aspectid { aspectname } {
	global phantombin
	set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	foreach {nothing1 a_id nothing2 a_name} $aspect_list {
		if { $a_name == $aspectname } {
			return $a_id
		}
	}
	return 0
}

proc set_prefference {my_command } {
	puts "settings..."
	global phantombin
	global groupprefix
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set my_postcontent [join [lrange [split [lindex $my_command 5] "\n"] 1 end] "\n"]
	set my_sender_guid [lindex $my_command 9]
	set my_aspectname [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	set my_aspectid [get_aspectid $my_aspectname]
	if {$my_aspectid == "" } { set my_aspectid 0 }
	if {$my_aspectid} {
		set my_aspectinfo [get_aspectinfo $my_aspectname]
		#aspect/group exists, check if the user is admin...
		set is_admin 0
		for {set i 0} {$i < [llength [lindex $my_aspectinfo 3]]} { incr i} {
			if {[lindex [lindex [lindex $my_aspectinfo 3] $i] 1] == $my_sender_guid} {
				set is_admin 1
			}
		}
		if {$is_admin} {
			set outputtext "## Done\\n\\n set\\n"
			set pref_array [lindex $my_aspectinfo 5]
			if {[regexp -nocase {(^|\s)(invite_only)(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 0 0 1]
				set outputtext "$outputtext\\n* invitation needed = true"
			}
			if {[regexp -nocase {(^|\s)(open_access)(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 0 0 0]
				set outputtext "$outputtext\\n* invitation needed = false"
			}
			if {[regexp -nocase {(^|\s)(open_(input|post(ing)?)s?|allow_ext(ern(al)?)?_posts?)(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 1 1 1]
				set outputtext "$outputtext\\n* external input = true"
			}
			if {[regexp -nocase {(^|\s)(closed?_(input|post(ing)?)s?|(deny|forbid|disallow|prohibit)_ext(ern(al)?)?_post(ing)?s?)(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 1 1 0]
				set outputtext "$outputtext\\n* external input = false"
			}
			if {[regexp -nocase {(^|\s)(always_)?public(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 2 2 1]
				set outputtext "$outputtext\\n* always public = true"
			}
			if {[regexp -nocase {(^|\s)(private)(\s|$)} $my_subcommand]} {
				set pref_array [lreplace $pref_array 2 2 0]
				set outputtext "$outputtext\\n* always public = false"
			}
			if {[regexp -nocase {(^|\s)(description)(\s|$)} $my_subcommand]} {
				set my_aspectinfo [lreplace $my_aspectinfo 2 2 $my_postcontent]
				set outputtext "$outputtext\\n* setup a description ([string length $my_postcontent])"
			}
			if {[regexp -nocase {(^|\s)(admin)\s(\w+@[\w\.\-]+)(\s|$)} $my_subcommand]} {
				regexp -nocase {(^|\s)(admin)\s(\w+@[\w\.\-]+)(\s|$)} $my_subcommand temp0 temp1 temp2 new_admin_handle temp3
				set my_aspectinfo [add_user_to_group $my_aspectinfo $new_admin_handle 1]
				set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $my_aspectid "-m" "ADD" "-u" [lindex [lindex [lindex $my_aspectinfo 3] end] 0]] "Ŋ"]
				set outputtext "$outputtext\\n* added [lindex [lindex [lindex $my_aspectinfo 3] end] 2] as an admin"
			}			
			save_aspectinfo $my_aspectname $my_aspectinfo
			puts "everything's fine, did what I wanted to do (I think) output is:\n\n$outputtext"
			puts "$phantombin post_comment.js -p [lindex $my_command 1] -- $outputtext"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" $outputtext]
			puts $comment_answer
		} else {
			puts "User seems to be no admin"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Only admins can setup prefferences, I did not recognize you as an admin."]
		}
	} else {
		puts "Couldn't find aspect '$my_aspectname\' to set up prefferences."
		set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Could not find $groupprefix$my_aspectname"]
	}
}

proc send_help { my_command } {	
	puts "sending help..."
	global phantombin
	global groupprefix
	set help_text "## Help\\n\\n"
	set help_text "$help_text Hello and welcome, you called me and asked for my help. So I'm here to tell you how this stuff works.\\n\\n"
	set help_text "$help_text I'm a group-bot and I offer the functionality you might know from mailing-lists. Basically I'm a distributor of messages."
	set help_text "$help_text You can controll me by several commands I'll teach you now."
	set help_text "$help_text First of all: Whenever you send anything to me, do it by writing a regular posting and **mention** me in it."
	set help_text "$help_text I do not handle *'conversation'* (private messages) at the moment.\\n"
	set help_text "$help_text I have to be able to read the posting so you have to send it publicly or to an aspect I'm in."
	set help_text "$help_text So maybe you wanna create an own aspect for me or for bots in general.\\n"
	set help_text "$help_text Any command send to me has to be in the first line of your posting (several other lines might be payload).\\n\\n"
	set help_text "$help_text\### Groupnames\\n\\n"
	set help_text "$help_text Whenever you refer a groupname start with a \\$groupprefix\."
	set help_text "$help_text So if you're talking about the group *'mygroup'* you'd use \\$groupprefix\mygroup.\\n\\n"
	set help_text "$help_text\### Founding a group\\n\\n"
	set help_text "$help_text The command-word to create a group is **create** or **found** and please tell me the name of the group as well ;D.\\n"
	set help_text "$help_text So if you'd like to create the group *'mygroup'* write a posting like\\n\\n"
	set help_text "$help_text >> @groupbot create \\$groupprefix\mygroup\\n\\n"
	set help_text "$help_text You will be the admin of that group (more about admins in the *'setup'* section)\\n\\n"
	set help_text "$help_text\### Enter a group\\n\\n"
	set help_text "$help_text Joining a group is nearly like creating one, just use **subscribe** or **enter** and the groups name.\\n\\n"
	set help_text "$help_text >> @groupbot subscribe \\$groupprefix\mygroup\\n\\n"
	set help_text "$help_text\### Leave a group\\n\\n"
	set help_text "$help_text **unsubscribe** or **leave**\\n\\n"
	set help_text "$help_text >> @groupbot unsubscribe \\$groupprefix\mygroup\\n\\n"
	set help_text "$help_text If you are the last admin of a group and leave it, then the user having the longest membership/subscription inherits the admin status."
	set help_text "$help_text If no user is left after you leave, the group will be disbanded.\\n\\n"
	set help_text "$help_text\### Setup prefferences\\n\\n"
	set help_text "$help_text The command-word to setup preferences of a group is **set** or **setup**."
	set help_text "$help_text There are some subcommands to use. Of course you have to be admin of the group to do any setup.\\n\\n"
	set help_text "$help_text\* **invite_only** makes the group to a closed one, noone can subscribe it without beeing invited. (not implemented yet)\\n"
	set help_text "$help_text\* **open_access** is the opposite, it makes the group open to everybody, so everybody can subscribe to it without beeing invited. (default)\\n"
	set help_text "$help_text\* **closed_input** or **disallow_ext_posts** will prevent non-subscribers from sending postings to the group. (default but not yet implemented)\\n"
	set help_text "$help_text\* **open_input** or **allow_ext_posts** will allow non-subscribers sending postings to the group.\\n"
	set help_text "$help_text\* **public** or **always_public** makes any group-posting in the future public."
	set help_text "$help_text No matter whether it's set as public or not. (more about public posts in the *'sending'* section)\\n"
	set help_text "$help_text\* **private** makes group-posting by default only visible to the group, so if you don't tell me to make a posting public,"
	set help_text "$help_text I will send it *limited* to an aspect the group is bound to.\\n"
	set help_text "$help_text\* **admin** \\\[diaspora handle\\\] makes another user an admin of the group."
	set help_text "$help_text You will not lose your admin-status in that case."
	set help_text "$help_text Write the diaspora-handle of the new admin directly behind the keyword **admin** (seperated by a space)."
	set help_text "$help_text The new admin is added to the group as an admin **and** subscriber if she isn't allready.\\n"
	set help_text "$help_text\* **description** tells me to use the *payload* of the posting as the description of the group."
	set help_text "$help_text (You can set a description and it is saved, but for now there is no way to display it.). In this case 'payload' means  the text starting one or two lines below the keyword **description**.\\n\\n"
	set help_text "$help_text You can set multiple settings in one posting. **Example:**\\n\\n"
	set help_text "$help_text >> @groupbot \\$groupprefix\mygroup setup admin anewadmin@example.org public description invite_only\\n\\n"
	set help_text "$help_text >> This is the groups description\\n\\n"
	set help_text "$help_text I don't care about the order of the commands/keywords,"
	set help_text "$help_text just be sure to write the diaspora-handle directly after the *'admin'* keyword, everything else... pffft"
	set help_text "$help_text (that includes the groups name, just be sure to prefix it with a \\$groupprefix ).\\n\\n"
	set help_text "$help_text\### Sending postings\\n\\n"
	set help_text "$help_text Sending a posting is simple and it has just one (or two) keywords."
	set help_text "$help_text If no of the command-words apears in the first line I'll take the posting as... as posting.. to send."
	set help_text "$help_text Use the *'payload'* to writer your actual posting.\\n\\n"
	set help_text "$help_text >> @groupbot \\$groupprefix\mygroup\\n\\n"
	set help_text "$help_text >> Hey dudes, let's talk about #this or\\n\\n"
	set help_text "$help_text >> ### #that\\n\\n"
	set help_text "$help_text >> I can also use images !\[images\](/assets/branding/ball_small.png) in my posting (but I cannot upload any in this version of the bot :( )\\n\\n"
	set help_text "$help_text The only keyword (except the groupname) is **public**."
	set help_text "$help_text Usually a post you send to the group is *limited* to the group (using the aspect-functionality of diaspora)."
	set help_text "$help_text But if you use the keyword **public** in the first line (or the group is set to be always public)"
	set help_text "$help_text I will repost it as a *public* posting and *mention* all subscribers (so they'll get a notification).\\n\\n"
	set help_text "$help_text \\n\\n"
	set help_text "$help_text Erm... well... that's it, have fun :-)"
	set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" $help_text]
	puts $help_text
	puts $comment_answer
}

proc create_group { my_command } {	
	puts "creation..."
	global phantombin
	global groupprefix
	#step one: check if there is a group of this name
	##set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set new_aspectname [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	##set group_exists 0
	if {[get_aspectid $new_aspectname]} { set group_exists 1 } else { set group_exists 0 }
	##foreach {nothing1 a_id nothing2 a_name} $aspect_list {
	##	if { $a_name == $new_aspectname } {
	##		set group_exists 1
	##	}
	##}
	if { $new_aspectname == "create"      } { set group_exists 2 }
	if { $new_aspectname == "found"       } { set group_exists 2 }
	if { $new_aspectname == "subscribe"   } { set group_exists 2 }
	if { $new_aspectname == "enter"       } { set group_exists 2 }
	if { $new_aspectname == "unsubscribe" } { set group_exists 2 }
	if { $new_aspectname == "leave"       } { set group_exists 2 }
	if { $new_aspectname == "set"         } { set group_exists 2 }
	if { $new_aspectname == "setup"       } { set group_exists 2 }
	if { [string is digit $new_aspectname]} { set group_exists 2 }
	if { $group_exists == 0 } {
		# $new_aspectname will be created
		set new_aspect_creation_answer [split [exec $phantombin "create_aspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $new_aspectname] "Ŋ"]
		if {[regexp {^\d+$} $new_aspect_creation_answer] > 0} {
			set sender_id [lindex $my_command 7]
			puts "Created aspect $new_aspect_creation_answer"
			#adding the asking user to this aspect...
			set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $new_aspect_creation_answer "-m" "ADD" "-u" $sender_id] "Ŋ"]
			if {$adduser_answer == "201"} {
				puts "Aspect created, user added"
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n the group $groupprefix$new_aspectname has been created and you were add to it."]
			} else {
				puts "Aspect created but user wasn't added for some reason ( $adduser_answer )"
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, I created the group $groupprefix$new_aspectname but for some reason I couldn't add you. You should try to subscribe the group by sending \\n\\n    subscribe $groupprefix$new_aspectname \\n\\nto me."]
			}
			# 1+3   "202890" "af99f4b44dd8eda5"
			# 5     "![avatar](https://pod.geraspora.de/uploads/images/thumb_small_7e75a4aba22a1d2d8f33.jpg) [Deus** Figendi](deusfigendi@pod.geraspora.de) to #defibrillator Und das hier ist die Nachricht"
			# 7+9   "19257" "guid"
			# 11+13 "Group Bot" "groupbot@pod.orkz.net"
			# 15    "https://pod.orkz.net/uploads/images/thumb_small_d9ca968a4418842cce0f.png"
			
			set founder_array [list [lindex $my_command 7] [lindex $my_command 9] [lindex $my_command 11] [lindex $my_command 13] [lindex $my_command 15]]
			
			set aspectsettings [list $new_aspectname $new_aspect_creation_answer "description" [list $founder_array] [list $founder_array] [list 0 0 0]]
			save_aspectinfo $new_aspectname $aspectsettings
		} else {
			puts "Something went wrong, I didn't get the regular answer for creating aspects."
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, I tried to create $groupprefix$new_aspectname but for some reason that didn't work."]
		}
	} elseif { $group_exists == 1 } {
		puts "$new_aspectname allready exists"
		set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "The group $groupprefix$new_aspectname allready exists. Please choose another name or subscribe that one."]
	} elseif { $group_exists == 2 } {
		set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "$groupprefix$new_aspectname matches a keyword, I will not create that group. Please choose another name."]
	}
}

proc main {} {
	##catch [exec "./phantomjs" "get_aspects.js"] returnvalue
	global phantombin
	global checkfrequency
	set my_commands [split [exec $phantombin "get_streamlike.js" "-a" "mentions" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	while { [llength $my_commands] > 0 } {
		set my_command [lrange $my_commands 0 15]
		set my_commands [lrange $my_commands 16 end]
		set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
		#puts $my_subcommand
		if { [regexp -nocase {(^|\s)(create|found)(\s|$)} $my_subcommand] } {
			#Group-creation
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				create_group $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\ncreated"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(subscribe|enter)(\s|$)} $my_subcommand] } {
			#Subscribtion
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				subscribe $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nsubscribed"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(unsubscribe|leave)(\s|$)} $my_subcommand] } {
			#Unsubscription
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				subscribe $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nunsubscribed"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(set|setup)(\s|$)} $my_subcommand] } {
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				set_prefference $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nsent"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(help)(\s|$)} $my_subcommand] } {
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				send_help $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nsent"
				close $done_file
			}
		} else {
			#sending
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				send_post $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nsent"
				close $done_file
			}
		}
	}
	if {$checkfrequency} {
		puts "now waiting [expr $checkfrequency / 1000] seconds..."
		after [expr $checkfrequency * 1  / 2] { puts [expr $checkfrequency / 2000 ]}
		after [expr $checkfrequency * 2  / 3] { puts [expr $checkfrequency / 3000 ]}
		after [expr $checkfrequency * 3  / 4] { puts [expr $checkfrequency / 4000 ]}
		after [expr $checkfrequency * 4  / 5] { puts [expr $checkfrequency / 5000 ]}
		after [expr $checkfrequency * 5  / 6] { puts [expr $checkfrequency / 6000 ]}
		after [expr $checkfrequency * 6  / 7] { puts [expr $checkfrequency / 7000 ]}
		after [expr $checkfrequency * 7  / 8] { puts [expr $checkfrequency / 8000 ]}
		after [expr $checkfrequency * 8  / 9] { puts [expr $checkfrequency / 9000 ]}
		after [expr $checkfrequency * 9  /10] { puts [expr $checkfrequency / 10000]}
		after [expr $checkfrequency * 10 /11] { puts [expr $checkfrequency / 11000]}
		after [expr $checkfrequency * 11 /12] { puts [expr $checkfrequency / 12000]}
		after $checkfrequency main
	} else {
		exit
	}
}

main

vwait null
