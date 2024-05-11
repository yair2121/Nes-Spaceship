# Spaceship Demo
**Programming Language**: C65 Assembly<br />
**Platform**: Nintendo Entertainment System (NES) from 1983<br />
**Processor**: Ricoh 2A03 (modified 8-bit 6502 processor)<br />
#### Description
The Spaceship Demo features a spaceship with basic interactivity, including shooting lasers (A button) and movement (D-pad). Additionally, the spaceship emits a fire-like animation from its back thrusters. The fire moves in the opposite direction of the spaceship’s movement.

Installation:
1. Download the cc65 compiler.
2. Clone the project.
3. Compile the “asm” file using the following commands:
```
ca65 spaceship.asm -o spaceship.o -t nes
ld65 spaceship.o -o spaceship.nes -t nes
```
4. Run the "spaceship.nes" file using a NES emulator of your choice.
