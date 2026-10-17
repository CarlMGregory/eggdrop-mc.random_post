##
# Random Post v1.3 by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.5.5 or greater.
#
# My SVS Website - http://mc.purehype.net:81/
##

##
# This script will pull a random line from a file and post it to the channel.
# The times to post a new line are triggered by a timer, you can set the timer
# to whatever you want per channel.
##

##
# History
##
# v1.3 (11.25.01)
#  MC_8 - kk - Fixed mIRC compliant color post support.
#  MC_8 - DCC command issues with optional entrie sections.
#  MC_8 - Added a better error output system, for debugging purposes.
#  MC_8 - Added filter bind to watch for 'chanset' changes.
#  MC_8 - Rewrote the entire script.
#  MC_8 - kk - Wasn't posting correct information.
#  MC_8 - Upgraded SVS from v1.2 to v2.0.
#
# v1.2.1 (09.17.01)
#  MC_8 - Snillting - Global posting wasn't following rules set by mc_rap(dcc_access).
#
# v1.2 (08.29.01)
#  MC_8 - Phillip Lewis - Added the %num replacment veriable.
#
# v1.1 (02.08.01)
#  MC_8 - BeastNH - Added mc_rap(dcc_access) veriable.  It defines who can add
#                   and remove random post entries.
#
# v1.0 (02.03.01)
#  MC_8 - BeastNH - inital release
##

##
# Commands (DCC Chat)
##
# .randompost [add [global/#channel] <post>/remove <number>/search <string>]
#      If you don't specify add/remove/search, it will show you all the random
#      posts you have stored.
#  
#      If you want to add a post that contains a multi lined post, seperate each
#      new post with a <br>, just like html coding. This will cause the script
#      to break to the next line at that point.
#
#      If you don't specify global/#channel when doing add, it will default to
#      global (post is good for all channels).
#
#      There are replacment veriables for the add post, they are
#       %chan    -- The channel.
#       %botnick -- The bot's irc nick.
#       %time    -- Current time, in '12:50 AM' format.
#       %date    -- Current date, in 'Aug. 29, 2001' format.
#       %num     -- The record number of current post.
##

##
# Settings
##
# Note:
#  There is one setting you set from dcc chat with the bot using .chanset.
#   mc.randompost <time>   Set's the number of seconds inbetween the random
#                          posts to the specific channel.  Setting the time
#                          to 0 (default) will turn the script off for that
#                          channel.
#
#  Example from dcc chat with the bot:
#   .chanset #channel mc.randompost 500

# What do you want the database filename to be?
set mc_rap(database) ".randompost.dat"

# What flaged users should have access to perform the dcc .randompost add and remove
# commands?
# Flag structur:  <global>|<channel>
# Set to -|- to let anyone have access (anyone that can dcc chat to the bot that is).
set mc_rap(dcc_access) o|o


## MC SVS (Script Version Service) v2.0 ##
# Do you want the bot to connection to MC_8's SVS to see if there are newer versions
# of this script avilable?  It will only tell you -- It's up to you to get the newest
# version (I decided not to auto update the code, there may be new features in the
# newest script that may require your attention).
# 0=no/1=yes
set mc_rap(svs:enabled) 1

# Once a day the script will check with the SVS -- this specifies when
# that should happen.  The setting should be the hour (military).
# examples:
#  set mc_rap(svs:check) 0   ;#This is at Midnight
#  set mc_rap(svs:check) 5   ;#This is at 5am
#  set mc_rap(svs:check) 13  ;#This is at 1pm
#  set mc_rap(svs:check) 23  ;#This is at 11pm
set mc_rap(svs:check) 3

# Upon finding a newer version of this script, who do you want this script
# to send a note to telling them of this newer version?
# If more than 1 user is to be notified, seperate each user with a
# ' ' (space).
set mc_rap(svs:notify) "MC_8"

# Do you want even beta version notified to whomever you have set?  Or just
# stable releases of the script?
#  0 = Tell me about all version, even beta versions.
#  1 = Just tell me about new stable versions.
set mc_rap(svs:stableonly) 0



##
# End of configuration, do not edit past here unless you know TCL.
##

set mc_rap(script)      "Random Post"
set mc_rap(version)     "v1.3"
set mc_rap(svs:script)  "randompost"
set mc_rap(svs:version) "001003000000"
set mc_rap(svs:server)  "mc.purehype.net"
set mc_rap(svs:port)    "81"
set mc_rap(svs:get)     "/"
set mc_rap(svs:query)   "svs=$mc_rap(svs:script)&version=$mc_rap(svs:version)"

if {$numversion < "1050500"} {
 putlog "$mc_rap(script) $mc_rap(version) by MC_8 will only work on eggdrop 1.5.5 or greater."
 putlog "$mc_rap(script) $mc_rap(version)  will not work with eggdrop $version."
 putlog "$mc_rap(script) $mc_rap(version)  not loaded."
 return 1
}

setudef int mc.randompost

proc mc:rap:error {bindproc error {arg ""}} {
 global mc_rap version lastbind
 putlog "Error in script $mc_rap(script) $mc_rap(version)."
 putlog "       Last bind: $lastbind"
 putlog "       Procedure: $bindproc"
 putlog "            Args: $arg"
 putlog " Eggdrop version: $version"
 putlog "     TCL version: [info tclversion]"
 putlog "*** Please email this bug information to MC_8, his latest"
 putlog "*** email address should be on http://mc.purehype.net:81/"
 putlog "*** Please include the next line in the email as well."
 error $error
}

proc mc:rap:errchk {command arg} {
 if {[catch {eval $command $arg} return]} {
  mc:rap:error $command $return $arg; return 0
 }; return $return
}

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
 if {![file exists $mc_rap(database)]} {set io [open $mc_rap(database) w]; close $io}
 mc:rap:set_timers $chan 1
 if {(![validchan $chan]) || (![mc:rap:chanint $chan mc.randompost]) ||
     (![onchan $botnick $chan])} {return 0}
 set lchan [string tolower $chan]
 set io [open $mc_rap(database) r]; set list ""
 while {![eof $io]} {
  gets $io line
  if {([lindex $line 1] != "global") &&
      ([string tolower [lindex $line 1]] != $lchan)} {continue}
  lappend list $line
 };close $io
 if {![llength $list]} {return 0}
 if {[llength $list] > "1"} {
  if {![info exists mc_rap(:rand:$lchan:)]} {set mc_rap(:rand:$lchan:) 0}
  set rand [rand [llength $list]]
  while {$rand == $mc_rap(:rand:$lchan:)} {set rand [rand [llength $list]]}
  set mc_rap(:rand:$lchan:) $rand
 } else {set rand 0}
 set list [lindex $list $rand]
 set num [lindex $list 0]; set list [lindex $list 2]
 set list [mc:rap:replace $list [list %num $num %time [strftime "%l:%M %PM"] %date [strftime "%b. %d, %Y"] %chan $lchan %botnick $botnick]]
 foreach post $list {puthelp "PRIVMSG $chan :$post"}
}

# .randompost [add [global/#channel] <post>/remove <number>/search <string>]
bind dcc - randompost mc:rap:dcc:randompost
proc mc:rap:dcc:randompost {hand idx arg} {
 return [mc:rap:errchk mc:rap:dcc:randompost_ [list $hand $idx $arg]]
}
proc mc:rap:dcc:randompost_ {hand idx arg} {
 global mc_rap
 if {![file exists $mc_rap(database)]} {set io [open $mc_rap(database) w]; close $io}
 if {[llength [split $arg]] < "2"} {set command ""} \
 else {scan "$arg\015" "%s %\[^\015\]" command arg}
 if {([join $arg] == "") && ($command != "")} {
  putdcc $idx "What?  You need '.help randompost'"; return 0
 }
 switch -- [string tolower $command] {
  add {
   if {([string tolower [lindex $arg 0]] == "global") || ([string index $arg 0] == "#")} {
    set chan [string tolower [lindex $arg 0]]; set arg [lrange $arg 1 end]
   } else {set chan global}
   if {(($chan == "global") && (![matchattr $hand $mc_rap(dcc_access)]) &&
        ($mc_rap(dcc_access) != "-|-")) ||
       (($chan != "global") && (![matchattr $hand $mc_rap(dcc_access) $chan]) &&
        ($mc_rap(dcc_access) != "-|-"))} {
    putdcc $idx "You do not have access to add to the $chan post list."
    putcmdlog "#$hand# (denied, no access): randompost add $chan $arg"
    return 0
   }
   if {$arg == ""} {putdcc $idx "What?  You need '.help randompost'"; return 0}
   set arg [mc:rap:replace $arg [list <br> \015 <Br> \015 <bR> \015 <BR> \015]]
   set arg [split $arg \015]
   set num [mc:rap:find_next_num]
   set io [open $mc_rap(database) a]; puts $io [list $num $chan $arg]; close $io
   putdcc $idx "Added record $num  ($chan):"
   foreach post $arg { putdcc $idx "  $post" }
   putcmdlog "#$hand# randompost add $chan"
   foreach post $arg {putcmdlog "     $post"}; return 0
  }
  remove {
   set io [open $mc_rap(database) r]; set list ""; set found 0
   while {![eof $io]} {
    gets $io line
    if {[lindex $line 0] != [lindex $arg 0]} {lappend list $line} \
    else {
     set chan [string tolower [lindex $line 1]]
     set found 1
    }
   }; close $io
   if {(($chan == "global") && (![matchattr $hand $mc_rap(dcc_access)]) &&
        ($mc_rap(dcc_access) != "-|-")) ||
       (($chan != "global") && (![matchattr $hand $mc_rap(dcc_access) $chan]) &&
        ($mc_rap(dcc_access) != "-|-"))} {
    putdcc $idx "You do not have access to remove from the $chan post list."
    putcmdlog "#$hand# (denied, no access): randompost remove [lindex $arg 0]"
    return 0
   }
   if {!$found} {putdcc $idx "Entrie [lindex $arg 0] not found."; return 0}
   set io [open $mc_rap(database) w]; foreach post $list {puts $io $post}; close $io
   putdcc $idx "Removed entrie #[lindex $arg 0]."
   putcmdlog "#$hand# randompost remove [lindex $arg 0]"; return 0
  }
  search {
   set arg *[mc:rap:replace $arg [list " " *]]*
   while {[regsub -all {\*\*} $arg * arg]} {}
   putdcc $idx "Search for '$arg' ..."
   putdcc $idx " "
   set io [open $mc_rap(database) r]; set list ""
   while {![eof $io]} {
    gets $io line
    if {[join $line] == ""} {continue}
    if {[string match $arg $line]} {lappend list $line}
   };close $io
   foreach post $list {
    putdcc $idx "Entrie [lindex $post 0]  ([lindex $post 1]):"
    foreach line [lindex $post 2] {putdcc $idx "   $line"}
   }
   if {[llength $list]} {putdcc $idx " "}
   if {[llength $list] == "1"} {set s ""} else {set s s}
   putdcc $idx "[llength $list] matche$s found."
   putcmdlog "#$hand# randompost search $arg"; return 0
  }
  default {mc:rap:dcc:randompost $hand $idx "search *"; return 0}
 }
}

bind filt - ".help *" mc:rap:filt:help
proc mc:rap:filt:help {idx arg} {
 return [mc:rap:errchk mc:rap:filt:help_ [list $idx $arg]]
}
proc mc:rap:filt:help_ {idx arg} {
 scan $arg {%s %s} cmd help
 if {[string tolower $help] == "randompost"} {
  putdcc $idx "### \002randompost\002 \[add <\[global/#channel\] post>/remove <number>/search \[string\]\]"
  putdcc $idx " If you don't specify add/remove/search,"
  putdcc $idx " it will show you all the random posts  "
  putdcc $idx " you have stored.                       "
  putdcc $idx "                                        "
  putdcc $idx " If you want to add a post that contains"
  putdcc $idx " a multi lined post, seperate each new  "
  putdcc $idx " post with a <br>, just like html       "
  putdcc $idx " coding. This will cause the script to  "
  putdcc $idx " break to the next line at that point.  "
  putdcc $idx "                                        "
  putdcc $idx " If you don't specify global/#channel   "
  putdcc $idx " when doing add, it will default to     "
  putdcc $idx " global (post is good for all channels)."
  putdcc $idx "                                        "
  putdcc $idx " There are replacment veriables for the "
  putdcc $idx " add post, they are %chan, %botnick,    "
  putdcc $idx " %time & %date                          "
  putcmdlog "#[idx2hand $idx]# help randompost"
  return ""
 } elseif {[string tolower $help] == "all"} {
  putdcc $idx "###  commands for the \002mc.randompost script\002"
  putdcc $idx "  \002randompost\002"
  putdcc $idx " "
 }; return $arg
}

proc mc:rap:find_next_num {} {
 return [mc:rap:errchk mc:rap:find_next_num_ ""]
}
proc mc:rap:find_next_num_ {} {
 global mc_rap
 if {![file exists $mc_rap(database)]} {set io [open $mc_rap(database) w]; close $io}
 set io [open $mc_rap(database) r]; set num 0
 while {![eof $io]} {
  gets $io line
  if {[lindex $line 0] > $num} {set num [lindex $line 0]}
 }; close $io; return [expr $num+1]
}

proc mc:rap:replace {text subs} {
 return [mc:rap:errchk mc:rap:replace_ [list $text $subs]]
}
# v1.0
proc mc:rap:replace_ {text subs} {
 if {![catch {string map -nocase $subs $text} output]} {return $output}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $text [lindex $subs [expr $i+1]] text
 }; return $text
}

proc mc:rap:chanint {channel int} {
 return [mc:rap:errchk mc:rap:chanint_ [list $channel $int]]
}
# v1.0
proc mc:rap:chanint_ {channel int} {
 if {![validchan $channel]} {return -code error "no such channel record"}
 set list [channel info $channel]
 for {set i 0} {![regexp -- {^[0-9]*:[0-9]*$} [lindex $list $i]]} {incr i} {}
 for {} {[regexp -- {^[0-9]*:[0-9]*$} [lindex $list $i]]} {incr i} {}
 set list [lrange $list $i end]
 foreach info [string tolower $list] {
  if {[lindex $info 0] == [string tolower $int]} {return [lindex $info 1]}
 };return -1
}

proc mc:rap:set_timers {{channel ""} {reset 0}} {
 return [mc:rap:errchk mc:rap:set_timers_ [list $channel $reset]]
}
proc mc:rap:set_timers_ {{channel ""} {reset 0}} {
 if {$channel == ""} {set channel [channels]} \
 else { if {![validchan $channel]} {return 0} }
 foreach chan [string tolower $channel] {
  set continue 0
  foreach timer [utimers] {
   if {[lindex $timer 1] == [list mc:rap:randompost $chan]} {
    if {$reset} {killutimer [lindex $timer 2]} \
    else {set continue 1; break}
   }
  }; if {$continue} {continue}
  set x [mc:rap:chanint $chan mc.randompost]; if {!$x} {continue}
  utimer $x [list mc:rap:randompost $chan]
 }
}; mc:rap:set_timers

## SVS v2.0
if {(![info exists mc_rap(svs:enabled)]) ||
    (![regexp -- {^(0|1)$} $mc_rap(svs:enabled)])} {set mc_rap(svs:enabled) 0}
if {(![info exists mc_rap(svs:check)]) ||
    ([regexp -- {[^0-9]} $mc_rap(svs:check)])} {set mc_rap(svs:check) 0}
if {![info exists mc_rap(svs:notify)]} {set mc_rap(svs:notify) $owner}
if {(![info exists mc_rap(svs:stableonly)]) ||
    (![regexp -- {^(0|1)$} $mc_rap(svs:stableonly)])} {set mc_rap(svs:stableonly) 0}
foreach bind [binds mc:rap:svs:time] {
 unbind [lindex $bind 0] [lindex $bind 1] [lindex $bind 2] [lindex $bind 4]
}
foreach command [info commands mc:rap:svs:time] {rename $command ""}
if {$mc_rap(svs:enabled)} {
 if {($mc_rap(svs:check) > "23") || ($mc_rap(svs:check) < "0")} {set mc_rap(svs:check) 00}
 if {[string length $mc_rap(svs:check)] == "1"} {set mc_rap(svs:check) 0$mc_rap(svs:check)}
 bind time - "00 $mc_rap(svs:check) *" mc:rap:svs:time
 proc mc:rap:svs:time {{args ""}} {
  global mc_rap
  if {[catch {socket -async $mc_rap(svs:server) $mc_rap(svs:port)} sid]} {;\
   putlog "SVS Error\[$mc_rap(svs:script)/$mc_rap(svs:version)\]:  $sid"
   return 1
  }
  fconfigure $sid -blocking 0 -buffering line
  set tout [after 60000 "mc:rap:svs:interface $sid timeout"]
  fileevent $sid readable "mc:rap:svs:interface $sid $tout"
  puts $sid "GET $mc_rap(svs:get)?$mc_rap(svs:query) HTTP/1.0\
           \nHost: $mc_rap(svs:server)\n"
  flush $sid
 }
}
proc mc:rap:svs:interface {sid tout} {
 global mc_rap
 if {$tout == "timeout"} {
  putlog "SVS Warning\[$mc_rap(svs:script)/$mc_rap(svs:version)\]:  SVS Server timed out."
  close $sid
  return 0
 }; after cancel $tout
 set temp 0
 while {![eof $sid]} {
  gets $sid get
  if {$temp < "2"} {
   if {$get == ""} {incr temp; if {$temp == "1"} {set temp 2}}
   continue
  }; if {$get == ""} {continue}
  switch -- [lindex $get 0] {
   003 {
    set reply [lrange $get 1 end]
    if {[lindex $reply 0] != $mc_rap(svs:script)} {
     putlog "SVS Error\[$mc_rap(svs:script)/$mc_rap(svs:version)\]:  SVS Server sent wrong info, got [lindex $reply 0]"
     break   
    }
    if {$mc_rap(svs:stableonly)} {
     set temp [string range $mc_rap(svs:version) 0 8]999
    } else {set temp [string range $mc_rap(svs:version) 0 11]}
    if {[lindex $reply 1] > $temp} {
     set note [lindex $reply 5]
     regsub -- %0 $note [lindex $reply 0] note
     regsub -- %1 $note [lindex $reply 1] note
     regsub -- %2 $note [lindex $reply 2] note
     regsub -- %3 $note [lindex $reply 3] note
     regsub -- %4 $note [lindex $reply 4] note
     regsub -- %version $note $mc_rap(version) note
     foreach to [split $mc_rap(svs:notify) ",; "] {
      if {$to == ""} {continue}
      regsub -- %nick $note $to outnote
      if {[string match *$outnote* [set unotes [notes $to -[notes $to]]]]} {
       set temp 0
       foreach unote $unotes {
        if {$outnote == [lindex $unote 2]} {set temp 1; break}
       }; if {$temp} {continue}
      }
      switch -- [sendnote SVS $to $outnote] {
       0 {
        if {![validuser $notify]} {set x "invalid user"} else {set x "unknown error"}
        putlog "SVS Error\[$mc_rap(svs:script)/$mc_rap(svs:version)\]:  Trying to send note to $to, $x."
       }
       3 {putlog "SVS Error\[$mc_rap(svs:script)/$mc_rap(svs:version)\]:  Trying to send note to $to, notebox too full!"}
      }
     }
    }
   }
  }
 }; close $sid
}
## ^

putlog "$mc_rap(script) $mc_rap(version) by MC_8 loaded." 
