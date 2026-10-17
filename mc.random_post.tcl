##
# Random Post v1.5
#  by MC_8 - Carl M. Gregory <mc8@purehype.net>
#  This script will only run on eggdrop 1.6.14 or greater.
#
#    R.I.P. Mom, To always be remembered; Nancy Marie Gregory.
#
# My Website - http://mc.purehype.net/
# Have a bug?  http://mc.purehype.net/bugzilla/
##

##
# This script will post a random bit of text to the channel.  The lines of text
# are addable on the fly via the dcc console, as well as the timer in which
# triggers it to post.
##

##
# Commands (DCC)
##
# +post ['global'|channel] <text>
#   This will add a random post entry to either channel or globally.  If channel
#   or global is not given, global is assumed.  Also, if channel is not a valid
#   channel, global is assumed.  Each line of text is to be separated by \n, ie
#   line 1\nline 2\nline 3.  This will return with the id the post was added as.
#   Replacement variables within text can be:
#     %channel -- The channel.
#     %botnick -- The bot's irc nick.
#     %time    -- Current time, in '12:50 AM' format.
#     %date    -- Current date, in 'Aug. 29, 2001' format.
#     %id      -- The record id of current post.
#   Examples:
#     +post global Welcome to %channel, enjoy your stay.
#       This will create a random post for all channels, that are enabled.
#
#     +post #eggdrop Rules found on topic.\nDo not abuse the rules.
#       This will create a random post for #eggdrop.
#
# -post <id>
#   This will remove the id from the random post database.
#
# posts ['all'|'global'|channel] [string]
#   This will search the random post database for the given string.  String
#   format is glob style, using * and ? as wild cards.
#
# chanset <channel> mc.random_post <time>
#   Set's the number of seconds in between the random posts to the specific
#   channel.  Setting the time to 0 (default) will turn the script off for that
#   channel.  Please note, you can set this to whatever time you like, but if it
#   happens to be an odd number, the script will set the timer to an even number
#   to avoid the utimer within utimer bug found at 
#   http://www.eggheads.org/bugzilla/show_bug.cgi?id=251.
#   Example:
#     chanset #eggdrop mc.random_post 500
##

##
# Configuration
##
#

# This script will store information it gathers into a database file.  Where and
# what do you want to call this database filename?
set mc_rap(:config:database) "./.randompost.dat"

# What access must a user have to add and remove entries to this script?  Flag
# structure is <global>|<channel>.  You can set this to "-|-" to allow anyone,
# who can dcc chat the bot, to add and remove entries.
set mc_rap(:config:dcc_access) o|o

# You can share your random post entries to other bots linked.  They must have
# the same key in order to share with one another.  Set the key you would like
# to use.  Set this to "" to disable sharing all together.
set mc_rap(:config:share_key) "BraeADS"

## SVS Client (Script Version Service) v4.1.1 ##
# Once a day, the SVS Client will connect to MC_8's SVS Server to determine if
# there is a newer version of this script available.  If a newer version is
# found, the script will be auto updated.

# [0=no/1=yes] Do you want to enable auto updating?  If you chose to disable
# auto updating, it will not automatically update the script upon finding a
# newer version.
set mc_rap(:config:svs:enable) 1

#
##

##
# Done with configurations, do not edit past here unless you know TCL.
##
#

#Script:mc_rap

## SVS insert (pre code)
catch {unset temp}
set mc_rap(info:vars) ""
foreach {temp(name) temp(value)} [array get mc_rap :config:*] {
  lappend mc_rap(info:vars) [list $temp(name) $temp(value)]
}
set mc_rap(info:loc) [info script]
array set mc_rap [list \
  script                 "Random Post" \
  version                "v1.5" \
  svs:script             "randompost" \
  svs:version            "001005000000" \
  svs:client_version     "v4.1.1" \
  svs:client_svs_version "004001001000" \
  svs:server             "mc.svs.purehype.net" \
  svs:port               "80" \
  svs:get                "/index.tcl"]
set mc_rap(svs:query)    "svs=$mc_rap(svs:script)&"
append mc_rap(svs:query) "version=$mc_rap(svs:version)&"
append mc_rap(svs:query) \
  "svs_version=$mc_rap(svs:client_svs_version)"

if {![info exists numversion] || 
    ([string range $numversion 0 4] < "10614") ||
    (([string range $numversion 0 4] == "10614") &&
     ([string range $numversion 5 6] != "00"))} {
  set temp(tag) "$mc_rap(script) $mc_rap(version)"
  putloglev o * \
    "$temp(tag) by MC_8 will only work on eggdrop 1.6.14 (stable) or greater."
  putloglev o * "$temp(tag) will not work with eggdrop $version."
  putloglev o * "$temp(tag) not loaded."
  uplevel #0 {
    if {[info exists temp] && ![array exists temp]} {unset temp}
    set temp(svs_return) [list 0 "Need to upgrade eggdrop."]
  }; return 1
}
## ^

# Error Catching System (ECS), v4.0.
proc mc:rap:errchk {command args} {
  
  # Enable (1) or disable (0) auto reporting of bugs to mc8@purehype.net.
  # This setting here for those who want to disable it in fear of privacy
  # violations.
  set enable_auto_reporting 1
  
  if {![info exists ::lastCommand]} {set ::lastCommand [list]}
  set ::lastCommand \
    "[list [list [clock seconds] $command $args]] $::lastCommand"
  set ::lastCommand [lrange $::lastCommand 0 4]
  if {![catch {eval $command $args} return]} {return $return}
  if {$::errorCode == "mc.ecs.done"} {return -errorcode mc.ecs.done -code error}
  
  set temp(lastbind) [expr {[info exists ::lastbind]?$::lastbind:"-NULL-"}]
  set temp(eversion) [expr {[info exists ::version]?$::version:"-NULL-"}]
  set message "
    ************************************
    (ECS 4.0) Error found in TCL script.
    --------------
    Script name   : $::mc_rap(script)
    Script version: $::mc_rap(version)
    Egg. Version  : $temp(eversion)
    TCL Version   : [info tclversion] ([info patchlevel])
    --------------
    Last Bind     : $temp(lastbind)
    Last Commands :"
  foreach line $::lastCommand {
    foreach {time command arg} $line break
    append message "\n        ${time}- $command $arg"
  }
  append message "\n    Error stack   :"
  foreach line [split $::errorInfo \n] {
    append message "\n        $line"
  }
  append message "\n    --------------"
  
  set message [lrange [split $message \n] 1 end]
  set offset [string first * [lindex $message 0]]
  set new_message [list]
  foreach line $message {lappend new_message [string range $line $offset end]}
  set message $new_message
  
  if {!$enable_auto_reporting ||
      [catch {socket -async mc.purehype.net 80} sid]} {
    foreach line $message {putloglev o * $line}
    putloglev o * "Submit this bug to http://mc.purehype.net/bugzilla/ . If"
    putloglev o * "you are experiencing problems with bugzilla, contact MC_8"
    putloglev o * "via email at mc8@purehype.net. Please include all"
    putloglev o * "information shown here, in this ECS report."
    putloglev o * "************************************"
    return -errorcode mc.ecs.done -code error
  }
  fconfigure $sid -blocking 0 -buffering line
  set query [list]
  foreach line $message {
    regsub -all -- "(\002|\017|\026|\037)" $line "" line
    regsub -all -- "\003(\[0-9\]\[0-9\]?(,\[0-9\]\[0-9\]?)?)?" $line "" line
    regsub -all {\%} $line "%25" line
    set i [string length $line]
    while {[regexp {[^a-zA-Z0-9%]} $line toh] && ($i >= 0)} {
      scan "$toh" %c dec
      regsub -all -- "\\${toh}" $line "%[format %X $dec]" line
      incr i -1
    }; lappend query $line
  }
  set query "message=[join $query %0a]"
  puts $sid "POST /report_bug.tcl HTTP/1.0\
           \nHost: mc.purehype.net:80\
           \nContent-type: application/x-www-form-urlencoded\
           \nContent-Length: [expr [string length $query] +2]"
  puts $sid \n$query
  close $sid

  foreach line $message {putloglev o * $line}
  putloglev o * "Automatically sending bug report to MC_8."
  putloglev o * "If you have a firewall setup, it may block the sending of this"
  putloglev o * "report. You can check the status of your bug, as soon as MC_8"
  putloglev o * "adds it, at http://mc.purehype.net/bugzilla/ ."
  putloglev o * "************************************"
  
  return -errorcode mc.ecs.done -code error
}
# ^

setudef int mc.random_post

# +post ['global'|channel] <text>
bind dcc - +post mc:rap:dcc:+post
proc mc:rap:dcc:+post {handle index text} {
  return [mc:rap:errchk mc:rap:dcc:+post_ $handle $index $text]
}
proc mc:rap:dcc:+post_ {handle index text} {
  global mc_rap
  
  set usage {+post ['global'|channel] <text>}
  
  set text [split $text]
  set channel [lindex $text 0]
  if {($channel == "global") || [validchan $channel]} {
    set text [join [lrange $text 1 end]]
  } else {
    set channel global
    set text [join $text]
  }
  
  set log_lev_c "+post $channel $text"
  
  if {($channel != "global") &&
      [validchan $channel] &&
      ![channel get $channel mc.random_post]} {
    putdcc $index "$channel is not enabled."
    putdcc $index \
      "To enable the channel, do: chanset $channel mc.random_post <number>"
    putdcc $index "Right now that number is 0, which is disable. The number"
    putdcc $index "represents how often a post is randomly displayed to the"
    putdcc $index "channel."
    putloglev c * "#$handle# (denied, channel disabled): $log_lev_c"
    return 0
  }
  
  if {(($channel == "global") &&
       (![matchattr $handle $mc_rap(:config:dcc_access)]) &&
       ($mc_rap(:config:dcc_access) != "-|-")) ||
      (($channel != "global") &&
       (![matchattr $handle $mc_rap(:config:dcc_access) $channel]) &&
       ($mc_rap(:config:dcc_access) != "-|-"))} {
    putdcc $index "You do not have access to add to the $channel post list."
    putloglev c * "#$handle# (denied, no access): $log_lev_c"
    return 0
  }
      
  if {$text == ""} {
    putdcc $index "You did not specify the text you wanted to add."
    putdcc $index "Usage: $usage"
    return 0
  }
      
  regsub -all -- {\\n} $text \n text
  set new_text [list]
  foreach item [split $text \n] {
    set item [string trim $item "\t "]
    if {$item == ""} {continue}
    lappend new_text $item
  }; set text $new_text
  
  set id [mc:rap:list add $channel $text]
  if {[string index $id 0] == "-"} {
    set id [string range $id 1 end]
    putdcc $index "Entry already exists under id $id."
    return
  }
  mc:rap:list send_share $handle add $channel $text

  putdcc $index "Added new post under id $id  ($channel):"
  foreach line $text {putdcc $index "  $line"}
  
  putloglev c * "#$handle# $log_lev_c"
  return 0
}

# -post <id>
bind dcc - -post mc:rap:dcc:-post
proc mc:rap:dcc:-post {handle index text} {
  return [mc:rap:errchk mc:rap:dcc:-post_ $handle $index $text]
}
proc mc:rap:dcc:-post_ {handle index text} {
  global mc_rap
  
  set usage {-post <id>}
  set id [lindex [split $text] 0]
  set log_lev_c "-post $id"
  
  if {$id == ""} {
    putdcc $index "You did not specify the id to remove."
    putdcc $index "Usage: $usage"
    return 0
  }
  
  if {![mc:rap:list exists $id]} {
    putdcc $index "Entry id $id does not exist."
    return 0
  }
  
  set channel [mc:rap:list get_channel $id]
  
  if {(($channel == "global") &&
       (![matchattr $handle $mc_rap(:config:dcc_access)]) &&
       ($mc_rap(:config:dcc_access) != "-|-")) ||
      (($channel != "global") &&
       (![matchattr $handle $mc_rap(:config:dcc_access) $channel]) &&
       ($mc_rap(:config:dcc_access) != "-|-"))} {
    putdcc $index "You do not have access to remove to the $channel post list."
    putloglev c * "#$handle# (denied, no access): $log_lev_c"
    return 0
  }
  
  set text [mc:rap:list get_text $id]
  
  mc:rap:list remove $id
  mc:rap:list send_share $handle remove $channel $text

  putdcc $index "Removed post under id $id  ($channel):"
  foreach line $text {putdcc $index "  $line"}
  
  putloglev c * "#$handle# $log_lev_c"
  return 0
}

# posts ['all'|'global'|channel] [string]
bind dcc - posts mc:rap:dcc:posts
proc mc:rap:dcc:posts {handle index text} {
  return [mc:rap:errchk mc:rap:dcc:posts_ $handle $index $text]
}
proc mc:rap:dcc:posts_ {handle index text} {
  global mc_rap
  
  set text [split $text]
  set channel [lindex $text 0]
  if {($channel == "global") || ($channel == "all") || [validchan $channel]} {
    set text [join [lrange $text 1 end]]
  } else {
    set channel all
    set text [join $text]
  }
  if {$channel == "all"} {set channels "[list global] [channels]"} \
  else {set channels [list $channel]}
  if {$text == ""} {set text *}
  
  set usage {posts ['all'|'global'|channel] [string]}
  set log_lev_c "posts $channel $text"
  
  set ltext [string tolower $text]
  set done_first 0
  putdcc $index "Searching for '$text' via $channel:"
  foreach channel $channels {
    if {(($channel == "global") &&
         (![matchattr $handle $mc_rap(:config:dcc_access)]) &&
         ($mc_rap(:config:dcc_access) != "-|-")) ||
        (($channel != "global") &&
         (![matchattr $handle $mc_rap(:config:dcc_access) $channel]) &&
         ($mc_rap(:config:dcc_access) != "-|-"))} {
      if {!$done_first} {set done_first 1} \
      else {putdcc $index " "}
      putdcc $index \
        "  !! You do not have access to view the $channel post list, skipping."
      continue
    }
  
    set outgoing [list]
    
    foreach entry [mc:rap:list list $channel] {
      foreach {e_id e_channel e_text} $entry break
      set le_text [string tolower $e_text]
      
      if {[string match $ltext $le_text]} {
        lappend outgoing "    \[$e_id\]: $e_text"
      }
    }
    
    if {[llength $outgoing]} {
      if {!$done_first} {set done_first 1} \
      else {putdcc $index " "}
      putdcc $index "  $channel:"
      foreach line $outgoing {putdcc $index $line}
    }
    
  }
    
  putloglev c * "#$handle# $log_lev_c"
  return 0
}

bind bot - mc_rap mc:rap:recieve_share
proc mc:rap:recieve_share {from command text} {
  return [mc:rap:errchk mc:rap:recieve_share_ $from $command $text]
}
proc mc:rap:recieve_share_ {from command text} {
  global mc_rap
  if {$mc_rap(:config:share_key) == ""} {return}
  set recieved [decrypt $mc_rap(:config:share_key) $text]
 
  foreach {key handle command} $recieved break
  if {$key != $mc_rap(:config:share_key)} {return}
  
  switch -- $command {
    
    "add" {
      foreach {. . . channel text} $recieved break
      set channel [string tolower $channel]
      
      if {[string index [mc:rap:list add $channel $text] 0] == "-"} {return}
      
      putloglev c * "#$handle@$from# +post $channel [join $text \\n]"
    }
    
    "remove" {
      foreach {. . . channel text} $recieved break
      
      set id [mc:rap:list exists $channel $text]
      if {!$id} {return}
      
      mc:rap:list remove $id

      putloglev c * "#$handle@$from# -post $id"
    }
    
  }
}

bind evnt - save mc:rap:evnt
proc mc:rap:evnt {type} {
  if {$type != "save"} {return}
  mc:rap:list save
}

proc mc:rap:list {command {args ""}} {
  return [mc:rap:errchk mc:rap:list_ $command $args]
}
proc mc:rap:list_ {command arg} {
  global mc_rap

  if {![info exists mc_rap(list)]} {set mc_rap(list) ""}

  if {[info tclversion] > 8.0} {
    set temp(newarg) [list]
    foreach temp(item) $arg {
      lappend temp(newarg) [encoding convertto [encoding system] $temp(item)]
    }; set args $temp(newarg)
  } else {set args $arg}

  switch -- $command {
    
    "list" {
      # In: [channel]
      set channel [string tolower [lindex $args 0]]
      
      if {$channel == ""} {return $mc_rap(list)}
      
      set return [list]
      foreach entry $mc_rap(list) {
        foreach {e_id e_channel e_text} $entry break
        if {$e_channel == $channel} {lappend return $entry}
      }; return $return
    }

    "add" {
      # Return:
      #   -<id> = Exists under <id>
      #    <id> = Added under <id>.
      foreach {channel text} $args break
      set channel [string tolower $channel]
      
      if {[set id [mc:rap:list exists $channel $text]]} {return -$id}
      
      set id [mc:rap:list get_next_id]
      lappend mc_rap(list) [list $id $channel $text]
      mc:rap:list save -quiet
      return $id
    }
    
    "remove" {
      # Return 0 if not found, 1 if found
      set id [lindex $args 0]
      
      set found 0; set new_list [list]
      foreach entry $mc_rap(list) {
        if {$id == [lindex $entry 0]} {set found 1; continue}
        lappend new_list $entry
      }
      if {$found} {
        set mc_rap(list) $new_list
        mc:rap:list save -quiet
      }
      return $found
    }
    
    "get_channel" {
      # Return "" or channel for given id.
      set id [lindex $args 0]
      
      foreach entry $mc_rap(list) {
        foreach {e_id e_channel e_text} $entry break
        if {$e_id == $id} {return $e_channel}
      }; return ""
    }
    
    "get_text" {
      # Return "" or text for given id.
      set id [lindex $args 0]
      
      foreach entry $mc_rap(list) {
        foreach {e_id e_channel e_text} $entry break
        if {$e_id == $id} {return $e_text}
      }; return ""
    }
    
    "exists" {
      # In: <id> or <channel> <text>
      # Return 0 or id
      foreach {channel text} $args break
      if {$text == ""} {set id $channel} \
      else {set channel [string tolower $channel]}

      set id_exists [info exists id]
      foreach entry [mc:rap:list list] {
        foreach {e_id e_channel e_text} $entry break
        if {($id_exists && ($e_id == $id)) ||
            (!$id_exists &&
             ($channel == $e_channel) &&
             ($text == $e_text))} {return $e_id}
      }; return 0
    }
    
    "get_next_id" {
      set id_list [list 0]
      foreach entry $mc_rap(list) {
        set id [lindex $entry 0]
        lappend id_list $id
      }
      set id_list [lsort -dictionary $id_list]

      for {set i 0} {$i < [llength $id_list]} {incr i} {
        set id [lindex $id_list $i]
        set next_id [lindex $id_list [expr $i+1]]
        if {$id != [expr $next_id-1]} {
          set usable_id [expr $id+1]
          break
        }
      }; return $usable_id
    }
    
    "save" {
      if {[lsearch -exact $args -quiet] == "-1"} {
        putloglev o * "Writing $mc_rap(script) file..."
      }

      set io [open $mc_rap(:config:database) w]
      puts $io "#v2:$mc_rap(script):$mc_rap(version):[clock seconds]"
      foreach line [mc:rap:list list] {
        if {![validchan [lindex $line 1]]} {continue}
        puts $io $line
      }
      close $io
      mc:rap:list load -quiet
    }
    
    "load" {
      if {[lsearch -exact $args -quiet] == "-1"} {
        putloglev o * "Reading $mc_rap(script) file..."
        set quiet 0
      } else {set quiet 1}

      if {![file exists $mc_rap(:config:database)]} {
        close [open $mc_rap(:config:database) w]
      }
      
      set list [list]
      set db_ver "1"
      
      set io [open $mc_rap(:config:database) r]
      for {set index 0} {![eof $io]} {incr index} {
        gets $io line
        if {!$index} {
          if {[regexp -- {^#v([0-9][0-9]*):} $line -> db_ver]} {continue}
          if {!$quiet} {
            putloglev o * "$mc_rap(script): Old database found."
          }
        }
        if {([string trim $line] == "") ||
            ([string index $line 0] == "#")} {continue}
        if {[info tclversion] > 8.0} {
          set new_line [list]
          lappend new_line \
            [encoding convertto [encoding system] [lindex $line 0]]
          lappend new_line \
            [encoding convertto [encoding system] [lindex $line 1]]
          set new_text [list]
          foreach text [lindex $line 2] {
            lappend new_text [encoding convertto [encoding system] $text]
          }
          lappend new_line $new_text
          set line $new_line
        }
        lappend list $line
      }
      close $io
      
      if {!$quiet} {
        set num [llength $list]
        set s [expr {($num=="1")?"":"s"}]
        putloglev o * "$mc_rap(script): Loaded $num record$s."
      }
      set mc_rap(list) $list
      return 1
    }
    
    "send_share" {
      if {$mc_rap(:config:share_key) == ""} {return}
      set send [encrypt $mc_rap(:config:share_key) \
        "[list $mc_rap(:config:share_key)] $args"]
      putallbots "mc_rap $send"
    }
    
    "check_timers" {
      set utimers [utimers]
      
      set found 0
      foreach utimer $utimers {
        foreach {time command timerId} $utimer break
        if {$command == [list mc:rap:list check_timers]} {
          set found 1
          break
        }
      }
      if {!$found} {utimer 60 [list mc:rap:list check_timers]}
      
      foreach channel [channels] {
        set channel [string tolower $channel]
        
        if {![set settime [channel get $channel mc.random_post]]} {
          foreach utimer $utimers {
            foreach {time command timerId} $utimer break
            if {$command != [list mc:rap:list post $channel]} {continue}
            killutimer $timerId
          }
        } else {
          if {[regexp -- {[13579]$} $settime]} {incr settime}
          set found 0
          foreach utimer $utimers {
            foreach {time command timerId} $utimer break
            if {$command == [list mc:rap:list post $channel]} {
              if {$time > $settime} {
                killutimer $timerId
                utimer $settime [list mc:rap:list post $channel]
              }
              set found 1
              break
            }
          }
          if {!$found} {utimer $settime [list mc:rap:list post $channel]}
        }
      }
    }

    "post" {
      set channel [lindex $args 0]
      set lchannel [string tolower $channel]
      mc:rap:list check_timers
      
      if {(![validchan $channel]) ||
          (![channel get $channel mc.random_post])} {return 0}
      
      set list [list]
      foreach entry [mc:rap:list list global]   {lappend list $entry}
      foreach entry [mc:rap:list list $channel] {lappend list $entry}

      set llength [llength $list]
      if {!$llength} {return}
      if {$llength > "1"} {
        if {![info exists mc_rap(:rand:$lchannel)]} {
          set mc_rap(:rand:$lchannel) 0
        }
        while {1} {
          set rand [rand $llength]
          if {$rand != $mc_rap(:rand:$lchannel)} {break}
        }
        set mc_rap(:rand:$lchannel) $rand
      } else {
        set rand 0
      }
      
      set entry [lindex $list $rand]
      foreach {id . text} $entry break
      set text [mc:rap:replace $text [list %id      $id \
                                           %time    [strftime "%l:%M %PM"] \
                                           %date    [strftime "%b. %d, %Y"] \
                                           %channel $channel \
                                           %botnick $::botnick]]
      foreach line $text {putserv "PRIVMSG $channel :$line"}
    }
    
  }
}

utimer 2 [list mc:rap:list load]
utimer 2 [list mc:rap:list check_timers]

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
  # Were not going to use 2list here, don't want to evoke a 'too many nested
  # calls to Tcl_EvalObj' error since '2list' uses on this proc.
  if {[catch {llength $check_args} llength]} {
    set check_args [split $check_args]
    set llength $check_args
  }

  if {($llength < $check_min) ||
      (($llength != "end") && ($llength > $check_max))} {
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

## End of More Tools quick procs.


## SVS insert (post code)
if {![info exists mc_rap(:config:svs:enable)] ||
    ![string match {[01]} $mc_rap(:config:svs:enable)]} {
  set mc_rap(:config:svs:enable) 0
}

bind time - "00 00 *" mc:rap:do_svs
proc mc:rap:do_svs {{args ""}} {
  global mc_rap
  set query $mc_rap(svs:query)
  if {$args == ""} {append query "&log=0"}
  if {[catch {connect $mc_rap(svs:server) $mc_rap(svs:port)} ind]} {
    set temp(1) "SVS problem connecting to $mc_rap(svs:server)"
    set temp(2) "on port $mc_rap(svs:port)"
    putloglev d * "$mc_rap(script): $temp(1) $temp(2):  $ind"
    return 0
  }
  putdcc $ind "GET $mc_rap(svs:get)?$query HTTP/1.0\n"
  putdcc $ind "Host: $mc_rap(svs:server):$mc_rap(svs:port)\n\n"
  control $ind mc:rap:svs_talk
}

proc mc:rap:svs_memory {action} {
  global mc_rap
  switch -- $action {
    
    "setup" {
      upvar index index
      foreach _item [list header memory rfc_memory] {
        upvar $_item $_item
        set $_item [list svs $_item $index]
      }
    }
    
    "remove" {
      upvar index index
      mc:rap:svs_memory setup
      catch {unset mc_rap($header)}
      catch {unset mc_rap($memory)}
      foreach _item [array names mc_rap $rfc_memory:*] {unset mc_rap($_item)}
    }

  }
}

proc mc:rap:svs_talk {index text} {
  global mc_rap
  mc:rap:svs_memory setup
  if {$text == ""} {
    mc:rap:svs_memory remove
    return 1
  }
  set text [split $text]
  set rfc [lindex $text 0]
  set text [join [lrange $text 1 end]]
  if {![info exists mc_rap($header)]} {
    if {$rfc == "002"} {set mc_rap($header) 1}
    return 0
  }
  switch -- $rfc {

    001 {return 0}
    002 {return 0}
    003 {return 0}

    010 {
      if {$text != $mc_rap(svs:script)} {
        set temp(1) "wanted $mc_rap(svs:script), got $text"
        putloglev d * "$mc_rap(script): SVS Error: $temp(1)"
        mc:rap:svs_memory remove
        return 1
      }
      if {$mc_rap(:config:svs:enable)} {return 0}
      set mc_rap($rfc_memory:[string index $rfc end]) $text
      return 0
    }

    011 {
      if {$mc_rap(:config:svs:enable)} {return 0}
      set mc_rap($rfc_memory:[string index $rfc end]) $text
      return 0
    }
      
    012 {
      if {$mc_rap(:config:svs:enable)} {return 0}
      set mc_rap($rfc_memory:[string index $rfc end]) $text
      return 0
    }
    
    013 {
      if {$mc_rap(:config:svs:enable)} {return 0}
      set mc_rap($rfc_memory:[string index $rfc end]) $text
      return 0
    }
    
    014 {
      if {$mc_rap(:config:svs:enable)} {return 0}
      set mc_rap($rfc_memory:[string index $rfc end]) $text
      return 0
    }
    
    017 {
      if {$mc_rap(:config:svs:enable)} {return 0}
      if {$text == ""} {
        set text "Newer version of this script exists."
      }
      foreach number [list 0 1 2 3 4] {
        if {![info exists mc_rap($rfc_memory:$number)]} {continue}
        regsub -all -- %$number $text $mc_rap($rfc_memory:$number) text
      }
      putloglev o * "SVS, $mc_rap(script): $text"
      mc:rap:svs_memory remove
      return 1
    }

    004 {
      # Quit.
      if {!$mc_rap(:config:svs:enable)} {
        mc:rap:svs_memory remove
        return 1
      }
        
      if {[info exists mc_rap($memory)]} {
        set file $mc_rap(info:loc)~new
        set temp(vars) $mc_rap(info:vars)
        set io [open $file w]
        for {set i 0} {$i <= [llength $mc_rap($memory)]} {incr i} {
          set line [lindex $mc_rap($memory) $i]
          set regexp {^[; ]*set mc_rap\((:config:[^)]*)\) *(.?)}
          if {[regexp -- $regexp $line -> name type]} {
            set continue 0
            foreach item $temp(vars) {
              set item_name [lindex $item 0]
              set item_value [lindex $item 1]
              if {$name != $item_name} {continue}
              set lsearch_index [lsearch -exact $temp(vars) $item]
              set temp(vars) \
                [lreplace $temp(vars) $lsearch_index $lsearch_index]
              puts $io [list set mc_rap($name) $item_value]
              if {$type == "\{"} {
                while {1} {
                  if {[regexp -- {\}(?:[; ][; ]*(.*))?} $line -> extra]} {
                    if {$extra != ""} {
                      puts $io $extra
                    }
                    break
                  }
                  incr i
                  set line [lindex $mc_rap($memory) $i]
                }
                puts $io ""
              } elseif {$type == "\""} {
                regsub -- {"} $line "" line
                while {1} {
                  if {[regexp -- {[^\\]"(?:[; ][; ]*(.*))?} $line -> extra] ||
                      [regexp -- {^"(?:[; ][; ]*(.*))?} $line -> extra]} {
                    if {$extra != ""} {
                      puts $io $extra
                    }
                    break
                  }
                  incr i
                  set line [lindex $mc_rap($memory) $i]
                }
                puts $io ""
              }
              set continue 1
              break
            }
            if {$continue} {continue}
          }
          puts $io $line
        }
        close $io
        set file $mc_rap(info:loc)
        putloglev o * "$mc_rap(script): Auto update testing new script..."
        if {[catch {uplevel "source $file~new"}]} {
          file delete -force -- $file~new
          putloglev o * "$mc_rap(script): Auto update failed:"
          putloglev o * $::errorInfo
          putloglev o * \
            "$mc_rap(script): Loading previous script version..."
          uplevel "source $file"
        } else {
          upvar #0 temp upvar_temp
          if {[info exists upvar_temp(svs_return)]} {
            set temp(return_code) [lindex $upvar_temp(svs_return) 0]
            set temp(return_arg) [lindex $upvar_temp(svs_return) 1]
            
            if {!$temp(return_code)} {
              file delete -force -- $file~new
              set temp() "message from new version: $temp(return_arg)"
              putloglev o * "$mc_rap(script): Auto update failed, $temp()"
              putloglev o * \
                "$mc_rap(script): Loading previous script version..."
              uplevel "source $file"
            } else {
              file rename -force -- $file~new $file
              set temp() "good, message from new version: $temp(return_arg)"
              putloglev o * "$mc_rap(script): Auto update test $temp()"
              putloglev o * \
                "$mc_rap(script): Moving and reloading new version..."
              uplevel "source $file"
            }
          } else {
            file rename -force -- $file~new $file
            putloglev o * "$mc_rap(script): Auto update test good."
            putloglev o * \
              "$mc_rap(script): Moving and reloading new version..."
            uplevel "source $file"
          }
        }
      }

      mc:rap:svs_memory remove
      return 1
    }

    200 {
      set temp(host) [lindex $text 1]
      set temp(port) [lindex $text 2]
      set temp(get)  [lindex $text 3]
      set temp(cache) "$temp(host) at $temp(port)"
      putloglev d * \
        "$mc_rap(script): SVS is being redirected to $temp(cache)."
      utimer 6 [list mc:rap:do_svs_ $temp(host) $temp(port) $temp(get)]
      mc:rap:svs_memory remove
      return 1
    }

    300 {
      if {$mc_rap(:config:svs:enable)} {
        lappend mc_rap($memory) $text
      }; return 0
    }

  }
}
catch {unset index}
if {![info exists mc_loaded]} {set mc_loaded(scripts) [list]}
if {![array exists mc_loaded]} {unset mc_loaded; set mc_loaded(scripts) [list]}
set index [lsearch -exact $mc_loaded(scripts) mc_rap]
set mc_loaded(scripts) [lreplace $mc_loaded(scripts) $index $index mc_rap]
## ^

putloglev o * "$mc_rap(script) $mc_rap(version) by MC_8 loaded."

#
##

##
# History  ( <Fixed by> - [Found by] - <Info> )
##
# v1.5 (08.31.03)
#  MC_8 -         - Changed replacment variable %num to %id and %chan to
#                   %channel.
#  MC_8 -         - Upgraded ECS.  v3.0 -> v4.0
#  MC_8 -         - Upgraded SVS client.  v3.0.1 -> v4.1.1
#  MC_8 -         - Bot no longer has to be on the channel to post to that
#                   channel -- can have channel set to +inactive so that it
#                   doesn't join.  If the channel accepts outside messages (-n),
#                   then they can see the post.
#  MC_8 -         - No longer watches .help nor .chanset.
#  MC_8 - TRaSH   - Rewrote how it keeps track of timers.
#                   Bugzilla Bug 284
#  MC_8 - BoR0    - Added ability to share over botnet.
#                   Bugzilla Bug 259 
#  MC_8 -         - Removed dcc command 'randompost' and added '+post', '-post'
#                   and 'posts'.
#  MC_8 -         - Changed chanset setting from `randompost` to `random_post`.
#  MC_8 - heber   - Removed now unused `chanint`.  Fixed 'invalid command name
#                   "mc:rap:chanint"'.
#                   Bugzilla Bug 253 
#  MC_8 - Normand - Fixed, 'can't read "chan": no such variable'.
#                   Bugzilla Bug 299 
#
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
#  MC_8 - BeastNH - Added mc_rap(dcc_access) variable.  It defines who can add
#                   and remove random post entries.
#
# v1.0 (02.03.01)
#  MC_8 - BeastNH - initial release
##
