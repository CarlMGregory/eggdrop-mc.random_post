##
# Random Post v1.0 by (Carl M. Gregory) MC_8 <gregory@worldinter.net>
#
# My SVS Website - http://mc.purehype.net/
##

##
# This script will pull a random line from a file and post it to the channel.
# The times to post a new line are triggered by a timer, you can set the timer
# to whatever you want per channel.
##

##
# History
##
# v1.0 (02.03.01)
#  MC_8 - BeastNH - inital release
##

##
# Commands (DCC Chat)
##
# .randompost [add <[global/#channel] post>/remove <number>/search <string>]
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
#      There are replacment veriables for the add post, they are %chan %botnick
#      %time %date
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

## MC SVS (Script Version Server) v1.1 ##
# Do you want the bot to connection to MC_8's SVS to see if there are newer versions
# of this script avilable?  It will only tell you -- It's up to you to get the newest
# version (I decided not to auto update the code, there may be new features in the
# newest script that may require your attention).
# 0=no/1=yes
set mc_rap(svs:enabled) 1

# Once a day the script will check with the SVS -- this specifies when
# that should happen.  The setting should be the hour (military).
# examples:
#  set mc_rap(svs:check) 0  ;#This is at Midnight
#  set mc_rap(svs:check) 5  ;#This is at 5am
#  set mc_rap(svs:check) 13  ;#This is at 1pm
#  set mc_rap(svs:check) 23  ;#This is at 11pm
set mc_rap(svs:check) 3

# Upon finding a newer version, who do you want to notify via note?
# Seperate each user with a " " (space).
set mc_rap(svs:notify) "MC_8"




### Do not edit past this part ###
set mc_rap(version) v1.0
set mc_rap(svs:script) "randompost 001000000000"
set mc_rap(svs:server) "mc.purehype.net 8085"

if {$numversion < "1050000"} {
 putlog "Random Post $mc_rap(version) by MC_8 is for eggdrop 1.5+ series only."
 putlog "Random Post $mc_rap(version) will not work with eggdrop $version."
 putlog "Random Post $mc_rap(version) not loaded."
 return 1
};setudef int mc.randompost

foreach chan [channels] {
 foreach info [channel info $chan] {
  if {[lindex $info 0] != "mc.randompost"} {continue}
  if {![lindex $info 1]} {set x 10} {set x [lindex $info 1]}
  if {![string match "*mc:rap:inter:utimer $chan*" [utimers]]} {
   utimer $x "mc:rap:inter:utimer [split $chan]"
  };break
 }
}

proc mc:rap:inter:utimer {chan} {
 global mc_rap botnick
 set repchan $chan
 set chan [string tolower $chan]
 set return 0
 foreach info [channel info $chan] {
  if {[lindex $info 0] != "mc.randompost"} {continue}
  if {![lindex $info 1]} {set x 10;set return 1} {set x [lindex $info 1]}
  if {![string match "*mc:rap:inter:utimer $chan*" [utimers]]} {
   utimer $x "mc:rap:inter:utimer [split $chan]"
  };break
 };if {$return} {return};unset return
 set io [open $mc_rap(database) r];set temp ""
 while {![eof $io]} {
  set line [gets $io]
  if {([lindex $line 1] != "global") &&
      ([string tolower [lindex $line 1]] != $chan)} {continue}
  if {[string trim $line] == ""} {continue}
  set temp "$temp {[lindex $line 2]}"
 };close $io;set temp [string trim $temp]
 if {![llength $temp]} {return}
 if {[llength $temp] > "1"} {
  if {![info exists mc_rap(:$chan:)]} {set mc_rap(:$chan:) 0}
  set rand [rand [llength $temp]]
  while {$rand == $mc_rap(:$chan:)} {set rand [rand [llength $temp]]}
  set mc_rap(:$chan:) $rand
 } {set rand 0}
 set temp [lindex $temp $rand]
 set temp [mc:rap:inter:replace $temp "%time {[strftime "%l:%M %PM"]} %date {[strftime "%b. %d, %Y"]} %chan {$repchan} %botnick {$botnick}"]
 foreach post $temp {puthelp "PRIVMSG $chan :$post"}
}

bind dcc - randompost mc:rap:dcc:randompost
proc mc:rap:dcc:randompost {hand idx args} {
 global mc_rap
 set command [lindex [join $args] 0]
 set args [lrange [join $args] 1 e]
 switch -- [string tolower $command] {
  add {
   if {$args == ""} {putdcc $idx "What?  You need '.randompost help'";return}
   if {([string tolower [lindex $args 0]] == "global") ||
       ([string index $args 0] == "#")} {
    set chan [string tolower [lindex $args 0]]
    set args [lrange $args 1 e]
   } {set chan global}
   if {$args == ""} {putdcc $idx "What?  You need '.randompost help'";return}
   set args [mc:rap:inter:replace $args "<br> \010 <Br> \010 <bR> \010 <BR> \010"]
   set args [split $args \010]
   set io [open $mc_rap(database) a];set temp ""
   set num [mc:rap:inter:findnextnum]
   puts $io "$num $chan {$args}"
   close $io
   putdcc $idx "Added record $num  ($chan):"
   foreach post $args {
    putdcc $idx "  $post"
   }
   putloglev c * "#$hand# randompost add $chan"
   foreach post $args {putloglev c * "     $post"};return
  }
  remove {
   if {$args == ""} {putdcc $idx "What?  You need '.randompost help'";return}
   set io [open $mc_rap(database) r];set temp "";set found 0
   while {![eof $io]} {
    set line [gets $io]
    if {[lindex $line 0] != [lindex $args 0]} {set temp "$temp {$line}"} {set found 1}
   };close $io
   if {!$found} {putdcc $idx "Entrie [lindex $args 0] not found.";return};unset found
   set temp [string trim $temp]
   set io [open $mc_rap(database) w];foreach post $temp {puts $io $post};close $io
   putloglev c * "#$hand# randompost remove [lindex $args 0]";return
  }
  search {
   if {([string trim $args] == "") || ([string trim $args] == "*")} {set args *} {
    set args *[join [string trim [join [split $args *]]] *]*
   }
   putdcc $idx "Search for $args..."
   putdcc $idx " "
   set io [open $mc_rap(database) r];set matches 0;set s s
   while {![eof $io]} {
    set line [gets $io]
    if {[string trim $line] == ""} {continue}
    if {[string match $args $line]} {
     incr matches 1
     if {$matches == 1} {set s ""} {set s s}
     putdcc $idx "Record [lindex $line 0] ([lindex $line 1]):"
     foreach post2 [lindex $line 2] {
      putdcc $idx "  $post2"
     }
    }
   };close $io
   if {$matches} {putdcc $idx " "}
   putdcc $idx "$matches matche$s found."
   putloglev c * "#$hand# randompost search $args";return
  }
  ? {putdcc $idx "What?  You need '.randompost help'";return}
  help {
   putdcc $idx ".randompost \[add <\[global/#channel\] post>/remove <number>/search \[string\]]"
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
   return 0
  }
  default {mc:rap:dcc:randompost $hand $idx "search *";return}
 }
}

if {![file exists $mc_rap(database)]} {set io [open $mc_rap(database) w];close $io}

proc mc:rap:inter:findnextnum {} {
 global mc_rap
 set io [open $mc_rap(database) r];set temp 0
 while {![eof $io]} {
  set line [gets $io]
  if {[lindex $line 0] > $temp} {set temp [lindex $line 0]}
 };close $io;return [expr $temp+1]
}

proc mc:rap:inter:replace {string subs} {
 if {[llength $subs] == "1"} {set subs [lindex $subs 0]}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $string [lindex $subs [expr $i+1]] string
 } ; return $string
}

if {$mc_rap(svs:enabled)} {
 if {($mc_rap(svs:check) > "23") || ($mc_rap(svs:check) < "0")} {set mc_rap(svs:check) 00}
 if {[string length $mc_rap(svs:check)] == "1"} {set mc_rap(svs:check) 0$mc_rap(svs:check)}
 bind time - "00 $mc_rap(svs:check) * * *" mc:rap:svs:time
 proc mc:rap:svs:time {min hour day month year} {
  global mc_rap
  catch {control [connect [lindex $mc_rap(svs:server) 0] [lindex $mc_rap(svs:server) 1]] mc:rap:svs:interface}
 }
}
proc mc:rap:svs:interface {idx args} {
 global mc_rap;set args [join $args]
 switch -- [lindex $args 0] {
  "" {return 1}
  000 {putdcc $idx q}
  002 {putdcc $idx [lindex $mc_rap(svs:script) 0]}
  003 {
   set args [lrange $args 1 e]
   if {[lindex $args 0] != [lindex $mc_rap(svs:script) 0]} {return 0}
   if {[lindex $args 1] > [lindex $mc_rap(svs:script) 1]} {
    set note [mc:rap:svs:replace [lindex $args 7] "%0 {[lindex $args 0]} %1 {[lindex $args 1]} %2 {[lindex $args 2]}"]
    set note [mc:rap:svs:replace $note "%3 {[lindex $args 3]} %4 {[lindex $args 4]} %5 {[lindex $args 5]}"]
    set note [mc:rap:svs:replace $note "%6 {[lindex $args 6]} %8 {[lindex $args 8]} %version {$mc_rap(version)}"]
    set note [mc:rap:svs:replace $note "%9 {[lindex $args 9]} %10 {[lindex $args 10]} %11 {[lindex $args 11]}"]
    set note [mc:rap:svs:replace $note "%12 {[lindex $args 12]} %13 {[lindex $args 13]} %14 {[lindex $args 14]}"]
    set note [mc:rap:svs:replace $note "%15 {[lindex $args 15]} %16 {[lindex $args 16]} %17 {[lindex $args 17]}"]
    set note [mc:rap:svs:replace $note "%18 {[lindex $args 18]} %19 {[lindex $args 19]} %20 {[lindex $args 20]}"]
    foreach notify [join [split $mc_rap(svs:notify) ",;"]] {
     switch -- [sendnote SVS $notify [mc:rap:svs:replace $note "%nick {$notify}"]] {
      0 {putlog "MC SVS for [lindex $mc_rap(svs:script) 0] had some errors updating $notify on current version of script; unknown reason!"}
      3 {putlog "MC SVS for [lindex $mc_rap(svs:script) 0] had some errors updating $notify on current version of script; notebox too full!"}
     }
    }
   } ; putdcc $idx q
  }
 } ; return 0
}
proc mc:rap:svs:replace {string subs} {
 if {[llength $subs] == "1"} {set subs [lindex $subs 0]}
 for {set i 0} {[lindex $subs $i] != ""} {incr i 2} {
  regsub -all -- [lindex $subs $i] $string [lindex $subs [expr $i+1]] string
 } ; return $string
}

putlog "Random Post $mc_rap(version) by MC_8 loaded." 
