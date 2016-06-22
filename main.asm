;***********************************************************************************
; DATEINAME main.asm
;***********************************************************************************
; PROZESSOR PIC 16C505
; PINBELEGUNG
;     Vcc 1-*-14 Vss
;     2 13 Spannungsnulldurchgangserfassung
;     3 12 Stromnulldurchgangserfassung
;     4 11 LED1
;     5 10 LED2
;     6 9 Taster1
;     Triac 7 8 Taster2
;***********************************************************************************
LIST P=16C505           ; Festlegung des verwendeten Prozessors
#include <P16c505.inc>  ; Verwendung von vorgegebenen Variablennamen
                        ; für den Mikrocontroller
;****** Variablen Definitionen *****************************************************
warten      equ 08h   ; Register für Unterprogramm Warteschleife
alpha       equ 09h   ; Register zum Speichern des alphaWinkels
alphaNew    equ 0Ah    ; Register fuer veraendertem alphaWinkel
;******BIT Definitionen ***********************************************************
#DEFINE _Unull PORTB,0    ; Spannungsnulldurchgang
#DEFINE _Inull PORTB,1    ; Stromnulldurchgang
#DEFINE _triac PORTC,3    ; Ansteuerung Triac
#DEFINE _Taster1 PORTC,1  ; Ansteuerung Taster 1
#DEFINE _Taster2 PORTC,2  ; Ansteuerung Taster 2
#DEFINE _LED1 PORTB,2     ; Ansteuerung LED 1
#DEFINE _LED2 PORTC,0     ; Ansteuerung LED 2
;****** Start Vector ***************************************************************
ORG 01FFh ; Reset Adresse
GOTO MAIN
    ORG 0000h ; Start Adresse
GOTO MAIN

; Sprung zum Hauptprogramm/Initialisierung
;****** Initialisiere PIC **********************************************************
MAIN
    MOVWF OSCCAL        ; Timer kalibrieren
    CLRWDT              ; Clear Watchdog Timer
    MOVLW b'00000001'
    OPTION              ; setzt OPTION Register mit folgenden Werten
                        ; Bit7 wake-up on pin-change,
                        ; Bit6 weak pull-ups
                        ; Bit5 Timer0 on internal instruction clock,
                        ; Bit3 prescaler to Timer0
                        ; Bit0-2: Prescaler rate 1:4

    MOVLW b'11111011'
    TRIS PORTB           ; Setzt Pins des PortB(RB0..RB5) auf
    MOVLW b'11110110'    ; 1=Input(high-impedance), 0=Output
    TRIS PORTC           ; entsprechend ProtC(RC0..RC5)
    CLRF PORTB
    CLRF PORTC
    MOVLW h'0f'          ;Init alpha und alphaNew mit Hexadezimal 0F als Startwert
    MOVEWF alpha
    MOVEWF alphaNew

;*** Hauptprogramm *****************************************************************
Start
  bcf _LED1   ; LEDs clearen
  bcf _LED2

Spannung0           ; Synchronisation zu Beginn der Programms auf
  btfsc _Unull      ;Spannungsnulldurchgang       btfsc --> bit test skip if clear
  goto Spannung0

Spannung1
  btfss _Unull      ; weiter bei anliegen der Spannung
  goto Spannung1

  btfsc _Taster1    ; Test ob Taste 1 (Dunkler) gedrueckt
  goto dunkler      ; wenn ja, Sprung zum Label "dunkler"
  btfsc _Taster2    ;Test ob Taste 2 (Heller) gedrueckt
  goto heller       ; wenn ja, Sprung "heller"

Verzoegerung
  movf alpha,0            ;alpha in Akku und dann
  movwf warten            ;in Wartevariable speichern
  call warteschleife      ; VERZOEGERUNG um alpha:

                        ; ZUENDEN
  bsf _triac            ;Setzen des Zuendimpulses
  movlw d'5'            ;Zuenddauer in Akku und dann
  movwf warten          ;in Wartevariable speichern
  call warteschleife    ;warten
  bcf _triac            ;Zündimpuls löschen

  goto Start            ; Springe zurück und beginne von vorn


;*** dunkler **********************************************************
dunkler
  bsf _LED1            ;LED aktivieren
  incf alphaNew        ;Erhöhe alphaNew ( je groeßer alpha desto dunkler)
  btfss STATUS,Z       ;Übergelaufen?
  goto neuesAlpha    ;Nein --> Sprung zu neuesAlpha

  movlw h'FF'          ;Ja --> Schreiben wir halt alles 1en in das Register
  movwf alphaNew

neuesAlpha            ;Überschreibe den alten alpha Winkel mit alphaNew
  movf alphaNew, 0
  movwf alpha
  goto Verzoegerung

;*** heller ***********************************************************
heller
  bsf _LED2
  decf alphaNew         ;Verringere alphaNew

  movlw h'29'           ;Prüfe ob alphaNew = hex 29
  movwf a               ;(kleinster gewollter Helligkeitswert 30)
  movf alphaNew,0
  subwf a,0
  btfss STATUS,Z
  goto neuesAlpha

  movlw h'30'           ;Falls zu klein --> setze alphaNew auf hex 30
  movwf alphaNew
  goto neuesAlpha


;***  Warteschleife ***************************************************
;Zykluszeit 1us
warteschleife
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    decfsz warten,1            ;warten 0? --> da vorher alpha in warten geschrieben
                               ;wurde ist die Wartezeit von alpha abhängig
    goto warteschleife         ;Nein? Weiter warten
    retlw 0h                  ;beende warteschleife

END
;***********************************************************************************
