# eggdrop citation script
# (c)2012 cr0n

set vers "0.1"

set citedb "relative/path/to/your/cite.database"
array set cites {}
set citecount 0

bind pub o|F !list pub:cdblist
bind pub - !help pub:cdbhelp
bind pub - !fact pub:cdbfact
bind pub - !rand pub:cdbrand
bind pub o|F !set pub:cdbset
bind pub o|F !save pub:cdbsave
bind pub o|R !reset pub:cdbreset
bind pub o|R !del pub:cdbdel
bind pub o|F !flush pub:cdbflush
bind pub - !grep pub:cdbsearch
bind pub - !add pub:cdbadd
bind pub - factbot: pub:cdbadd
bind time - "?0 *" auto:cdbsave

proc pub:cdbrand {n u h c a} {
    global cites
    set keys [lsort -integer [array names cites]]
    if {[llength $keys] > 0} {
        set id [lindex $keys [expr {int(rand()*[llength $keys])}]]
        putquick "PRIVMSG $c :\[$id\] $cites($id)"
    } else {
        putquick "PRIVMSG $c :currently no facts exist"
    }
}

proc pub:cdbhelp {n u h c a} {
    global vers
    puthelp "PRIVMSG $c :factbot v$vers  --  autosave every 10 minutes"
    puthelp "PRIVMSG $c :==========================================="
    puthelp "PRIVMSG $c :channel cmd      | desc"
    puthelp "PRIVMSG $c :-----------------+-------------------------"
    puthelp "PRIVMSG $c :!fact <#>        | get fact num <#>"
    puthelp "PRIVMSG $c :!add <fact>      | add <fact>"
    puthelp "PRIVMSG $c :factbot: <fact>  | idem"
    puthelp "PRIVMSG $c :!grep <regex>    | search facts for <regex>"
    puthelp "PRIVMSG $c :!help            | guess what?"
    puthelp "PRIVMSG $c :!rand            | get a random fact"
}

proc pub:cdblist {n u h c a} {
	global cites
   	set citequery [lsort -integer [array names cites]]
	if {[llength $citequery] == 0} {
		putquick "PRIVMSG $c :currently no facts exist"
	} else {
		foreach i $citequery {
			puthelp "PRIVMSG $n :\[$i\] $cites($i)"
		}
	}
}

proc pub:cdbfact {n u h c a} {
	global cites
	set id [lindex $a 0]
	if {[info exists cites($id)]} {
		putquick "PRIVMSG $c :\[$id\] $cites($id)"
	} else {
		putquick "PRIVMSG $c :fact $id does not exist"
	}
}

proc pub:cdbsearch {n u h c a} {
    global cites
    set re [string trim $a]
    if {[string length $re] < 1} {
        putquick "PRIVMSG $c ::P"
    } else {
        set re [regsub -all {\s+} $re {.*}]
        set found 0
        set out [list]
        foreach i [lsort -integer [array names cites]] {
            if {[regexp -nocase $re $cites($i)] == 1} {
                incr found
                if {$found > 10} break
                lappend out "\[$i\] $cites($i)"
            }
        }
        if {$found > 0} {
            if {$found > 10} {
                puthelp "PRIVMSG $c :found >10 results, please be more specific"
            }
            foreach line $out {
                puthelp "PRIVMSG $c :$line"
            }
        } else {
            putquick "PRIVMSG $c :nothing found"
        }
    }
}

proc pub:cdbdel {n u h c a} {
	global cites
	set what [string trim $a]
	set j 0
	foreach i $what {
		if {[info exists cites($i)]} {
			unset cites($i)
			incr j
		}
	}
	putquick "PRIVMSG $c :$j facts removed"
}

proc pub:cdbset {n u h c a} {
	global cites citecount
	set id [lindex $a 0]
   	set txt [string trim [lrange $a 1 end]]
    if {[string length $txt] > 0 && $id >= 0 && $id <= $citecount} {
    	putquick "PRIVMSG $c :\[$id\] $txt"
    	set cites($id) $txt
    } else {
        putquick "PRIVMSG $c :new fact is empty or id is out of range"
    }
}

proc pub:cdbadd {n u h c a} {
    global cites citecount
    set txt [string trim $a]
    if {[string length $txt] > 0 && $txt != "{}"} {
        set keys [lsort -integer [array names cites]]
        foreach i $keys {
            if {$cites($i) == $txt} {
                putquick "PRIVMSG $c :dupe, see fact $i"
                return
            }
        }
        incr citecount
        putquick "PRIVMSG $c :\[$citecount\] $txt"
        set cites($citecount) $txt
    } else {
        putquick "PRIVMSG $c :no fact given"
    }
}

proc int:cdbsave {} {
    global citedb cites citecount
    set fp [open $citedb w]
	puts $fp [list array set cites [array get cites]]
    puts $fp [list set citecount [set citecount]]
    close $fp;
}

proc auto:cdbsave {m h d w y} {
    int:cdbsave
}

proc pub:cdbsave {n u h c a} {
    int:cdbsave
	putquick "PRIVMSG $c :facts saved"
}

proc pub:cdbreset {n u h c a} {
	global cites citecount
    set citecount 0
	unset cites
	array set cites {}
	putquick "PRIVMSG $c :facts cleared"
}

proc int:cdbread {} {
    global citedb cites citecount
	uplevel {
	    if {[file exist $citedb]} {
            unset cites
			source $citedb
        }
    }
}

proc pub:cdbflush {n u h c a} {
    global citedb cites citecount
    uplevel {
        if {[file exist $citedb]} {
            unset cites
            source $citedb
        }
    }    
    putquick "PRIVMSG $c :facts flushed"
}

int:cdbread

putlog "FactsDB v$vers successfully loaded."
