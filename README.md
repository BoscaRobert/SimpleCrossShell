This project is a Tcl/Tk GUI-based command executor with pipe chaining and inter-process communication via named pipes (FIFOs).

## Dependencies

- **Tcl/Tk** — core runtime and GUI
- **tDOM** — XML/DOM parsing
- **Bash** — command execution backend (Unix only)

### Installing Dependencies on Debian/Ubuntu
```bash
sudo apt install tcl tk tdom
```

## Running the program
To run the program, use the tcl shell to run the simpleCrossShell.tcl script
```bash
tclsh simpleCrossShell.tcl
```
## How to use
The program works similar to a terminal. You input commands in the textbox, but instead of pressing Enter to execute the command(s), you have to press the "Executa" button
If the "Logheaza" checkbox is checked, the program will log each command executed in a local `log.txt` file
The authentication system does not authenticate actual system users,it simulates a user login system using a local `users.txt` file.txt

You can configure the window size and color palette by editing the `config.xml` file

## Platform Support
Linux - supported

Windows - work in progress

## Localization
romanian - available

english - work in progress
## Screenshot


<img width="879" height="542" alt="Screenshot_20260606_172144" src="https://github.com/user-attachments/assets/61fd0cc4-97a5-4abe-829e-a715eede5c42" />

