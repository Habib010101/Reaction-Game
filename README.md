# Two-Player Reaction Game in AVR Assembly

A two-player reaction game developed in AVR Assembly for the **ATmega328P** microcontroller.

The system waits for a randomized amount of time and then turns on an LED. Both players must press their button as quickly as possible. The first detected player receives one point, and the current score is displayed on a four-digit TM1637 seven-segment display.

The first player to reach **10 points** wins.

## Project Information

This project was developed as a university microcontroller project by **Group J**.

**Team members:**

- Ahmad
- Habib Ibrahim

## Features

- Two-player reaction game
- Written entirely in AVR Assembly
- Random delay before each round
- LED reaction signal
- Two mechanical push buttons
- Software button debouncing
- Four-digit TM1637 score display
- Buzzer and LED victory indication
- First player to 10 points wins
- Internal pull-up resistors for button inputs

## Hardware

- ATmega328P microcontroller
- TM1637 four-digit seven-segment display
- Two mechanical push buttons
- LED
- Buzzer
- Breadboard and jumper wires
- Suitable resistors
- Microcontroller programmer or compatible development board

## Pin Configuration

| Component | ATmega328P pin | Port |
|---|---:|---|
| Player 1 button | PD2 | Digital input |
| TM1637 clock | PD3 | Digital output |
| TM1637 data | PD4 | Digital output |
| LED | PD5 | Digital output |
| Buzzer | PD6 | Digital output |
| Player 2 button | PD7 | Digital input |

The buttons use the ATmega328P internal pull-up resistors.

Therefore:

- Button released: `HIGH`
- Button pressed: `LOW`

## How the Game Works

1. The scores of both players are initialized to zero.
2. The display briefly shows `P1P2`.
3. The LED is switched off.
4. The microcontroller waits for a randomized amount of time.
5. The LED turns on to signal the beginning of the round.
6. Both players try to press their button first.
7. The button signal is checked again after a short debounce delay.
8. The successful player's score is increased.
9. The updated scores are shown on the TM1637 display.
10. The next round begins.
11. The game ends when one player reaches 10 points.

## Button Debouncing

Mechanical buttons can generate several rapid electrical transitions when pressed. This is known as **switch bounce**.

The program uses a delay of approximately 20 milliseconds before confirming a button press:

```asm
rcall delay_20ms
```

After the delay, the input is checked again. This helps prevent one physical button press from being interpreted as multiple presses.

## Random Delay

Timer0 is used as part of the pseudo-random seed.

The program combines the current Timer0 counter value with an updated seed to create a different waiting time before each round:

```asm
in temp, TCNT0
eor seed, temp
```

This makes it more difficult for players to predict exactly when the LED will turn on.

## Score Display

The player scores are converted into decimal digits and then converted into seven-segment display values.

For example:

```text
Player 1: 03
Player 2: 07
Display: 03:07
```

The `SegTable` lookup table contains the segment representation for digits from 0 to 9.

## Victory Signal

When a player reaches the maximum score, the program activates the LED and buzzer using a blinking pattern.

Player 1 and Player 2 use different victory patterns so that the winner can also be identified without looking at the display.

## Repository Structure

```text
reaction-game/
├── README.md
├── src/
│   └── reaction_game.asm
├── presentation/
│   ├── project-presentation.pptx
│   └── project-presentation.pdf
└── images/
    ├── circuit.jpg
    └── project-demo.jpg
```

## Building the Project

The source code uses the ATmega328P definition file:

```asm
.include "m328pdef.inc"
```

The project can be assembled using tools such as:

- Microchip Studio
- AVR Assembler
- A compatible AVR toolchain

General steps:

1. Create a new AVR Assembly project.
2. Select the ATmega328P as the target microcontroller.
3. Add `reaction_game.asm` to the project.
4. Build the project.
5. Flash the generated program to the microcontroller.
6. Connect the display, buttons, LED and buzzer according to the pin table.

## Timing Note

The delay routines use instruction-counting loops. Their actual duration depends on the CPU clock frequency.

If the microcontroller clock frequency changes, the delay routines may need to be recalculated.

## What We Learned

During this project, we worked with:

- AVR Assembly programming
- Digital input and output
- Mechanical switch debouncing
- Timer-based pseudo-random behavior
- TM1637 serial communication
- Seven-segment display encoding
- Register management
- Low-level delay routines
- Hardware testing and debugging

## Possible Improvements

Future improvements could include:

- Detecting and penalizing early button presses
- Using hardware interrupts for the buttons
- Using timer interrupts instead of blocking delay loops
- Adding a reset button
- Adding multiple game modes
- Improving the random number generation
- Playing different buzzer sounds for each player
- Adding a start countdown
- Saving scores in EEPROM

## Authors

**Group J**

- Ahmad Thaljeh
- Habib Ibrahim

## License

This project was created for educational purposes as part of a university microcontroller course.
