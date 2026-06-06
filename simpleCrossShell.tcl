#!/usr/bin/env tclsh

#Tk este folosit pentru GUI
package require Tk
#tdom este folosit pentru XML parsing
package require tdom

#salvam directorul script-ului
set DIR [file dirname [info script]]

#detectam platforma
set OS $tcl_platform(platform)
puts "Platforma detectat : $OS"

#comSend/comPWSH este pipe-ul prin care procesul in lant de executie comunica cu interfata grafica
if { $OS == "unix" } {
    if {![file exists ./comSend]} {
        exec mkfifo comSend
    }
} else {
    if {![file exists ./comPWSH]} {
        exec mkfifo comPWSH
    }
}
#Aici se configureaza variabilele temei GUI-ului
#Incarcam valorile default in cazul in care apar probleme cu documentul de configurare
set defBG "#242424" 
set defFG "#F2FFFF"
set usrcol "#37FF00"
set dircol "#00FFDC"
set TITLE "Simple Cross Shell"
set WIDTH 512
set HEIGHT 256

#Incercam sa incarcam din XML
set CONFIG "config.xml"
if {[file exists "$DIR/$CONFIG"]} {
    set dom [dom parse -channel [open "$DIR/$CONFIG" r]]
    set doc [$dom documentElement]

    if {[catch {
        set bgValue [ [$doc selectNodes "/config/theme/background"] asText ]
        if {$bgValue ne ""} {
            set defBG [string trim $bgValue "\""]
        }
        
        set fgValue [ [$doc selectNodes "/config/theme/foreground"] asText ]
        if {$fgValue ne ""} {
            set defFG [string trim $fgValue "\""]
        }
        
        set usrValue [ [$doc selectNodes "/config/theme/user"] asText ]
        if {$usrValue ne ""} {
            set usrcol [string trim $usrValue "\""]
        }
        
        set dirValue [ [$doc selectNodes "/config/theme/dir"] asText ]
        if {$dirValue ne ""} {
            set dircol [string trim $dirValue "\""]
        }

        set titleNode [$doc selectNodes "/config/window/title"]
            if {$titleNode ne ""} {
                set TITLE [string trim [$titleNode asText] "\""]
            }
            
            set widthNode [$doc selectNodes "/config/window/width"]
            if {$widthNode ne ""} {
                set WIDTH [string trim [$widthNode asText] "\""]
            }
            
            set heightNode [$doc selectNodes "/config/window/height"]
            if {$heightNode ne ""} {
                set HEIGHT [string trim [$heightNode asText] "\""]
            }
        
        $dom delete
        
    }]} {
        puts "A aparut o eroare la incarcarea XML-ului"
    }
} else {
    puts "Fisierul config.xml nu exista"
}

#Crearea de fereastra
wm title . $TITLE
wm minsize . $WIDTH $HEIGHT
wm iconphoto . [image create photo -file $DIR\/icon.gif]
ttk::frame .c -padding "3 3 12 12" -borderwidth 2

ttk::frame .c.fereastraConsola -padding 10 -borderwidth 2 -relief sunken 
ttk::frame .c.fereastraButoane -padding 10 -borderwidth 2 -relief sunken 

grid .c -column 0 -row 0 -sticky nwes
grid .c.fereastraConsola -column 1 -row 2 -sticky wesn -rowspan 6
grid .c.fereastraButoane -column 2 -row 2 -sticky wesn -rowspan 6

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
#Procedura de pornire a scriptului de executie pentru Linux
proc pornire_exec_linux {} {
    global prompt
    global last
    global DIR
    global workingDir
    global env
    global seLogheaza
    set comanda [getText]
    if {$comanda eq ""} {
        puts "eroare"
        insertText "Eroare, Nu a fost inserata nicio comanda"
        insertPrompt
        return
    }

    puts $env(PWD)
    set pid [exec "$DIR\/Exec_main_linux.sh" $seLogheaza $DIR $env(PWD) &]
    puts $pid
    exec echo "$comanda" > "$DIR\/comSend"

    set fifo [open "$DIR\/outstream" r]
    fconfigure $fifo -blocking 0 
    set output ""
    while {!("$output" == "TERM")} {
        update
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

#Procedura de pornire a scriptului de executie pentru Windows
proc pornire_exec_win {} {
    global prompt
    global last
    global DIR
    global workingDir
    global env
    global seLogheaza
    set comanda [getText]
    if {$comanda eq ""} {
        puts "eroare"
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
        update
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

#se porneste script-ul de executie fan-out then in lant.
proc executa {} {
    global OS
    global last
    if { $OS == "unix"} {
        pornire_exec_linux
    } else {
        pornire_exec_win
    }
}

#Aceasta functie nu logheaza un utilizator de sistem, ci un mockup de utilizator 
#din fisierul users.txt. Nu are nici un folos practic, implementat doar pentru proiect.
#Autentificarea reala ar fi durat mult prea mult de implementat.
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