##
# Random Post v1.4
#  by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.5.5 or greater.
#
#    R.I.P. Mom, To always be remembered; Nancy Marie Gregory.
#
# My Website - http://mc.purehype.net:81/
# Have a bug?  http://mc.purehype.net:81/bugzilla/
##

##
# This script will pull a random line from a file and post it to the channel.  The
# times to post a new line are triggered by a timer, you can set the timer to
# whatever you want per channel.
##

##
# The history log has been moved to the very bottom of this script.
##

##
# Commands (DCC Chat)
##
# randompost [add [global/#channel] <post>/remove <number>/search <string>]
#      If you don't specify add/ remove/ search, it will show you all the random
#      posts you have stored.
#
#      If you want to add a post that contains a multi lined post, separate each new
#      post with a <br>, just like html coding. This will cause the script to break
#      to the next line at that point.
#
#      If you don't specify global/#channel when doing add, it will default to global
#      (post is good for all channels).
#
#      There are replacement variables for the add post, they are
#       %chan    -- The channel.
#       %botnick -- The bot's irc nick.
#       %time    -- Current time, in '12:50 AM' format.
#       %date    -- Current date, in 'Aug. 29, 2001' format.
#       %num     -- The record number of current post.
#
# chanset <channel> mc.randompost <time>
#      Set's the number of seconds in between the random posts to the specific
#      channel.  Setting the time to 0 (default) will turn the script off for that
#      channel.
#      Example:
#        .chanset #channel mc.randompost 500
##

##
# Settings
##

# What do you want the database filename to be?
set mc_rap(database) ".randompost.dat"

# What flagged users should have access to perform the dcc .randompost add and remove
# commands?  Correct flag structure is <global>|<channel>.  Set to -|- to let anyone
# have access (anyone that can dcc chat to the bot that is).
set mc_rap(dcc_access) o|o


## SVS Client (Script Version Service) v3.0.1 ##
# Once a day, the SVS Client will connect to MC_8's SVS Server to determine if there
# is a newer version of this script available.  This will only notify users of the ne
# version via a note.  It's up to the owner of the bot to download, adjust settings
# then install the script.

# If a newer version is found, whom do you want to notify?  The notification is sent
# via a note.  Seperate each user with a space, or set this to "" to disable SVS
# notification.  For those whom know TCL; do not put this in list format, keep it in
# string format.
set mc_rap(svs:notify) "MC_8"

# Would you like to restrict the concept of a new version to stable releases only?
#   0 = No, inform of both stable and beta release versions.
#   1 = Yes, inform of only stable release versions.
set mc_rap(svs:mode) 0


##
# End of configuration, do not edit past here unless you know TCL.
##

#Script:mc_rap

set mc_rap(script)      "Random Post"
set mc_rap(version)     "v1.4"
set mc_rap(svs:script)  "randompost"
set mc_rap(svs:version) "001004000000"
set mc_rap(svs:server)  "mc.purehype.net"
set mc_rap(svs:port)    "81"
set mc_rap(svs:get)     "/svs_client_interface.tcl"
set mc_rap(svs:query)   \
	"svs=$mc_rap(svs:script)&version=$mc_rap(svs:version)"

catch {unset temp}
if {![info exists numversion] || ($numversion < "1050500")} {
	set temp(tag) "$mc_rap(script) $mc_rap(version)"
	putlog "$temp(tag) by MC_8 will only work on eggdrop 1.5.5 or greater."
	putlog "$temp(tag)  will not work with eggdrop $version."
	putlog "$temp(tag)  not loaded."
	return 1
}

setudef int mc.randompost

# Error system, v3.0
proc mc:rap:error {command error arg} {
	global mc_rap version lastbind errorInfo
	putlog "Error in script $mc_rap(script) $mc_rap(version)."
	putlog "    Error System: v3.0"
	putlog "       Last Bind: [expr {[info exists lastbind] ? $lastbind : "-NULL-"}]"
	putlog "         Command: $command"
	putlog "       Arguments: $arg"
	putlog "       Error Msg: $error"
	putlog "    Egg. Version: [expr {[info exists version] ? $version : "-NULL-"}]"
	putlog "     TCL Version: [info tclversion]"
	putlog "  TCL Patchlevel: [info patchlevel]"
	putlog "*** Please submit this bug so MC_8 can fix it.  Visit"
	putlog "*** http://mc.purehype.net:81/bugzilla/ to properly report the bug."
	putlog "*** Please include ALL info. in the bug report, including the next(s)."
	error $errorInfo
}

proc mc:rap:errchk {command arg} {
	if {![catch {eval $command $arg} return]} {return $return}
	mc:rap:error $command $return $arg
	return 0
}
# ^

bind filt - ".chanset * mc.randompost *" mc:rap:filt
proc mc:rap:filt {idx arg} {
	return [mc:rap:errchk mc:rap:filt_ [list $idx $arg]]
}
proc mc:rap:filt_ {idx arg} {
	scan $arg {%s %s} cmd chan
	utimer 1 [list mc:rap:set_timers $chan 1]
	return $arg
}

proc mc:rap:randompost {chan} {
	return [mc:rap:errchk mc:rap:randompost_ [list $chan]]
}
proc mc:rap:randompost_ {chan} {
	global mc_rap botnick
	if {![file exists $mc_rap(database)]} {
		set io [open $mc_rap(database) w]
		close $io
	}
	mc:rap:set_timers $chan 1
	if {(![validchan $chan]) || (![mc:rap:chanint $chan mc.randompost]) ||
	    (![onchan $botnick $chan])} {return 0}
	set lchan [string tolower $chan]
	set io [open $mc_rap(database) r]
	set list ""
	while {![eof $io]} {
		gets $io line
		if {([lindex $line 1] != "global") &&
		    ([string tolower [lindex $line 1]] != $lchan)} {continue}
		lappend list $line
	}
	close $io
	if {![llength $list]} {return 0}
	if {[llength $list] > "1"} {
		if {![info exists mc_rap(:rand:$lchan:)]} {
			set mc_rap(:rand:$lchan:) 0
		}
		set rand [rand [llength $list]]
		while {$rand == $mc_rap(:rand:$lchan:)} {
			set rand [rand [llength $list]]
		}
		set mc_rap(:rand:$lchan:) $rand
	} else {
		set rand 0
	}
	set list [lindex $list $rand]
	set num [lindex $list 0]
	set list [lindex $list 2]
	set list [mc:rap:replace $list [list %num $num \
	                                     %time [strftime "%l:%M %PM"] \
	                                     %date [strftime "%b. %d, %Y"] \
	                                     %chan $lchan \
	                                     %botnick $botnick]]
	foreach post $list {puthelp "PRIVMSG $chan :$post"}
}

# .randompost [add [global/#channel] <post>/remove <number>/search <string>]
bind dcc - randompost mc:rap:dcc:randompost
proc mc:rap:dcc:randompost {hand idx arg} {
	return [mc:rap:errchk mc:rap:dcc:randompost_ [list $hand $idx $arg]]
}
proc mc:rap:dcc:randompost_ {hand idx arg} {
	global mc_rap
	if {![file exists $mc_rap(database)]} {
		set io [open $mc_rap(database) w]
		close $io
	}
	if {[llength [split $arg]] < "2"} {set command ""} \
	else {scan "$arg\015" "%s %\[^\015\]" command arg}
	if {([join $arg] == "") && ($command != "")} {
		putdcc $idx "What?  You need '.help randompost'"
		return 0
	}
	switch -- [string tolower $command] {
		add {
			set chan [lindex [split $arg] 0]
			if {([string tolower $chan] == "global") || ([validchan $chan])} {
				set chan [string tolower $chan]
				set arg [join [lrange [split $arg] 1 end]]
			} else {
				set chan global
			}
			if {(($chan == "global") && (![matchattr $hand $mc_rap(dcc_access)]) &&
			     ($mc_rap(dcc_access) != "-|-")) ||
			    (($chan != "global") && (![matchattr $hand $mc_rap(dcc_access) $chan]) &&
			     ($mc_rap(dcc_access) != "-|-"))} {
				putdcc $idx "You do not have access to add to the $chan post list."
				putcmdlog "#$hand# (denied, no access): randompost add $chan $arg"
				return 0
			}
			if {$arg == ""} {
				putdcc $idx "What?  You need '.help randompost'"
				return 0
			}
			set arg [mc:rap:replace $arg [list <br> \015 <Br> \015 <bR> \015 <BR> \015]]
			set arg [split $arg \015]
			set num [mc:rap:find_next_num]
			set io [open $mc_rap(database) a]
			puts $io [list $num $chan $arg]
			close $io
			putdcc $idx "Added record $num  ($chan):"
			foreach post $arg {putdcc $idx "  $post"}
			putcmdlog "#$hand# randompost add $chan"
			foreach post $arg {putcmdlog "     $post"}
			return 0
		}
		remove {
			set io [open $mc_rap(database) r]
			set list ""
			set found 0
			while {![eof $io]} {
				gets $io line
				if {[lindex $line 0] != [lindex [split $arg] 0]} {
					lappend list $line
				} else {
					set chan [string tolower [lindex $line 1]]
					set found 1
				}
			}; close $io
			if {(($chan == "global") && (![matchattr $hand $mc_rap(dcc_access)]) &&
			     ($mc_rap(dcc_access) != "-|-")) ||
			    (($chan != "global") && (![matchattr $hand $mc_rap(dcc_access) $chan]) &&
			     ($mc_rap(dcc_access) != "-|-"))} {
				putdcc $idx "You do not have access to remove from the $chan post list."
				putcmdlog \
					"#$hand# (denied, no access): randompost remove [lindex [split $arg] 0]"
				return 0
			}
			if {!$found} {
				putdcc $idx "Entrie [lindex [split $arg] 0] not found."
				return 0
			}
			set io [open $mc_rap(database) w]
			foreach post $list {puts $io $post}
			close $io
			putdcc $idx "Removed entree #[lindex [split $arg] 0]."
			putcmdlog "#$hand# randompost remove [lindex [split $arg] 0]"
			return 0
		}
		search {
			set arg *[mc:rap:replace $arg [list " " *]]*
			while {[regsub -all {\*\*} $arg * arg]} {}
			putdcc $idx "Search for '$arg' ..."
			putdcc $idx " "
			set io [open $mc_rap(database) r]
			set list ""
			while {![eof $io]} {
				gets $io line
				if {[join $line] == ""} {continue}
				if {[string match $arg $line]} {lappend list $line}
			}
			close $io
			foreach post $list {
				putdcc $idx "Entrie [lindex $post 0]  ([lindex $post 1]):"
				foreach line [lindex $post 2] {putdcc $idx "   $line"}
			}
			if {[llength $list]} {putdcc $idx " "}
			putdcc $idx \
				"[llength $list] matche[expr {[llength $list] == "1"?"":"s"}] found."
			putcmdlog "#$hand# randompost search $arg"
			return 0
		}
		default {
			mc:rap:dcc:randompost $hand $idx "search *"
			return 0
		}
	}
}

bind filt - ".help *" mc:rap:filt:help
proc mc:rap:filt:help {idx arg} {
	return [mc:rap:errchk mc:rap:filt:help_ [list $idx $arg]]
}
proc mc:rap:filt:help_ {idx arg} {
	set cmd [lindex [split $arg] 0]
	set help [lindex [split $arg] 1]
	if {[string tolower $help] == "randompost"} {
		set syntax "\[add <\[global/#channel\] post>/remove <number>/search \[string\]\]"
		putdcc $idx "### \002randompost\002 $syntax"
		putdcc $idx " If you don't specify add/ remove/ search,"
		putdcc $idx " it will show you all the random posts  "
		putdcc $idx " you have stored.                       "
		putdcc $idx "                                        "
		putdcc $idx " If you want to add a post that contains"
		putdcc $idx " a multi lined post, separate each new  "
		putdcc $idx " post with a <br>, just like html       "
		putdcc $idx " coding. This will cause the script to  "
		putdcc $idx " break to the next line at that point.  "
		putdcc $idx "                                        "
		putdcc $idx " If you don't specify global/#channel   "
		putdcc $idx " when doing add, it will default to     "
		putdcc $idx " global (post is good for all channels)."
		putdcc $idx "                                        "
		putdcc $idx " There are replacement variables for the "
		putdcc $idx " add post, they are %chan, %botnick,    "
		putdcc $idx " %time & %date                          "
		putcmdlog "#[idx2hand $idx]# help randompost"
		return ""
	} elseif {[string tolower $help] == "all"} {
		putdcc $idx "###  commands for the \002mc.randompost script\002"
		putdcc $idx "  \002randompost\002"
		putdcc $idx " "
	}
	return $arg
}

proc mc:rap:find_next_num {} {
	return [mc:rap:errchk mc:rap:find_next_num_ ""]
}
proc mc:rap:find_next_num_ {} {
	global mc_rap
	if {![file exists $mc_rap(database)]} {
		set io [open $mc_rap(database) w]
		close $io
	}
	set io [open $mc_rap(database) r]
	set num 0
	while {![eof $io]} {
		gets $io line
		if {[lindex $line 0] > $num} {set num [lindex $line 0]}
	}
	close $io
	return [expr $num+1]
}

## (start) initialize timers
proc mc:rap:set_timers {{channel ""} {reset 0}} {
	return [mc:rap:errchk mc:rap:set_timers_ [list $channel $reset]]
}
proc mc:rap:set_timers_ {channel reset} {
	if {$channel == ""} {
		set channel [channels]
	} else {
		if {![validchan $channel]} {return 0}
	}
	foreach chan [string tolower $channel] {
		set continue 0
		foreach timer [utimers] {
			if {[lindex $timer 1] == [list mc:rap:randompost $chan]} {
				if {$reset} {
					killutimer [lindex $timer 2]
				} else {
					set continue 1
					break
				}
			}
		}
		if {$continue} {continue}
		set x [mc:rap:chanint $chan mc.randompost]
		if {!$x} {continue}
		utimer $x [list mc:rap:randompost $chan]
	}
}
if {[info exists server] && ($server != "")} {mc:rap:set_timers}

bind evnt - init-server mc:rap:initserver
proc mc:rap:initserver {type} {mc:rap:set_timers}
## (stop) initialize timers


## More Tools quick procs.
## -- http://mc.purehype.net:81/script_info.tcl?script=moretools

# badargs <args> <min_llength> <max_llength|end> <argNames>
#     version:
#       v1.0
proc mc:rap:badargs {{args ""}} {
	if {[llength $args] < 4} {
		error {
			wrong # args: should be "mc:rap:badargs args min_llength max_llength argNames"
		}
	}

	set index 0
	foreach varName [list args min max names] {
		set check_$varName [lindex $args $index]
		incr index
	}

	if {[regexp -- {([^0-9])} $check_min -> bad]} {
		error "bad number \"$bad\" in: $check_min"
	}
	if {[regexp -- {([^0-9])} $check_max -> bad] && ($check_max != "end")} {
		error "bad number \"$bad\" in: $check_max"
	}

	# Make sure $check_args is in list format, if not then make it so.
	# Were not going to use 2list here, don't want to evoke a 'too many nested calls
	# to Tcl_EvalObj' error since '2list' uses on this proc.
	if {[catch {llength $check_args} llength]} {
		set check_args [split $check_args]
		set llength $check_args
	}

	if {($llength < $check_min) || (($llength != "end") && ($llength > $check_max))} {
		if {[info level] == "1"} {return 1}
		error "wrong # args: should be \"[lindex [info level -1] 0] $check_names\""
	}; return 0
}

# 2list <text>
#     version:
#       v1.0
proc mc:rap:2list {{args ""}} {
	mc:rap:badargs $args 1 1 "text"
	mc:rap:unlist $args text

	return [expr {([catch {llength $text}])?[split $text]:$text}]
}

# unlist <argsList> [varName1] [varName2] ... [varNameN]
#     version:
#       v1.0
proc mc:rap:unlist {{args ""}} {
	mc:rap:badargs $args 1 end "argsList ?varName varName ...?"
	set argList [lindex $args 0]
	set argList [expr {([catch {llength $argList}])?[split $argList]:$argList}]
	set argNames [lrange $args 1 end]
	if {![llength $argNames]} {
		return [expr {(![catch {llength $argList}])?
			[join $argList]:$argList}]
	}
	for {set index 0} {$index < [llength $argNames]} {incr index 1} {
		set argName     [lindex $argNames $index]
		set argListItem [lindex $argList  $index]

		set argName_ [expr {([catch {llength $argName}])?[split $argName]:$argName}]
		set setTo   [lindex $argName_ 1]
		set argName [lindex $argName_ 0]

		if {$argName == ""} {continue}

		upvar 1 $argName var

		if {[expr $index+1] > [llength $argList]} {
			if {[llength $argName_] == "2"} {set var $setTo}
		} else {
			if {$argName == "args"} {
				set var [lrange $argList $index end]
				incr index [expr [llength $var]-1]
			} else {set var $argListItem}
		}
	}; return $index
}

# replace [switches] <text> <substitutions>
#     version:
#       v1.3
proc mc:rap:replace {{args ""}} {
	mc:rap:badargs $args 2 4 "?switches? text substitutions"
	set switches ""
	for {set i 0} {[string match -* [set arg [lindex $args $i]]]} {incr i} {
		if {![regexp -- {^-(nocase|-)$} $arg -> switch]} {
			error "bad switch \"$arg\": must be -nocase, or --"
		}
		if {$switch == "-"} {
			incr i
			break
		}; lappend switches $switch
	}
	set nocase [expr {([lsearch -exact $switches "nocase"] >= "0") ? 1 : 0}]
	set text [lindex $args $i]
	set substitutions [lindex $args [expr $i+1]]
	mc:rap:badargs [lrange $args $i end] 2 2 "?switches? text substitutions"

	# Check to see if $substitutions is in list format, if not make it so.
	set substitutions [mc:rap:2list $substitutions]

	if {[info tclversion] >= "8.1"} {
		return [expr {($nocase)?
			[string map -nocase $substitutions $text]:
			[string map $substitutions $text]}]
	}

	set re_syntax {([][\\\*\+\?\{\}\,\(\)\:\.\^\$\=\!\|])}
	foreach {a b} $substitutions {
		regsub -all -- $re_syntax $a {\\\1} a
		if {$nocase} {regsub -all -nocase -- $a $text $b text} \
		else {regsub -all -- $a $text $b text}
	}; return $text
}

# chanint <channel> <flag>
#     version:
#       v3.2
proc mc:rap:chanint {{args ""}} {
	mc:rap:badargs $args 2 2 "channel integer_flag"
	mc:rap:unlist $args channel flag

	set flag [string tolower $flag]

	if {![validchan $channel]} {error "no such channel record"}

	# Try the 'channel' commands' 'get' option first, it's faster since it is written
	# in C by the eggdrop development team.
	if {![catch {channel get $channel $flag} output]} {return $output}

	foreach chaninfo [string tolower [channel info $channel]] {
		# Using 2list here because it's only in string format.  I told the eggdrop
		# development team of this error, but have yet to see them fix it.
		set chaninfo [mc:rap:2list $chaninfo]

		set name [join [expr {([info tclversion] >= "8.1")?
			[lrange $chaninfo 0 end-1]:
			[lrange $chaninfo 0 [expr [llength $chaninfo]-2]]}]]

		if {$name == $flag} {return [lindex $chaninfo end]}
	}; return -1
}

## End of More Tools quick procs.


## SVS v3.0.1
set mc_rap(svs:client_version) "v3.0.1"
if {![info exists mc_rap(svs:mode)] ||
    ![regexp -- {^(1|0)$} $mc_rap(svs:mode)]} {
	set mc_rap(svs:mode) 0
}
if {![info exists mc_rap(svs:notify)]} {
	if {![info exists owner]} {set owner ""}
	set mc_rap(svs:notify) $owner
}

bind time - "00 00 *" mc:rap:do_svs
proc mc:rap:do_svs {{args ""}} {
	global mc_rap tcl_platform
	if {[catch {
	        socket -async $mc_rap(svs:server) $mc_rap(svs:port)
	           } sid]} {
		putloglev d * "$mc_rap(script): SVS socket error: $sid"
		return 1
	}

	# This block of code is to get a standard User-Agent line of information, as
	# proposed in http://www.mozilla.org/build/revised-user-agent-strings.html
	foreach array_name [list platform os osVersion machine] {
		set temp($array_name) [lindex [array get tcl_platform $array_name] 1]
	}
	switch -- $temp(platform) {
		windows {
			switch -- $temp(os) {
				Windows {set temp(2) Win$temp(osVersion)}
				"Windows 95" {
					if {$temp(osVersion) < "4.10"} {
						set temp(2) Win95
					} else {
						set temp(2) Win98
					}
				}
				"Windows 98" {set temp(2) Win98}
				"Windows NT" {
					if {$temp(osVersion) >= "5.0"} {
						set temp(2) "Windows NT $temp(osVersion)"
					} else {
						set temp(2) WinNT$temp(osVersion)
					}
				}
				default {
					set temp(2) "$temp(os) $temp(osVersion)"
				}
			}
		}
		unix {
			set temp(2) "unix $temp(machine)"
		}
		macintosh {
			set temp(2) $temp(machine)
		}
		default {
			set temp(2) "$temp(os) $temp(osVersion) $temp(machine)"
		}
	}
	set temp(user_agent) "Mozilla/5.001 ($temp(platform); U; $temp(2); en) "
	append temp(user_agent) "Gecko/25250101 $mc_rap(svs:script)/"
	append temp(user_agent) "$mc_rap(svs:version) SVS_Client/"
	append temp(user_agent) "$mc_rap(svs:client_version)"
	# ^

	fconfigure $sid -blocking 0 -buffering line
	set tout [after 60000 "mc:rap:svs_talk $sid timeout"]
	fileevent $sid readable "mc:rap:svs_talk $sid $tout"
	puts $sid "GET $mc_rap(svs:get)?$mc_rap(svs:query) HTTP/1.0\
	         \nHost: $mc_rap(svs:server):$mc_rap(svs:port)\
	         \nUser-Agent: $temp(user_agent)\n"
	flush $sid
}

proc mc:rap:svs_talk {sid tout} {
	global mc_rap
	set array [list svs temp $sid]
	if {$tout == "timeout"} {
		set temp(1) "$mc_rap(svs:server):$mc_rap(svs:port)"
		putloglev d * \
			"$mc_rap(script): SVS Warning: Timed out connecting to $temp(1)."
		catch {unset mc_rap($array)}
		close $sid
		return 0
	}
	if {[eof $sid]} {
		catch {unset mc_rap($array)}
		close $sid
		return 1
	}
	gets $sid get
	after cancel $tout
	if {![info exist mc_rap($array)]} {
		if {$get == ""} {set mc_rap($array) 1}
		return -1
	}
	if {($get == "") || [catch {llength $get}]} {
		return -2
	}
	switch -- [lindex $get 0] {
		003 {
			set temp(reply) [lrange $get 1 end]
			set temp(reply:0) [lindex $temp(reply) 0]
			set temp(reply:1) [lindex $temp(reply) 1]
			set temp(reply:2) [lindex $temp(reply) 2]
			set temp(reply:3) [lindex $temp(reply) 3]
			set temp(reply:4) [lindex $temp(reply) 4]
			set temp(reply:5) [lindex $temp(reply) 5]
			if {$temp(reply:0) != $mc_rap(svs:script)} {
				set temp(1) "wanted $mc_rap(svs:script), got $temp(reply:0)"
				putloglev d * "$mc_rap(script): SVS Error: $temp(1)"
				unset mc_rap($array)
				close $sid
				return -3
			}
			if {$mc_rap(svs:mode)} {
				set temp(svs:version) [string range $mc_rap(svs:version) 0 8]999
			} else {
				set temp(svs:version) [string range $mc_rap(svs:version) 0 11]
			}
			if {$temp(reply:1) > $temp(svs:version)} {
				set temp(note) $temp(reply:5)
				regsub -all -- %0 $temp(note) $temp(reply:0) temp(note)
				regsub -all -- %1 $temp(note) $temp(reply:1) temp(note)
				regsub -all -- %2 $temp(note) $temp(reply:2) temp(note)
				regsub -all -- %3 $temp(note) $temp(reply:3) temp(note)
				regsub -all -- %4 $temp(note) $temp(reply:4) temp(note)
				regsub -all -- %version $temp(note) $mc_rap(version) temp(note)
				foreach temp(to) [split $mc_rap(svs:notify) ",; "] {
					if {[string trim $temp(to)] == ""} {continue}
					regsub -- %nick $temp(note) $temp(to) temp(note2)
					set temp(lunotes) [notes $temp(to) -[notes $temp(to)]]]
					if {[string match *$temp(note2)* $temp(lunotes)]} {
						set temp(found_note) 0
						foreach temp(unote) $temp(lunotes) {
							if {$temp(note2) == [lindex $temp(unote) 2]} {
								set temp(found_note) 1
								break
							}
						}
						if {$temp(found_note)} {continue}
					}
					set temp(error) "sending note to $temp(to) -> "
					switch -- [sendnote SVS $temp(to) $temp(note2)] {
						0 {
							if {![validuser $temp(to)]} {
								append temp(error) "invalid user"
							} else {append temp(error) "unknown error"}
							putloglev d * \
								"$mc_rap(script): SVS sendnote error: $temp(error)"
						}
						3 {
							append temp(error) "notebox too full"
							putloglev d * \
								"$mc_rap(script): SVS sendnote error: $temp(error)"
						}
					}
				}
			}
			unset mc_rap($array)
			close $sid
			return 2
		}
	}
}
## ^

putlog "$mc_rap(script) $mc_rap(version) by MC_8 loaded."

##
# History
##
# v1.4 (09.20.01)
#  MC_8 - BoR0 - Fixed special character handling.
#                Bugzilla number: 153
#  MC_8 -      - Fixed 21 spelling errors.
#  MC_8 -      - Added `unlist` tcl command.  none -> v1.0
#  MC_8 -      - Added `2list` tcl command.  none -> v1.0
#  MC_8 -      - Added `badargs` tcl command.  none -> v1.0
#  MC_8 -      - Upgraded `chanint` tcl command.  v1.0 -> v3.2
#  MC_8 -      - Upgraded `replace` tcl command.  v1.0 -> v1.3
#  MC_8 -      - Upgraded SVS Client.  v2.0 -> v3.0.1
#  MC_8 -      - Upgraded Error Catching System.  old -> v3.0
#  MC_8 - BoR0 - Fixed problem with this script setting the proper timers if the
#                script was initialized while not connected to a server.
#                Bugzilla number: 149
#
# v1.3 (11.25.01)
#  MC_8 - kk - Fixed mIRC compliant color post support.
#  MC_8 -    - DCC command issues with optional entree sections.
#  MC_8 -    - Added a better error output system, for debugging purposes.
#  MC_8 -    - Added filter bind to watch for 'chanset' changes.
#  MC_8 -    - Rewrote the entire script.
#  MC_8 - kk - Wasn't posting correct information.
#  MC_8 -    - Upgraded SVS from v1.2 to v2.0.
#
# v1.2.1 (09.17.01)
#  MC_8 - Snillting - Global posting wasn't following rules set by
#                     mc_rap(dcc_access).
#
# v1.2 (08.29.01)
#  MC_8 - Phillip Lewis - Added the %num replacement variable.
#
# v1.1 (02.08.01)
#  MC_8 - BeastNH - Added mc_rap(dcc_access) variable.  It defines who can add and
#                   remove random post entries.
#
# v1.0 (02.03.01)
#  MC_8 - BeastNH - initial release
##
