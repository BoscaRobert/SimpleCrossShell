#!/usr/bin/env tclsh

set OS $tcl_platform(platform)

#salvam directorul original
set DIR $env(PWD)

puts "Platforma detectat : $OS"

if {![file exists ./comSend]} {
    exec mkfifo comSend
}

package require Tk
wm title . "SimpleCrossShell"
wm minsize . 512 256
wm iconphoto . [image create photo -file ./icon.gif]

ttk::frame .c -padding "3 3 12 12" -borderwidth 2

ttk::frame .c.fereastraConsola -padding 10 -borderwidth 2 -relief sunken 
ttk::frame .c.fereastraButoane -padding 10 -borderwidth 2 -relief sunken 

grid .c -column 0 -row 0 -sticky nwes
grid .c.fereastraConsola -column 1 -row 2 -sticky wesn -rowspan 6
grid .c.fereastraButoane -column 2 -row 2 -sticky wesn -rowspan 6

set defBG "#242424" 
set defFG "#F2FFFF"
set usrcol "#37FF00"
set dircol "#00FFDC"

grid [text .c.fereastraConsola.con -wrap word -background $defBG -foreground $defFG] -column 1 -row 2 -sticky wesn -rowspan 3

.c.fereastraConsola.con tag configure usr -foreground $usrcol
.c.fereastraConsola.con tag configure dir -foreground $dircol
.c.fereastraConsola.con tag configure dfb -background $defBG
.c.fereastraConsola.con tag configure dff -foreground $defFG

set seLogheaza nu

grid [ttk::button .c.fereastraButoane.butonExec -text "Executa" -command "executa"] -column 2 -row 2 -sticky nsew
grid [ttk::checkbutton .c.fereastraButoane.checkbuttonLog -text "Logheaza" -variable seLogheaza -onvalue log -offvalue nolog] -column 2 -row 3 -sticky nsew
grid [ttk::label .c.fereastraButoane.labelUsername -text {username:}] -column 2 -row 4 -sticky nsew
grid [ttk::entry .c.fereastraButoane.fieldUsername -textvariable username] -column 2 -row 5 -sticky nsew
grid [ttk::label .c.fereastraButoane.labelPassword -text {password:}] -column 2 -row 6 -sticky nsew
grid [ttk::entry .c.fereastraButoane.fieldPassword -textvariable password -show "*"] -column 2 -row 7 -sticky nsew
grid [ttk::button .c.fereastraButoane.butonLogOut -text "Log In" -command "login"] -column 2 -row 8 -sticky nsew
grid [ttk::button .c.fereastraButoane.butonLogIn -text "Log Out" -command "logout"] -column 2 -row 9 -sticky nsew

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

grid columnconfigure .c 1 -weight 1
grid rowconfigure .c 2 -weight 1

grid columnconfigure .c.fereastraConsola 1 -weight 1
grid rowconfigure .c.fereastraConsola 2 -weight 1

set workingDir $env(PWD)
set user "not-logged@cross-shell"

.c.fereastraConsola.con insert end "$user" usr
.c.fereastraConsola.con insert end ":" dff
.c.fereastraConsola.con insert end "$workingDir" dir
.c.fereastraConsola.con insert end ">" dff

set last [.c.fereastraConsola.con index "end-1c" ]

proc insertPrompt {} {
    global user
    global workingDir
    global last
    global DIR
    .c.fereastraConsola.con insert end "\n$user" usr
    .c.fereastraConsola.con insert end ":" dff
    .c.fereastraConsola.con insert end "$workingDir" dir
    .c.fereastraConsola.con insert end ">" dff
    set last [.c.fereastraConsola.con index "end-1c" ]
}

proc getText {} {
    global last

    set returnText [.c.fereastraConsola.con get $last end-1c ]
    set last [.c.fereastraConsola.con index "end-1c" ]
    return $returnText
}

proc insertText {arg } {
    global last
    .c.fereastraConsola.con insert $last "\n$arg"
    set last [.c.fereastraConsola.con index "end-1c" ]
}

proc pornire_exec_linux {} {
    global prompt
    global last
    global DIR
    global workingDir
    global env
    global seLogheaza
    set comanda [getText]
    if {$comanda eq ""} {
        puts eroare
        insertText "Eroare, Nu a fost inserata nicio comanda"
        insertPrompt
        return
    }

    puts $env(PWD)
    set pid [exec "$DIR\/Exec_main_linux.sh" $seLogheaza $DIR $env(PWD) &]
    puts $pid
    exec echo "$comanda" > "$DIR\/comSend"
    exec echo "$comanda" > "$DIR\/comPWSH"

    set fifo [open "$DIR\/outstream" r]
    fconfigure $fifo -blocking 0 
    set output ""
    while {!("$output" == "TERM")} {
        after 100
        set output [gets $fifo]
        if {!($output == "") && !("$output" == "TERM")} {
            insertText $output
        }
    }
    close $fifo
    set f [open "$DIR\/current_directory" r]
    set env(PWD) [gets $f]
    close $f
    set workingDir $env(PWD)
    puts executat
    puts $env(PWD)
    insertPrompt
}

proc pornire_exec_win {} {
    global prompt
    global last
    global DIR
    global workingDir
    global env
    global seLogheaza
    set comanda [getText]
    if {$comanda eq ""} {
        puts eroare
        insertText "Eroare, Nu a fost inserata nicio comanda"
        insertPrompt
        return
    }

    exec echo "$comanda" > "$DIR\/comPWSH"
    puts $env(PWD)
    set pid [exec "$DIR\/Exec_main_win.ps1" $seLogheaza $DIR $env(PWD) &]
    puts $pid

    set fifo [open "$DIR\/outstream" r]
    fconfigure $fifo -blocking 0 
    set output ""
    while {!("$output" == "TERM")} {
        after 100
        set output [gets $fifo]
        if {!($output == "") && !("$output" == "TERM")} {
            insertText $output
        }
    }
    close $fifo
    set f [open "$DIR\/current_directory" r]
    set env(PWD) [gets $f]
    close $f
    set workingDir $env(PWD)
    puts executat
    puts $env(PWD)
    insertPrompt
}

proc executa {} {
    global OS
    global last
    if { $OS == "unix"} {
        pornire_exec_linux
    } else {
        pornire_exec_win
    }
}

proc login {} {
    global user
    global DIR
    global username
    global password
    global OS
    if {![info exists username]} {
        insertText "Trebuie Introdus un username"
        insertPrompt
        return
    }
    if {![info exists password]} {
        insertText "Trebuie Introdus o parola"
        insertPrompt
        return
    }

    if {$OS == "unix"} {
    set hash [exec echo -n "$password" | sha256sum ]
    set hashcod [lindex [split $hash] 0]
    } else {
        set hashcod [exec Get-StringHash -String "$password" -Algorithm SHA256]
    }

    #Citire fiecare linie pana gasim utilizatorul
    set f [open "$DIR/usrs.txt"]
    while {[gets $f line] >= 0} {
        set tempname [lindex [split $line ";" ] 0]
        set temppass [lindex [split $line ";"] 1]
        if {"$tempname" == "$username"} {
            if {"$hashcod" == "$temppass"} {
                set user "$tempname\@crosshell"
                insertText "Logat cu succes ca $user"
                insertPrompt
                return
            } else {
                insertText "Username sau parola Incorecta"
                insertPrompt
                return
            }
        }
    }
    insertText "Nu s-a gasit username-ul"
    insertPrompt
    return
}

proc logout {} {
    global user
    set user "not-logged@cross-shell"
    insertPrompt
}