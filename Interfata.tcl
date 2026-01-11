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
grid .c.fereastraConsola -column 1 -row 2 -sticky wesn -rowspan 4
grid .c.fereastraButoane -column 2 -row 2 -sticky wesn -rowspan 4

set defBG "gray15" 
set defFG "white"
set usrcol "green"
set dircol "blue"

grid [text .c.fereastraConsola.con -wrap word -background $defBG -foreground $defFG] -column 1 -row 2 -sticky wesn -rowspan 3

.c.fereastraConsola.con tag configure usr -foreground $usrcol
.c.fereastraConsola.con tag configure dir -foreground $dircol
.c.fereastraConsola.con tag configure dfb -background $defBG
.c.fereastraConsola.con tag configure dff -foreground $defFG


grid [ttk::button .c.fereastraButoane.butonExec -text "Executa" -command "executa"] -column 2 -row 2 -sticky nsew
grid [ttk::button .c.fereastraButoane.butonLog -text "Executa\n     si\nlogeaza" -command "log"] -column 2 -row 3 -sticky nsew
grid [ttk::button .c.fereastraButoane.butonLogOut -text "Log\n In" -command "login"] -column 2 -row 4 -sticky nsew
grid [ttk::button .c.fereastraButoane.butonLogIn -text "Log\nOut" -command "logout"] -column 2 -row 5 -sticky nsew

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
    set comanda [getText]
    if {$comanda eq ""} {
        puts eroare
        insertText "Eroare, Nu a fost inserata nicio comanda"
        insertPrompt
        return
    }

    puts $env(PWD)
    set pid [exec "$DIR\/Exec_main_linux.sh" nolog $DIR $env(PWD) &]
    puts $pid
    exec echo "$comanda" > "$DIR\/comSend"

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
    }
}