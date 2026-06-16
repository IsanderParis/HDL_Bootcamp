# Project: Simon Says
# Isander Paris Santiago

----------------------
## Project Description
----------------------

- This repository was used to document and share my code while building a digital version of the classic Simon Says game on the Basys3 FPGA board. Here you will find the VHDL entities and the constraints file used in the project, but if you want to run and implement the code, you will need to build the project in Vivado.

- A version of the Simon Says game was implemented using digital logic synthesized on the Basys3. The design applies finite state machine (FSM) principles, sequential logic, and I/O handling covered in class.

- The game generates a random sequence of colors that the user must repeat using the buttons. Each round adds one more color to the sequence. If the player makes a mistake or does not respond within 16 seconds, the game ends.

---------------
## I/O Mapping
----------------

- LEDs [15:0]
    Divided into 4 groups of 4, one per color (Red, Green, Yellow, Blue)
- 7-segment display
    Shows the current score and the high score
- Buttons (W19, U17, T17, T18)
    User input — color selection
- Button (U18)
    Start / confirm
- Switch (R2)
    Game reset
- Switches (V16, V17)
    Difficulty control
- Output pin (external buzzer)
    Generates a different tone for each color

---------------------
### Main Entities ###
---------------------

# key_controller 
    - Reads button inputs and returns a stable debounced signal
# wdt
    - Sends an alert signal if 16 seconds have passed without user activity
# rand_gen 
    - Randomly selects among the 4 colors to build the game sequence
# game_controller : 
    - Main state machine that coordinates all phases of the game
# display : 
    - Converts the numeric score to the corresponding 7-segment display encoding
# buzzer : 
    - Converts each color into an audio frequency and emits it through the output pin
# top_module : 
    - Interconnects all modules and maps signals to the physical pins of the Basys3

----------------
### Diagrams ###
----------------

 # state_diagram
 - The figure shown in state_diagram.jpeg shows the state diagram used to build the game. 
 - This was my first step in the programming process but it was later revised until its final version shown.

 # entities_diagram
 - The figure shown in entities_diagram.pdf is a diagram of every interconection in between every entity used for the implementation of the game.





-------------------------------------------------------------------------------------
## Demo
-------------------------------------------------------------------------------------
Video de demostración del proyecto funcionando en la Basys3:
Ver en Google Drive

-------------------------------------------------------------------------------------
## Cómo implementarlo en Vivado

1. Crear un nuevo proyecto en Vivado seleccionando la Basys3 (xc7a35tcpg236-1)
2. Agregar todos los archivos .vhd de la carpeta src/ como fuentes de diseño
3. Agregar el archivo .xdc de constraints/ como fuente de constraints
4. Ejecutar Synthesis → Implementation → Generate Bitstream
5. Conectar la Basys3 y programar con Open Hardware Manager