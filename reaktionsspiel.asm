.include "m328pdef.inc"

; Das ist die Arbeit von Gruppe J  (Ahmad und Habib )


; =====================================================
; ================ CONSTANT DEFINITIONS ===============
; =====================================================
.equ CLK       = 3       ; PD3 - TM1637 Clock
.equ DIO       = 4       ; PD4 - TM1637 Data
.equ LED_BIT   = 5       ; PD5 - LED
.equ BUZZ_BIT  = 6       ; PD6 - Buzzer
.equ BTN1_BIT  = 2       ; PD2 - Player 1 button
.equ BTN2_BIT  = 7       ; PD7 - Player 2 button
.equ MAX_SCORE = 10

; =====================================================
; ================== REGISTER USAGE ===================
; =====================================================
.def p1_score   = r20
.def p2_score   = r21
.def temp       = r16
.def bcd_tens   = r19
.def seed       = r25

; Temp registers used in TM1637_display_score
; r0-r7, r17, r18, r22, r23, r24, r26, r27 are used

; =====================================================
; ===================== RESET =========================
; =====================================================
.org 0x0000
    rjmp RESET

RESET:
    clr temp
    clr p1_score
    clr p2_score
    clr bcd_tens

    ; Initialize pseudo-random seed
    in seed, TCNT0
    andi seed, 0x7F
    cpi seed, 0
    brne seed_ok
    ldi seed, 0x55
seed_ok:

    ; Setup outputs
    sbi DDRD, LED_BIT
    sbi DDRD, BUZZ_BIT
    sbi DDRD, CLK
    sbi DDRD, DIO

    ; Setup inputs with pull-ups
    cbi DDRD, BTN1_BIT
    cbi DDRD, BTN2_BIT
    sbi PORTD, BTN1_BIT
    sbi PORTD, BTN2_BIT

    ; Timer0: Prescaler 64
    ldi temp, (1 << CS01) | (1 << CS00)
    out TCCR0B, temp

    ; Initialize display
    rcall TM1637_init
    rcall Display_P1P2

; =====================================================
; ===================== MAIN LOOP =====================
; =====================================================
main_loop:
    cbi PORTD, LED_BIT           ; Turn off LED
    rcall wait_random_delay     ; Wait random time
    sbi PORTD, LED_BIT           ; Signal players

wait_for_button:
    sbic PIND, BTN1_BIT
    rjmp btn1_pressed
    sbic PIND, BTN2_BIT
    rjmp btn2_pressed
    rjmp wait_for_button

btn1_pressed:
    rcall delay_20ms
    sbis PIND, BTN1_BIT
    rjmp wait_for_button
    inc p1_score
    rcall TM1637_display_score
wait_btn1_release:
    sbic PIND, BTN1_BIT
    rjmp wait_btn1_release
    rjmp check_winner

btn2_pressed:
    rcall delay_20ms
    sbis PIND, BTN2_BIT
    rjmp wait_for_button
    inc p2_score
    rcall TM1637_display_score
wait_btn2_release:
    sbic PIND, BTN2_BIT
    rjmp wait_btn2_release

check_winner:
    cpi p1_score, MAX_SCORE
    breq player1_wins
    cpi p2_score, MAX_SCORE
    breq player2_wins
    rjmp main_loop

player1_wins:
    ldi temp, MAX_SCORE
    rcall blink_and_buzz
    rjmp end

player2_wins:
    ldi temp, MAX_SCORE
    rcall blink_and_buzz
    rcall blink_and_buzz
    rjmp end

end:
    rjmp end

; =====================================================
; ================= DISPLAY FUNCTIONS =================
; =====================================================
Display_P1P2:
    ; Show 'P1P2'
    rcall TM1637_start
    ldi temp, 0x40
    rcall TM1637_write
    rcall TM1637_stop

    rcall TM1637_start
    ldi temp, 0xC0
    rcall TM1637_write
    ldi temp, 0x73    ; 'P'
    rcall TM1637_write
    ldi temp, 0x86    ; '1' + colon
    rcall TM1637_write
    ldi temp, 0x73    ; 'P'
    rcall TM1637_write
    ldi temp, 0x5B    ; '2'
    rcall TM1637_write
    rcall TM1637_stop

    ; Brightness
    rcall TM1637_start
    ldi temp, 0x8A    ; Brightness level 2
    rcall TM1637_write
    rcall TM1637_stop
    ret

TM1637_init:
    rcall TM1637_start
    ldi temp, 0x40
    rcall TM1637_write
    rcall TM1637_stop
    ret

TM1637_display_score:
    ; Convert both scores to BCD
    mov temp, p1_score
    rcall ByteToBcd
    mov r0, r22
    mov r1, r23

    mov temp, p2_score
    rcall ByteToBcd
    mov r2, r22
    mov r3, r23

    ; Segment conversion
    mov temp, r0
    rcall ConvertDigitToSegment
    mov r4, r17

    mov temp, r1
    rcall ConvertDigitToSegment
    ori r17, 0x80
    mov r5, r17

    mov temp, r2
    rcall ConvertDigitToSegment
    mov r6, r17

    mov temp, r3
    rcall ConvertDigitToSegment
    mov r7, r17

    ; Send to display
    rcall TM1637_start
    ldi temp, 0x40
    rcall TM1637_write
    rcall TM1637_stop

    rcall TM1637_start
    ldi temp, 0xC0
    rcall TM1637_write
    mov temp, r4
    rcall TM1637_write
    mov temp, r5
    rcall TM1637_write
    mov temp, r6
    rcall TM1637_write
    mov temp, r7
    rcall TM1637_write
    rcall TM1637_stop
    ret

; =====================================================
; ================== UTILITY ROUTINES =================
; =====================================================
ByteToBcd:
    clr bcd_tens
bcd_loop:
    cpi temp, 10
    brlo bcd_done
    subi temp, 10
    inc bcd_tens
    rjmp bcd_loop
bcd_done:
    mov r22, bcd_tens
    mov r23, temp
    ret

ConvertDigitToSegment:
    ldi ZH, high(SegTable*2)
    ldi ZL, low(SegTable*2)
    add ZL, temp
    ldi temp, 0
    adc ZH, temp
    lpm r17, Z
    ret

; =====================================================
; ============= TM1637 COMMUNICATION ==================
; =====================================================
TM1637_write:
    ldi r19, 8
write_loop:
    cbi PORTD, CLK
    sbrs temp, 0
    cbi PORTD, DIO
    sbrc temp, 0
    sbi PORTD, DIO
    lsr temp
    sbi PORTD, CLK
    rcall Delay
    dec r19
    brne write_loop

    ; Wait for ACK
    cbi PORTD, CLK
    cbi DDRD, DIO
    sbi PORTD, DIO
    sbi PORTD, CLK
    rcall Delay
    sbic PIND, DIO
    rjmp no_ack
    cbi PORTD, CLK
    sbi DDRD, DIO
    ret

no_ack:
    cbi PORTD, CLK
    sbi DDRD, DIO
    rcall TM1637_stop
    ret

TM1637_start:
    sbi PORTD, CLK
    sbi PORTD, DIO
    cbi PORTD, DIO
    cbi PORTD, CLK
    rcall Delay
    ret

TM1637_stop:
    cbi PORTD, CLK
    cbi PORTD, DIO
    sbi PORTD, CLK
    sbi PORTD, DIO
    rcall Delay
    ret

; =====================================================
; ===================== DELAYS ========================
; =====================================================
Delay:
    ldi r18, 19
delay_loop:
    nop
    dec r18
    brne delay_loop
    ret

delay_20ms:
    ldi r18, 160
outer:
    ldi r26, 200
inner:
    nop
    nop
    dec r26
    brne inner
    dec r18
    brne outer
    ret

delay_100ms:
    ldi r27, 5
loop_100:
    rcall delay_20ms
    dec r27
    brne loop_100
    ret

; =====================================================
; =============== RANDOM DELAY (2-10s) ================
; =====================================================
wait_random_delay:
    lsl seed
    brcc no_xor
    ldi temp, 0xB4
    eor seed, temp
no_xor:
    in temp, TCNT0
    eor seed, temp

    mov r18, seed
    ldi r19, 81
    mul r18, r19
    mov r18, r1
    ldi r24, 20
    add r24, r18

random_delay_loop:
    rcall delay_100ms
    rcall delay_100ms
    dec r24
    brne random_delay_loop
    ret

; =====================================================
; ================ VICTORY BLINKING ===================
; =====================================================
blink_and_buzz:
blink_loop:
    sbi PORTD, LED_BIT
    sbi PORTD, BUZZ_BIT
    rcall delay_100ms
    cbi PORTD, LED_BIT
    cbi PORTD, BUZZ_BIT
    rcall delay_100ms
    dec temp
    brne blink_loop
    ret

; =====================================================
; ================= SEGMENT LOOKUP ====================
; =====================================================
SegTable:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66
    .db 0x6D, 0x7D, 0x07, 0x7F, 0x6F
