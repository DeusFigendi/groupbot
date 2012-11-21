#  Groupbots phantomjs-modules provide several functions to do stuff
#  with an diaspora account. This file provides the groupbots
#  functionality itself.
#  Copyright (C) 2012  Deus Figendi
#
#   Groupbot is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   Groupbot is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
set checkfrequency 20000
#######################################################################


proc remove_user_from_group2 { group_value user_value {remove_from 0}} {
	##removes an user off a group… on the pod AND local
	## group_value might be the (aspect)id or the name of the group
	## user_value might be the (global)id or the diaspora-handle OR (unusual) the Name of the user OR (great) a whole user-array
	## remove_from is 0 for all, 1 for admin only, 2 for subscriber only (unusual)
	
	global phantombin
	#step1 get group-id and group-name
	set group_value [string trim $group_value]
	if {[regexp {^\d+$} $group_value]} {
		##group_value seems to be a group-id, check if there's a file
		if {[file exists "./aspects/$group_value"]} {
			##there's a file with that ID, it should contain the groups name...
			set group_file [open "./aspects/$group_value" r]
			set group_name [string trim [read $group_file]]
			set group_id $group_value
			close $group_file
		} else {
			##there is no such file, let's get it from the pod
			set aspect_list [exec $phantombin "get_aspects.js" "-d" "\{" "\} " "Ŋ" "ŋ"]
			set i 0
			while { [lindex $aspect_list $i] != $group_value && $i < [llength $aspect_list]} {
				##searching for that ID in the aspect-list…
				incr i
			}
			if { $i < [llength $aspect_list]} {
				set group_name [string trim [lindex $aspect_list [expr $i + 1]]]
				set group_id $group_value
			} else {
				##could not find the groupname, maybe group does not exist?
				set group_name -1
				set group_id -1
			}
		}
	} else {
		##group_value seems to be a groupname…
		if {[file exists "./aspects/$group_value"]} {
			##there's a file with that ID, it should contain the groups name...
			set group_file [open "./aspects/$group_value" r]
			set group_array [string trim [read $group_file]]
			set group_name $group_value
			set group_id [lindex $group_array 1 0]
			close $group_file
		} else {
			set group_name $group_value
			set group_id [get_aspectid $group_name]
		}
	}
	## okay, at this point we SHOULD have a group_name and a group_id
	
	if {$group_id > 0} {
		##group was found, lets search for the user
		## first hope: The user_value is an user-array allready, in that case, nothing's to do
		## a user-array is always 5 items long...
		if {[llength $user_value] == 5} {
			##okay, the length is correct but it might still be the displayed name of the user.
			##let's check if the fields are correct... 0=id 1=guid 2=name 3=handle 4=avatar
			if { [regexp {^\d+$} [lindex $user_value 0]] && [regexp {^\w+$} [lindex $user_value 1 0]] && [regexp {^\w+\@[[:alnum:].]+$} [lindex $user_value 3] ] } {
				set user_array $user_value
			}
		}
			
		if { [info exists user_array] <= 0} {
			##there is no user_array, let's check if it can be found somwhere in the groups users from file...				
			if {[file exists "./aspects/$group_name"]} {
				## there is a file with that groupname...
				set group_file [open "./aspects/$group_name" r]
				set group_array [read $group_file]
				close $group_file
				for { set i 0 } { $i < [llength [lindex $group_array 3]]} {incr i} {
					if {[lindex $group_array 3 $i 0] == $user_value ||[lindex $group_array 3 $i 1] == $user_value ||[lindex $group_array 3 $i 3] == $user_value} {
						set user_array [lindex $group_array 3 $i]
					}
					if {[info exists user_array] <= 0 && [lindex $group_array 3 $i 2] == $user_value} {
						set user_array [lindex $group_array 3 $i]
					}
				}
				for { set i 0 } { $i < [llength [lindex $group_array 4]]} {incr i} {
					if {[lindex $group_array 4 $i 0] == $user_value ||[lindex $group_array 4 $i 1] == $user_value ||[lindex $group_array 4 $i 3] == $user_value} {
						set user_array [lindex $group_array 4 $i]
					}
					if {[info exists user_array] <= 0 && [lindex $group_array 4 $i 2] == $user_value} {
						set user_array [lindex $group_array 4 $i]
					}
				}
			}				
		}
		if { [info exists user_array] <= 0} {
			## so there was no user_array given to the proc
			##    the user was not found in file
			## let's just search for it on the pod.
			set user_search_answer [split [exec $phantombin "get_user.js" "-d" "Ŋ" "Ŋ" "N" "N" "-u" $my_user] "Ŋ"]
			if {[llength $user_search_answer] >= 5} {			
				set user_array [list [lindex $user_search_answer 1] [lindex $user_search_answer 3] [lindex $user_search_answer 5] [lindex $user_search_answer 7] [lindex $user_search_answer 9]]
			}				
		}
		if { [info exists user_array]} {
			##okay, in some way we got an user_array, we have a groupname and a groupid, now we can add it to the groupfile (if it exists) and to the aspect(s)
			## jejj we can remove the user XD
			if { $remove_from == 0 || $remove_from == 2 } {
				##remove as subscriber				
				if {[file exists "./aspects/$group_value"]} {
					set group_file [open "./aspects/$group_value" r]
					set group_array [string trim [read $group_file]]					
					close $group_file
					set users_list [lindex $group_array 4]
					set i [llength $users_list]
					while {$i >0} {
						set i [expr $i - 1]
						## okay if the guid or the handle fits remove the user... other stuff might also be possible (e.g. Name AND user-id)
						if {[lindex $users_list $i 1] == [lindex $user_array 1] || [lindex $users_list $i 3] == [lindex $user_array 3] } {
							set users_list [lreplace $users_list $i $i]
						}
					}
					set group_array [lreplace $group_array 4 4 $users_list]
					set group_file [open "./aspects/$group_value" w]
					puts $group_file $group_array
					close $group_file					
				}
				set deluser_answer1 [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\}" "-a" $group_id "-m" "DEL" "-u" [lindex $user_array 0]]				
			} else {
				set deluser_answer1 200
			}
			if { $remove_from == 0 || $remove_from == 1 } {
				##remove as admin
				if {[file exists "./aspects/$group_value"]} {
					set group_file [open "./aspects/$group_value" r]
					set group_array [string trim [read $group_file]]					
					close $group_file				
					set users_list [lindex $group_array 3]
					set i [llength $users_list]
					while {$i >0} {
						set i [expr $i - 1]
						## okay if the guid or the handle fits remove the user... other stuff might also be possible (e.g. Name AND user-id)
						if {[lindex $users_list $i 1] == [lindex $user_array 1] || [lindex $users_list $i 3] == [lindex $user_array 3] } {
							set users_list [lreplace $users_list $i $i]
						}
					}
					set group_array [lreplace $group_array 3 3 $users_list]
					set group_file [open "./aspects/$group_value" w]
					puts $group_file $group_array
					close $group_file					
				}
				
				set deluser_answer2 [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\}" "-a" [get_aspectid "$group_name\_a" 1] "-m" "DEL" "-u" [lindex $user_array 0]]				
			} else {
				set deluser_answer2 200
			}
		} else {
				set deluser_answer1 500
				set deluser_answer2 500
		}
		if { $deluser_answer1 == 200 && $deluser_answer2 == 200 } {
			## everything worked fine
			return 1
		} else {
			## group was found but deleting the user failed in some way.
			return -10
		}
	} else {
		## group not found, didn't try to fetch user
		return -20
	}
}

proc add_user_to_group2 {group_value user_value {add_admin 0} } {
	##adds an user to a group… on the pod AND local
	## group_value might be the (aspect)id or the name of the group
	## user_value might be the (global)id or the diaspora-handle OR (unusual) the Name of the user OR (great) a whole user-array
	## add_admin is boolean if the user should be added as an admin.
	global phantombin
	#step1 get group-id and group-name
	set group_value [string trim $group_value]
	if {[regexp {^\d+$} $group_value]} {
		##group_value seems to be a group-id, check if there's a file
		if {[file exists "./aspects/$group_value"]} {
			##there's a file with that ID, it should contain the groups name...
			set group_file [open "./aspects/$group_value" r]
			set group_name [string trim [read $group_file]]
			set group_id $group_value
			close $group_file
		} else {
			##there is no such file, let's get it from the pod
			set aspect_list [exec $phantombin "get_aspects.js" "-d" "\{" "\} " "Ŋ" "ŋ"]
			set i 0
			while { [lindex $aspect_list $i] != $group_value && $i < [llength $aspect_list]} {
				##searching for that ID in the aspect-list…
				incr i
			}
			if { $i < [llength $aspect_list]} {
				set group_name [string trim [lindex $aspect_list [expr $i + 1]]]
				set group_id $group_value
			} else {
				##could not find the groupname, maybe group does not exist?
				set group_name -1
				set group_id -1
			}
		}
	} else {
		#group_value seems to be a group-name, check if there's a groupfile...
		if {[file exists "./aspects/$group_value"]} {
			## there is a file with that groupname...
			set group_file [open "./aspects/$group_value" r]
			set group_array [read $group_file]
			set group_id [lindex $group_array 1 0]
			set group_name $group_value
			close $group_file
		} else {
			## there is no groupfile, lets get it from the pod.
			set aspect_list [exec $phantombin "get_aspects.js" "-d" "\{" "\} " "Ŋ" "ŋ"]
			set i 0
			while { [lindex $aspect_list $i] != $group_value && $i < [llength $aspect_list]} {
				##searching for that ID in the aspect-list…
				incr i
			}
			if { $i < [llength $aspect_list]} {
				set group_id [string trim [lindex $aspect_list [expr $i - 1]]]
				set group_name $group_value
			} else {
				##could not find the groupname, maybe group does not exist?
				set group_name -1
				set group_id -1
			}
		}
		## so, group_id and group_name are set now, if they are -1 the group was not found
		if {$group_id >= 0} {
			##group was found, lets search for the user
			## first hope: The user_value is an user-array allready, in that case, nothing's to do
			## a user-array is always 5 items long...
			if {[llength $user_value] == 5} {
				##okay, the length is correct but it might still be the displayed name of the user.
				##let's check if the fields are correct... 0=id 1=guid 2=name 3=handle 4=avatar
				if { [regexp {^\d+$} [lindex $user_value 0]] && [regexp {^\w+$} [lindex $user_value 1 0]] && [regexp {^\w+\@[[:alnum:].]+$} [lindex $user_value 3] ] } {
					set user_array $user_value
				}
			}
			
			if { [info exists user_array] <= 0} {
				##there is not user_array, let's check if it can be found somwhere in the groups users from file...				
				if {[file exists "./aspects/$group_name"]} {
					## there is a file with that groupname...
					set group_file [open "./aspects/$group_name" r]
					set group_array [read $group_file]
					close $group_file
					for { set i 0 } { $i < [llength [lindex $group_array 3]]} {incr i} {
						if {[lindex $group_array 3 $i 0] == $user_value ||[lindex $group_array 3 $i 1] == $user_value ||[lindex $group_array 3 $i 3] == $user_value} {
							set user_array [lindex $group_array 3 $i]
						}
						if {[info exists user_array] <= 0 && [lindex $group_array 3 $i 2] == $user_value} {
							set user_array [lindex $group_array 3 $i]
						}
					}
					for { set i 0 } { $i < [llength [lindex $group_array 4]]} {incr i} {
						if {[lindex $group_array 4 $i 0] == $user_value ||[lindex $group_array 4 $i 1] == $user_value ||[lindex $group_array 4 $i 3] == $user_value} {
							set user_array [lindex $group_array 4 $i]
						}
						if {[info exists user_array] <= 0 && [lindex $group_array 4 $i 2] == $user_value} {
							set user_array [lindex $group_array 4 $i]
						}
					}
				}				
			}
			if { [info exists user_array] <= 0} {
				## so there was no user_array given to the proc
				##    the user was not found in file
				## let's just search for it on the pod.
				set user_search_answer [split [exec $phantombin "get_user.js" "-d" "Ŋ" "Ŋ" "N" "N" "-u" $my_user] "Ŋ"]
				if {[llength $user_search_answer] >= 5} {			
					set user_array [list [lindex $user_search_answer 1] [lindex $user_search_answer 3] [lindex $user_search_answer 5] [lindex $user_search_answer 7] [lindex $user_search_answer 9]]
				}				
			}
			if { [info exists user_array]} {
				##okay, in some way we got an user_array, we have a groupname and a groupid, now we can add it to the groupfile (if it exists) and to the aspect(s)
				if {$add_admin} { set usertype 3 } else { set usertype 4 }
				if {[file exists "./aspects/$group_name"] <= 0} {
					#huh, there's no groupfile... okay, we need that, create it in some way!
					set new_grouparray [list $group_name $group_id "-" [list] [list] [list 0 0 0]]
					## maybe try to contruct this from pod
					set group_file [open "./aspects/$group_name" w]
					puts $group_file $new_grouparray
					close $group_file
				}
				## a groupfile surely exists, if it wasn't there it's just created.
				set group_file [open "./aspects/$group_name" r]
				set group_array [read $group_file]
				close $group_file
				# check if the user allready exists
				set user_exists_in_group 0
				set users_array [lindex $group_array $usertype]
				for {set i 0} { $i < [llength $users_array]} { incr i } {
					if { [lindex $users_array $i] == $user_array } { set user_exists_in_group 1 }
				}
				if {$user_exists_in_group == 0} {
					lappend users_array $user_array
					set group_file [open "./aspects/$group_name" w]
					set group_array [lreplace $group_array $usertype $usertype $users_array]
					puts $group_file $group_array
					close $group_file
				}
				## wrote the user to the groupfile, now add it to the aspect
				if {$add_admin} {
					##outch, need the admin-aspect-id to do so
					set admin_aspect_id [get_aspectid "$group_name\_a" 1]
					set adduser_answer [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $admin_aspect_id "-m" "ADD" "-u" [lindex $user_array 0]]
				} else {				
					set adduser_answer [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $group_id "-m" "ADD" "-u" [lindex $user_array 0]]
				}
				## allrightyright, everything should be done, I COULD check what $adduser_answer returned but I'm not sure what to do if it failed (because maybe the user just was in the aspect allready in that case the actual state would be what's wanted.
				return 1				
			} else {
				## That user could not be found, return an error
				return -10
			}
		} else {
			## That group could not be found, return an error
			return -20
		}
	}
}

proc get_grouparray {aspect} {
	if {[string is digit $aspect]} {
		set aspect_id $aspect
		if {[file exists "/aspects/$aspect"]} {
			set tempfile [open "/aspects/$aspect" r]
			set aspect_name [read $tempfile]
			close $tempfile
		} else {
			set aspect_name 0
		}
	}
	if {[file exists "./aspects/$aspect_name"]} {
		set aspectfile [open "./aspects/$aspect_name" r]
		set aspectlist [read $aspectfile]
		close $aspectfile
		return $aspectlist
	} else {
		global phantombin
		set aspect_adminid [get_aspectid "$aspect_name\_a" 1]
		set getaspect_answer1 [exec $phantombin "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $aspect_id]
		if {$aspect_adminid} {
			set getaspect_answer2 [exec $phantombin "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $aspect_adminid]
		} else {
			set getaspect_answer2 "-1"
		}
		if {$getaspect_answer1 != "-1"} {
			set admin_list [list]
			set users_list [list]
			foreach { h_ i_ n_ a_ g_ } $getaspect_answer1 {
				lappend users_list [list $i_ $g_ $n_ $h_ $a_]
			}
			if {$getaspect_answer2 != "-1"} {
				foreach { h_ i_ n_ a_ g_ } $getaspect_answer2 {
					lappend admin_list [list $i_ $g_ $n_ $h_ $a_]
				}
			} else {
				lappend admin_list [lindex $users_list 0]
			}
			set aspectlist [list $aspect_name $aspect_id "desc" $admin_list $users_list [list 0 0 0]]
			return $aspectlist
		} else {
			return 0
		}
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

proc unsubscribe_command { my_command } {
	puts "unsubscription..."
	global phantombin
	global groupprefix
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set group_name [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	if { $group_name == "create"       ||
	     $group_name == "found"        ||
	     $group_name == "subscribe"    ||
	     $group_name == "enter"        ||
	     $group_name == "unsubscribe"  ||
	     $group_name == "leave"        ||
	     $group_name == "set"          ||
	     $group_name == "setup"        ||
	     [regexp {^\d+$} $group_name] ||
	     [regexp {^\w+_a$} $group_name] } {
			#aspectname fits a keyword, abort!
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "You can't leave $groupprefix$group_name because that is no valid groupname."]			
	} else {
		## The groupname is valid...
		set sender_array [list [lindex $my_command 7] [lindex $my_command 9] [lindex $my_command 11] [lindex $my_command 13] [lindex $my_command 15]]
		set subscriber_answer [remove_user_from_group2 $group_name $sender_array]
		if {$subscriber_answer > 0} {
			puts "User removed"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n you just unsubscribed $groupprefix$group_name"]
		} elseif {$subscriber_answer == -10} {
			puts "User is not identified"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm... I'm not sure if you're totally removed. (error: unsubscribe $subscriber_answer\)"]
		} elseif {$subscriber_answer == -20} {
			puts "Group is not identified"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Sorry I cannot find the group $groupprefix$group_name you specified."]
		} else {
			puts "unknown subscription error $subscriber_answer"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, for some unknown reason I could not remove you off $groupprefix$group_name (error: unsubscribe impossible error # $subscriber_answer\)"]
		}
	}
}

proc subscribe_command { my_command } {
	puts "(un)subscription..."
	global phantombin
	global groupprefix
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set group_name [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	
	if { $group_name == "create"       ||
	     $group_name == "found"        ||
	     $group_name == "subscribe"    ||
	     $group_name == "enter"        ||
	     $group_name == "unsubscribe"  ||
	     $group_name == "leave"        ||
	     $group_name == "set"          ||
	     $group_name == "setup"        ||
	     [regexp {^\d+$} $group_name] ||
	     [regexp {^\w+_a$} $group_name] } {
			#aspectname fits a keyword, abort!
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "You can't join $groupprefix$group_name because that is no valid groupname."]			
	} else {
		## The groupname is valid...
		set sender_array [list [lindex $my_command 7] [lindex $my_command 9] [lindex $my_command 11] [lindex $my_command 13] [lindex $my_command 15]]
		set subscriber_answer [add_user_to_group2 $group_name $sender_array 0]
		if {$subscriber_answer > 0} {
			puts "User added"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n you just subscribed $groupprefix$group_name"]
		} elseif {$subscriber_answer == -10} {
			puts "User is not identified"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm... sorry for some reason I could not identify you. (error: impossible case 1)"]
		} elseif {$subscriber_answer == -20} {
			puts "Group is not identified"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Sorry I cannot find the group $groupprefix$group_name you specified."]
		} else {
			puts "unknown subscription error $subscriber_answer"
			set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "Erm, for some unknown reason I could not add you to $groupprefix$group_name (error: subscribe $subscriber_answer\)"]
		}
	}
}


proc get_aspectid { aspectname {source_type 0} } {
	## source_type:
	##             0 "any" (podinformation preffered)
	##             1 "pod"
	##             2 "file"
	if {$source_type != 2} {
		global phantombin
		set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
		foreach {nothing1 a_id nothing2 a_name} $aspect_list {
			if { $a_name == $aspectname } {
				return $a_id
			}
		}
	}
	if {$source_type != 1} {
		## maybe should check if asked for an admin-aspect
		if {[file exists "./aspects/$aspectname"]} {
			set groupfile [open "./aspects/$aspectname" r]
			set group_array [read $groupfile]
			close $groupfile
			return [lindex $group_array 1 0]
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
		set my_aspectinfo [get_grouparray $my_aspectname]
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
				add_user_to_group2 $my_aspectname $new_admin_handle 1
#				set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $my_aspectid "-m" "ADD" "-u" [lindex [lindex [lindex $my_aspectinfo 3] end] 0]] "Ŋ"]
#				set getaspectid_answer [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
#				set i 0
#				while { [lindex $getaspectid_answer $i] != "$my_aspectname\_a" && $i < [llength $getaspectid_answer]} { incr i }					 
#				if { $i < [llength $getaspectid_answer] } {
#					set my_adminaspectid [lindex $getaspectid_answer [expr $i - 2]]
#					set adduser_answer [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $my_adminaspectid "-m" "ADD" "-u" [lindex [lindex [lindex $my_aspectinfo 3] end] 0]] "Ŋ"]
#					set my_aspectinfo [add_user_to_group $my_aspectinfo $new_admin_handle 1]
#					set outputtext "$outputtext\\n* added [lindex [lindex [lindex $my_aspectinfo 3] end] 2] as an admin"
#				} else {
#					puts "could not find $my_aspectname\_a cannot set admin"
#				}
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

proc create_group_command { my_command } {	
	puts "creation..."
	global phantombin
	global groupprefix
	#step one: check if there is a group of this name
	##set aspect_list [split [exec $phantombin "get_aspects.js" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
	set new_aspectname [string range [lindex [regexp -inline -- "\\$groupprefix\\w+" $my_subcommand] 0] 1 end]
	##set group_exists 0
	if {[get_aspectid $new_aspectname]} { set group_exists 1 } else { set group_exists 0 }


	if { $new_aspectname == "create"      } { set group_exists 2 }
	if { $new_aspectname == "found"       } { set group_exists 2 }
	if { $new_aspectname == "subscribe"   } { set group_exists 2 }
	if { $new_aspectname == "enter"       } { set group_exists 2 }
	if { $new_aspectname == "unsubscribe" } { set group_exists 2 }
	if { $new_aspectname == "leave"       } { set group_exists 2 }
	if { $new_aspectname == "set"         } { set group_exists 2 }
	if { $new_aspectname == "setup"       } { set group_exists 2 }
	if { [regexp {.*_a$} $new_aspectname] > 0 } { set group_exists 2 }
	if { [string is digit $new_aspectname]} { set group_exists 2 }
	if { [string length $new_aspectname] > 16} { set group_exists 3 }
	if { $group_exists == 0 } {
		# $new_aspectname will be created
		puts "create aspect... $phantombin create_aspect.js -d Ŋ Ŋ N N -a $new_aspectname"
		set new_aspect_creation_answer1 [split [exec $phantombin "create_aspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $new_aspectname] "Ŋ"]
		puts "create admin-aspect... $phantombin create_aspect.js -d Ŋ Ŋ N N -a $new_aspectname\_a"
		set new_aspect_creation_answer2 [split [exec $phantombin "create_aspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" "$new_aspectname\_a"] "Ŋ"]
		if {[regexp {^\d+$} $new_aspect_creation_answer1] > 0 && [regexp {^\d+$} $new_aspect_creation_answer2] > 0} {
			set sender_id [lindex $my_command 7]
			puts "Created aspect $new_aspect_creation_answer1 / $new_aspect_creation_answer2"
			#adding the asking user to this aspect...
			set adduser_answer1 [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $new_aspect_creation_answer1 "-m" "ADD" "-u" $sender_id] "Ŋ"]
			set adduser_answer2 [split [exec $phantombin "change_useraspect.js" "-d" "Ŋ" "Ŋ" "N" "N" "-a" $new_aspect_creation_answer2 "-m" "ADD" "-u" $sender_id] "Ŋ"]
			if {$adduser_answer1 == "201" && $adduser_answer2 == "201"} {
				puts "Aspect created, user added"
				set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "## Done, \\n\\n the group $groupprefix$new_aspectname has been created and you were added as an admin."]
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
			
			set aspectsettings [list $new_aspectname $new_aspect_creation_answer1 "description" [list $founder_array] [list $founder_array] [list 0 0 0]]
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
	} elseif { $group_exists == 2 } {
		set comment_answer [exec $phantombin "post_comment.js" "-p" [lindex $my_command 1] "--" "$groupprefix$new_aspectname is to long, the maximum length for groupnames is 16 characters."]
	}
}

proc do_idle_stuff {} {
	#after doing what to do or after doing nothing the bot can do maintenance stuff
	global phantombin
	set random_stuff [expr round(rand() * 4)]
	puts "random stuff to do: $random_stuff"
	set group_name [get_random_groupname]
	if {$random_stuff == 1} {
		puts "search in $group_name for dublicates"
		if {[file exists "./aspects/$group_name"]} {
			set groupfile [open "./aspects/$group_name" r]
			set group_array [string trim [read $groupfile]]
			close $groupfile
			set users_list [lindex $group_array 3]
			set indicies_to_delete [list]
			for { set i 0 } { $i < [llength $users_list]} { incr i } {
				for { set j [expr $i + 1] } { $j < [llength $users_list]} { incr j } {
					if {[lindex $users_list $i 1] == [lindex $users_list $j 1] || [lindex $users_list $i 3] == [lindex $users_list $j 3]} {
						lappend indicies_to_delete $j
					}
				}
			}
			for { set i [expr [llength $indicies_to_delete] -1] } { $i >= 0 } { set i [expr $i - 1] } {
				puts "removing [lindex $users_list $i 2] from $group_name"
				set users_list [lreplace $users_list $i $i]
			}			
			set group_array [lreplace $group_array 3 3 $users_list]
			set users_list [lindex $group_array 4]
			set indicies_to_delete [list]
			for { set i 0 } { $i < [llength $users_list]} { incr i } {
				for { set j [expr $i + 1] } { $j < [llength $users_list]} { incr j } {
					if {[lindex $users_list $i 1] == [lindex $users_list $j 1] || [lindex $users_list $i 3] == [lindex $users_list $j 3]} {
						lappend indicies_to_delete $j
					}
				}
			}
			for { set i [expr [llength $indicies_to_delete] -1] } { $i >= 0 } { set i [expr $i - 1] } {
				puts "removing [lindex $users_list $i 2] from $group_name"
				set users_list [lreplace $users_list $i $i]
			}
			set group_array [lreplace $group_array 4 4 $users_list]
			
			set groupfile [open "./aspects/$group_name" w]
			puts $groupfile $group_array
			close $groupfile
		}
	} elseif {$random_stuff == 2} {
		puts "Syncing pod and file on $group_name ..."
		set new_group_name [string trim $group_name]
		set new_group_id [get_aspectid $new_group_name]
		set new_group_adminid [get_aspectid "$new_group_name\_a" 1]
		set new_group_description "-"
		set new_group_admins [list]
		set new_group_users [list]
		set new_group_settings [list 0 0 0]
		
		puts "  getting adminlist from server..."
		if { $new_group_adminid } {
			set adminlist_from_pod [exec "./phantomjs" "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $new_group_adminid]
			if {$adminlist_from_pod != "-1"} {
				puts "        [llength $adminlist_from_pod]"
				foreach { h_ i_ n_ a_ g_ } $adminlist_from_pod {
					lappend new_group_admins [list $i_ $g_ $n_ $h_ $a_]
				}
			}
		}
		puts "  getting userlist from server..."
		if { $new_group_id } {
			set userlist_from_pod [exec "./phantomjs" "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $new_group_id]
			if {$userlist_from_pod != "-1"} {
				puts "        [llength $userlist_from_pod]"
				foreach { h_ i_ n_ a_ g_ } $userlist_from_pod {
					lappend new_group_users [list $i_ $g_ $n_ $h_ $a_]
				}
			}			
		}
		
		puts "  getting information from file..."
		if {[file exists "./aspects/$new_group_name"]} {
			set groupfile [open "./aspects/$new_group_name" r]
			set old_user_array [read $groupfile]
			close $groupfile
			if {[llength $old_user_array] > 0} {
				if {$new_group_name != [lindex $old_user_array 0]} {
					#something ran really really wrong, but just keep the groupname, we'll overwrite the filecontent
				}
			}
			if {[llength $old_user_array] > 1} {
				if {$new_group_id != [lindex $old_user_array 1]} {
					if {$new_group_id != [lindex $old_user_array 1 0]} {
						# group_id on pod differs to the ID in file... I think pod counts XD (except its 0 in that case...)
						if {$new_group_id == 0} { set new_group_id [lindex $old_user_array 1 0]}
					}
				}
				if {[llength [lindex $old_user_array 1]] > 1} {
					## there is an admin-aspect-id in the file, let's check this too.
					if {$new_group_adminid != [lindex $old_user_array 1 1]} {
						# group_adminid on pod differs to the ID in file... I think pod counts XD (except its 0 in that case...)
						if {$new_group_adminid == 0} { set new_group_adminid [lindex $old_user_array 1 1]}
					}
				}
			}
			if {[llength $old_user_array] > 2} {
				set new_group_description [string trim [lindex $old_user_array 2]]
			}
			if {[llength $old_user_array] > 3} {
				# list of admins...
				set new_group_admins [concat [lindex $old_user_array 3] $new_group_admins]
				##remove dublicates...				
				set indicies_to_delete [list]
				for { set i 0 } { $i < [llength $new_group_admins]} { incr i } {
					for { set j [expr $i + 1] } { $j < [llength $new_group_admins]} { incr j } {
						if {[lindex $new_group_admins $i 1] == [lindex $new_group_admins $j 1] || [lindex $new_group_admins $i 3] == [lindex $new_group_admins $j 3]} {
							lappend indicies_to_delete $j
						}
					}
				}
				for { set i [expr [llength $indicies_to_delete] -1] } { $i >= 0 } { set i [expr $i - 1] } {
					set new_group_admins [lreplace $new_group_admins $i $i]
				}				
			}
			
			if {[llength $old_user_array] > 4} {
				# list of admins...
				set new_group_users [concat [lindex $old_user_array 4] $new_group_users]
				##remove dublicates...				
				set indicies_to_delete [list]
				for { set i 0 } { $i < [llength $new_group_users]} { incr i } {
					for { set j [expr $i + 1] } { $j < [llength $new_group_users]} { incr j } {
						if {[lindex $new_group_users $i 1] == [lindex $new_group_users $j 1] || [lindex $new_group_users $i 3] == [lindex $new_group_users $j 3]} {
							lappend indicies_to_delete $j
						}
					}
				}
				for { set i [expr [llength $indicies_to_delete] -1] } { $i >= 0 } { set i [expr $i - 1] } {
					set new_group_users [lreplace $new_group_users $i $i]
				}				
			}
			if {[llength $old_user_array] > 5} {
				set new_group_settings [lindex $old_user_array 5]				
			}
		}
		
		puts "  merging data..."
		
		set new_group_array [list]
		lappend new_group_array $new_group_name
		if {$new_group_adminid > 0} {
			lappend new_group_array [list $new_group_id $new_group_adminid]
		} else {
			lappend new_group_array $new_group_id
		}
		lappend new_group_array $new_group_description
		lappend new_group_array $new_group_admins
		lappend new_group_array $new_group_users
		lappend new_group_array $new_group_settings		
		
		puts "  saving to file..."
		set groupfile [open "./aspects/$new_group_name" w]
		puts $groupfile $new_group_array
		close $groupfile
		
		## aaand do on pod:
		# create aspect if not exists
		puts "  saving on pod..."
		set aspect_creation_answer [get_aspectid $new_group_name 1]
		puts "         ...user aspect"
		if { $aspect_creation_answer == 0} {
			set aspect_creation_answer [exec $phantombin "create_aspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" "$new_group_name"]
		}
		# add subscriber
		puts "         ...users"
		if {[regexp {^\d+$} $aspect_creation_answer] > 0} {
			for {set i 0 } { $i < [llength $new_group_users] } {incr i} {
				puts "                 [lindex $new_group_users $i 3]"
				set user_adding_answer [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $aspect_creation_answer "-m" "ADD" "-u" [lindex $new_group_users $i 0]]
			}
		}

		# create admin-aspect if not exists
		# add admins
		puts "         ...admin aspect"
		set aspect_creation_answer [get_aspectid "$new_group_name\_a" 1]
		if { $aspect_creation_answer == 0} {
			set aspect_creation_answer [exec $phantombin "create_aspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" "$new_group_name\_a"]
		}
		puts "         ...admins"
		if {[regexp {^\d+$} $aspect_creation_answer] > 0} {
			for {set i 0 } { $i < [llength $new_group_admins] } {incr i} {
				puts "                 [lindex $new_group_admins $i 2]"
				set user_adding_answer [exec $phantombin "change_useraspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" $aspect_creation_answer "-m" "ADD" "-u" [lindex $new_group_admins $i 0]]
			}
		}
		
	} elseif {$random_stuff == 3} {
		puts "Check for zero admins/users in $group_name"
		if {[file exists "./aspects/$group_name"]} {
			set groupfile [open "./aspects/$group_name" r]
			set group_array [string trim [read $groupfile]]
			close $groupfile
			
			if {[llength [lindex $group_array 3]] == 0} {
				puts "   no admin, check for admins on pod..."
				if {[llength [lindex $group_array 1]] >= 2} {
					set adminlist_from_pod [exec "./phantomjs" "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" [lindex $group_array 1 1]]
					if {$adminlist_from_pod != "-1"} {
						foreach { h_ i_ n_ a_ g_ } $adminlist_from_pod {
							lappend [lindex $group_array 3] [list $i_ $g_ $n_ $h_ $a_]
						}
					}
				}
			} else { puts "   admin found, everything's fine" }
			
			if {[llength [lindex $group_array 3]] == 0} {
				puts "   no admin in file or pod, taking a user..."
				#still no admin, get one from users list.
				if {[llength [lindex $group_array 4]] == 0} {
					#no admins no users? check the pod!
					set userlist_from_pod [exec "./phantomjs" "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" [lindex $group_array 1 0]]
					if {$userlist_from_pod != "-1"} {
						foreach { h_ i_ n_ a_ g_ } $userlist_from_pod {
							lappend [lindex $group_array 4] [list $i_ $g_ $n_ $h_ $a_]
						}
						puts "   found user on pod, adding as an admin"
						lappend [lindex $group_array 3] [lindex $group_array 4 0]
					}
				} else {
					puts "   found user in file, adding as an admin"
					set admins_list [lindex $group_array 3]
					lappend admins_list [lindex $group_array 4 0]
					set group_array [lreplace $group_array 3 3 $admins_list]
				}
			}
			if {[llength [lindex $group_array 3]] || [llength [lindex $group_array 4]]} {
				#okay, there are admins and/or userer (usually both), so just save the stuff...
				set groupfile [open "./aspects/$group_name" w]
				puts $groupfile $group_array
				close $groupfile
			} else {
				## remove group…
				set remove_aspect_answer [exec "./phantomjs" "delete_aspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" [lindex $group_array 1 0]]				
				set remove_aspect_answer [exec "./phantomjs" "delete_aspect.js" "-d" "\{" "\} " "\\\{" "\\\} " "-a" [lindex $group_array 1 1]]
				if {[file exists "./aspects/$group_name"]} {
					file delete "./aspects/$group_name"
				}
			}
		}
	}
}

proc get_random_groupname {{source_type 0}} {
	##returns a random groupname
	## source_type = 0; no matter the source of the group
	## source_type = 1; from file
	## source_type = 2; from pod
	if {$source_type == 0} { set source_type [expr int(rand() * 2 +1)] }
	if {$source_type == 1} {
		set group_list [glob -directory "./aspects" *]
		set group_name [lindex [split [lindex $group_list [expr int(rand() * [llength $group_list])]] "/"] 2]
		if {[regexp {^\d+$} $group_name]} {
			set groupfile [open "./aspects/$group_name" r]
			set group_name [string trim [read $groupfile]]
			close $groupfile
		}
		return $group_name
	} elseif {$source_type == 2} {
		set group_list [exec "./phantomjs" "get_aspects.js" "-d" "\{" "\} " "\\\{" "\\\} "]
		set group_name [lindex $group_list [expr int(rand() * [llength $group_list])]]
		while {[regexp {^\d+$} $group_name] || [regexp {_a$} $group_name] || $group_name == "users" || $group_name == "admins"} {
			set group_name [lindex $group_list [expr int(rand() * [llength $group_list])]]
		}
		return $group_name
	}
}

proc main {} {
	##catch [exec "./phantomjs" "get_aspects.js"] returnvalue
	puts " "
	puts "checking for new stuff..."
	global phantombin
	global checkfrequency
	set my_commands [split [exec $phantombin "get_streamlike.js" "-a" "mentions" "-d" "Ŋ" "Ŋ" "N" "N"] "Ŋ"]
	puts "...checking for new stuff..."
	while { [llength $my_commands] > 0 } {
		set my_command [lrange $my_commands 0 15]
		set my_commands [lrange $my_commands 16 end]
		set my_subcommand [lindex [split [lindex $my_command 5] "\n"] 0]
		#puts $my_subcommand
		if { [regexp -nocase {(^|\s)(create|found)(\s|$)} $my_subcommand] } {
			#Group-creation
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				create_group_command $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\ncreated"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(subscribe|enter)(\s|$)} $my_subcommand] } {
			#Subscribtion
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				subscribe_command $my_command
				set done_file [open "./done/[lindex $my_command 3]" w]
				puts $done_file "$my_command \n\nsubscribed"
				close $done_file
			}
		} elseif { [regexp -nocase {(^|\s)(unsubscribe|leave)(\s|$)} $my_subcommand] } {
			#Unsubscription
			if {[file exists "./done/[lindex $my_command 3]"] == 0} {
				unsubscribe_command $my_command
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
	do_idle_stuff
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
puts "Groupbot  Copyright (C) 2012  Deus Figendi"
puts "This program comes with ABSOLUTELY NO WARRANTY;"
puts "This is free software, and you are welcome to redistribute it"
puts "under certain conditions;"
puts " "
main

vwait null
