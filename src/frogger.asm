; ==========================================================================
; FROGGER - Konami - MSX1 - cartucho RC-704 de 8 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: La cabecera del cartucho. "AB" y despues INIT, 0x41B4, con
;   el byte bajo delante. Los otros tres vectores -STATEMENT, DEVICE y TEXT-
;   van a cero: este cartucho solo se arranca.
;   0x4000..0x4012  (18 bytes)
DATA_cabecera:
	defb 041h,042h	; 4000
	defw 041b4h	; 4002  -> INIT
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 4004  ............
	defb 000h,000h	; 4010

; ======================================================================
; CODIGO 0x4012..0x49a3  (2449 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA INTERRUPCION. La BIOS entra aqui en cada retrazo por el gancho H.KEYI. Lo primero que decide es de que se ocupa este fotograma, mirando 0xE043; despues, si hay partida, que escena toca, mirando 0xE040.
; ----------------------------------------------------------------------
INTERRUPCION:
	push hl			;4012   ; los cuatro pares de registros se guardan: se entra desde la interrupcion
	push de			;4013
	push bc			;4014
	push af			;4015
	in a,(099h)		;4016   ; leer el estado del VDP es lo que reconoce la interrupcion
	ld hl,0e043h		;4018   ; 0xE043 reparte el fotograma: bit 0, solo la demo y el sonido; bit 6, solo el sonido
	ld a,(hl)			;401b
	rrca			;401c
	jp c,SOLO_DEMO_Y_SONIDO		;401d
	bit 6,(hl)		;4020
	jp nz,SUENAN_LOS_TRES_CANALES		;4022
	ld hl,0e015h		;4025   ; sin partida en marcha no hay nada que mover, solo la cuenta de fotogramas
	xor a			;4028
	cp (hl)			;4029
	jp z,CUENTA_DE_FOTOGRAMAS		;402a
	dec hl			;402d
	cp (hl)			;402e   ; con la demo en marcha los mandos no se leen: salen de una lista
	jr nz,PILOTA_LA_DEMO		;402f
	ld a,(0e007h)		;4031   ; 1 = joystick (registro 14 del PSG), 0 = teclado (los cursores)
	or a			;4034
	jr z,LEE_EL_TECLADO		;4035
	call LEE_EL_JOYSTICK		;4037
	cpl			;403a   ; el joystick da las lineas a cero: se invierten
	and 00fh		;403b   ; los cuatro bits bajos: las cuatro direcciones
	jr GUARDA_MANDOS		;403d
LEE_EL_TECLADO:		; Los cursores, y ademas quita el bit del disparo si hay tecla de por medio
	call LOS_CURSORES_COMO_JOYSTICK		;403f
	ld b,a			;4042
	ld a,c			;4043   ; el bit 0 de la fila 8 es el espacio, que hace de primer boton
	rrca			;4044
	jr nc,MIRA_FILA_7		;4045
	ld a,0efh		;4047   ; el 0xEF apaga el bit 4, que es el primer boton
	and b			;4049
	ld b,a			;404a
MIRA_FILA_7:
	ld a,007h		;404b   ; fila 7 del teclado, para el bit 6
	call LEE_UNA_FILA		;404d   ; fila 7 del teclado
	bit 6,a		;4050   ; y el bit 6 de la fila 7 -la tecla SELECT- del segundo
	jr nz,MANDOS_LISTOS		;4052
	ld a,0dfh		;4054   ; y el 0xDF el bit 5, que es el segundo
	and b			;4056
	ld b,a			;4057
MANDOS_LISTOS:
	ld a,b			;4058
	jr INVIERTE		;4059
PILOTA_LA_DEMO:		; Un byte de la lista de 0x584F por cada espera agotada
	ld hl,0e018h		;405b
	ld a,(hl)			;405e
	or a			;405f
	ld a,000h		;4060
	jr nz,MANDOS_A_E009		;4062
	ld (hl),001h		;4064   ; y se apunta que ya se ha leido
	ld hl,0e049h		;4066   ; el puntero de la demo tiene el byte ALTO delante, y solo sube el bajo
	ld d,(hl)			;4069
	inc hl			;406a
	ld e,(hl)			;406b
	inc (hl)			;406c   ; se avanza al leerlo, asi que la lista se consume de una vez
	ex de,hl			;406d
	ld a,(hl)			;406e
	jr MANDOS_A_E009		;406f
INVIERTE:
	cpl			;4071
GUARDA_MANDOS:
	ld hl,0e008h		;4072   ; 0xE008 son los mandos de antes; solo se apunta el cambio
	cp (hl)			;4075
	jr z,MANDOS_A_E009		;4076
	ld (hl),a			;4078
	inc hl			;4079
	ld a,(hl)			;407a
MANDOS_A_E009:
	ld hl,0e009h		;407b
	ld (hl),a			;407e
	ld hl,0e280h		;407f   ; sin nada pulsado, la rana deja de estar a mitad de un salto
	or a			;4082
	jr nz,QUE_ESCENA_TOCA		;4083
	res 1,(hl)		;4085   ; el bit 1 apagado: el salto se da por terminado

; ----------------------------------------------------------------------
; QUE ESCENA TOCA. 0xE040 se lee bit a bit con rrca: cada bit es una escena, y si no hay ninguno corre el juego normal. Bit 0 la muerte, bit 1 el bonus del tiempo (dentro del juego), bit 2 la fase superada, bit 3 el fin de la partida, bit 4 montar la fase.
; ----------------------------------------------------------------------
QUE_ESCENA_TOCA:
	ld hl,0e040h		;4087
	ld a,(hl)			;408a
	rrca			;408b   ; bit 0: la rana ha muerto
	jr c,ESCENA_MUERTE		;408c
	rrca			;408e
	rrca			;408f   ; bit 2: fase superada
	jr c,ESCENA_FASE_SUPERADA		;4090
	rrca			;4092   ; bit 3: se acabo la partida
	jr c,ESCENA_FIN_DE_PARTIDA		;4093
	rrca			;4095   ; bit 4: hay que montar la fase
	jr c,ESCENA_MONTA_FASE		;4096
	call MUEVE_LOS_CARRILES		;4098   ; el juego normal, en este orden: los carriles, la rana, el bicho del rio, la rana que se rescata y los choques
	call MUEVE_LA_RANA		;409b
	call EL_BICHO_DEL_RIO		;409e
	call LA_RANA_RESCATABLE		;40a1
	call LOS_CHOQUES		;40a4
	jr nc,SIGUE_EL_JUEGO		;40a7   ; si 0x5185 devuelve acarreo la rana ha muerto, y se pasa a la escena de la muerte
	xor a			;40a9
	ld (0e018h),a		;40aa   ; la espera se limpia antes de entrar en la muerte
	jr ESCENA_MUERTE		;40ad
SIGUE_EL_JUEGO:
	call EL_RELOJ		;40af   ; el reloj de la partida
	ld hl,0e040h		;40b2
	bit 1,(hl)		;40b5   ; bit 1: la rana ya esta en casa y corre el bonus del tiempo
	call nz,ENTRA_EN_CASA		;40b7
	jr SOLO_DEMO_Y_SONIDO		;40ba
ESCENA_MUERTE:
	call SE_MUERE		;40bc
	jr SOLO_DEMO_Y_SONIDO		;40bf
ESCENA_FASE_SUPERADA:
	call BONUS_DEL_TIEMPO		;40c1
	jr SOLO_DEMO_Y_SONIDO		;40c4
ESCENA_MONTA_FASE:
	call MONTA_LA_FASE		;40c6
	jr SOLO_DEMO_Y_SONIDO		;40c9
ESCENA_FIN_DE_PARTIDA:
	call SE_ACABO_LA_PARTIDA_YA		;40cb
	jr SOLO_DEMO_Y_SONIDO		;40ce
SOLO_DEMO_Y_SONIDO:
	ld a,(0e014h)		;40d0
	or a			;40d3
	jr z,PARPADEA_EL_1UP		;40d4
	ld hl,0e043h		;40d6
	ld a,(0e031h)		;40d9   ; con el canal 3 callado se sale del reparto reducido
	or a			;40dc
	jr nz,MIRA_EL_BIT_7		;40dd
	ld (hl),000h		;40df   ; el reparto vuelve a cero: se juega entero otra vez
MIRA_EL_BIT_7:
	ld a,(hl)			;40e1
	rlca			;40e2
	jr c,SUENAN_LOS_TRES_CANALES		;40e3
	jr CUENTA_DE_FOTOGRAMAS		;40e5
PARPADEA_EL_1UP:
	call PARPADEO_DEL_JUGADOR		;40e7
SUENAN_LOS_TRES_CANALES:
	ld hl,0e021h		;40ea   ; la ficha del canal 1 empieza en 0xE020, y PASO_DE_CANAL entra apuntando a su byte +1
	call PASO_DE_CANAL		;40ed
	ld hl,0e029h		;40f0   ; el canal 2, ocho bytes mas alla
	call PASO_DE_CANAL		;40f3
	ld hl,0e031h		;40f6   ; y el canal 3; de aqui se cae en la cuenta de fotogramas, sin salto
	call PASO_DE_CANAL		;40f9
CUENTA_DE_FOTOGRAMAS:
	ld hl,0e019h		;40fc
	inc (hl)			;40ff   ; 0xE019 sube en todos los fotogramas, pase lo que pase
	ld a,(hl)			;4100
	and 01fh		;4101   ; una vez cada 32 se descuenta la espera de 0xE018
	jr nz,INTERRUPCION_SALIDA		;4103
	dec hl			;4105
	cp (hl)			;4106
	jr z,INTERRUPCION_SALIDA		;4107
	dec (hl)			;4109   ; y si no, la espera baja un punto
INTERRUPCION_SALIDA:
	pop af			;410a   ; se devuelven los cuatro pares que apilo 0x4012, en el orden contrario
	pop bc			;410b
	pop de			;410c
	pop hl			;410d
	ei			;410e   ; se sale con las interrupciones ya abiertas; el `reti` hace aqui de `ret`, porque al gancho se entra con un `call` de la BIOS
	reti		;410f

; ----------------------------------------------------------------------
; EL REPRODUCTOR DE SONIDO. Un canal por llamada, con la ficha de 8 bytes en HL-1. El programa se guarda en el propio cartucho como una tira de notas de tres bytes: periodo bajo, periodo alto con el volumen en el nibble de arriba y el bit 3 para el ruido, y duracion. Con la duracion negativa la nota se va apagando sola. Estos 163 bytes son EL MISMO CODIGO que 0x4160-0x4202 de Time Pilot: de los 163 solo tres bytes cambian, y dos de ellos son el byte bajo de un puntero reubicado (0x41A1 aqui, 0x41F0 alli, el desfase 0x4F exacto).
; ----------------------------------------------------------------------
PASO_DE_CANAL:		; Un paso del canal cuya ficha empieza en HL-1
	ld a,(hl)			;4111   ; con el byte de arriba del puntero a cero, el canal esta callado
	or a			;4112
	ret z			;4113
	dec hl			;4114
	ld e,(hl)			;4115   ; los dos primeros bytes de la ficha son el puntero al programa
	inc hl			;4116
	ld d,(hl)			;4117
	ld c,0a1h		;4118   ; el 0xA1 es el puerto de datos del PSG
	inc hl			;411a
	ld a,(hl)			;411b   ; el tercero es lo que le queda a la nota; con el bit 7, ademas, se apaga sola
	and 07fh		;411c   ; los siete bits bajos son lo que queda de nota
	jr z,CANAL_NOTA_NUEVA		;411e
	ld a,(hl)			;4120
	bit 7,a		;4121
	jr z,CANAL_SIGUE		;4123
	and 07fh		;4125
	inc hl			;4127
	inc hl			;4128
	inc hl			;4129
	dec (hl)			;412a   ; la cuenta de la nota baja un punto
	cp (hl)			;412b
	jr z,CANAL_MIRA_ESCALON		;412c
	dec (hl)			;412e
CANAL_BAJA_VOLUMEN:		; Un escalon menos de volumen, y a esperar
	dec hl			;412f   ; un escalon menos
	dec (hl)			;4130
	ld a,(hl)			;4131   ; con el volumen a cero ya no hay nada que hacer
	or a			;4132
	ret z			;4133
	ld b,(hl)			;4134
	dec hl			;4135
	call ESCRIBE_VOLUMEN		;4136   ; se escribe en el PSG
	dec hl			;4139
	set 7,(hl)		;413a   ; y se marca que esta nota se apaga sola
	jr CANAL_SIGUE		;413c
CANAL_NOTA_NUEVA:		; Lee del programa la nota que toca
	ld a,(de)			;413e   ; 0xFF termina el programa
	cp 0ffh		;413f
	jr z,CANAL_FIN		;4141
	inc hl			;4143
	ld a,(hl)			;4144
	ld c,0a1h		;4145
	ex de,hl			;4147
	out (0a0h),a		;4148   ; registro 2n del PSG: el periodo fino del canal n
	outi		;414a
	inc a			;414c
	out (0a0h),a		;414d   ; y el 2n+1: los cuatro bits altos del periodo
	ld a,(hl)			;414f
	and 007h		;4150   ; los tres bits bajos son el resto del periodo
	out (c),a		;4152
	bit 3,(hl)		;4154   ; el bit 3 del segundo byte enciende el ruido
	jr z,CANAL_PON_VOLUMEN		;4156
	ld a,007h		;4158
	out (0a0h),a		;415a   ; registro 7: la mezcla. Es EL UNICO byte de estos 163 que dice algo distinto en Time Pilot: alli vale 0x98 y el ruido va al canal C; aqui vale 0xA8 y va al canal B
	ld b,0a8h		;415c
	out (c),b		;415e
	dec a			;4160
	out (0a0h),a		;4161
	ld a,01fh		;4163   ; el 0x1F es el periodo del ruido
	out (c),a		;4165
CANAL_PON_VOLUMEN:
	ex de,hl			;4167   ; el nibble de arriba del segundo byte de la nota
	ld a,(de)			;4168
	and 0f0h		;4169   ; el nibble alto del segundo byte es el volumen de arranque
	rrca			;416b   ; cuatro rotaciones para bajar el nibble alto
	rrca			;416c
	rrca			;416d
	rrca			;416e
	ld b,a			;416f
	call ESCRIBE_VOLUMEN		;4170
	inc de			;4173   ; y el tercero es cuanto dura
	inc hl			;4174
	ld (hl),b			;4175   ; se apunta el volumen de arranque, para ir bajandolo
	dec hl			;4176
	dec hl			;4177
	ld a,(de)			;4178   ; el tercer byte es la duracion de la nota
	ld (hl),a			;4179
	bit 7,a		;417a
	jr z,CANAL_GUARDA_PUNTERO		;417c
	and 07fh		;417e
	inc hl			;4180
	inc hl			;4181
	inc hl			;4182
	add a,003h		;4183   ; la duracion, mas tres, es lo que tarda en apagarse
	ld (hl),a			;4185
	dec hl			;4186
	dec hl			;4187
	dec hl			;4188
CANAL_GUARDA_PUNTERO:
	inc de			;4189   ; la nota ocupaba tres bytes, asi que DE queda ya sobre la siguiente
	dec hl			;418a
	ld (hl),d			;418b   ; el puntero del programa vuelve a la ficha: el byte alto en +1 y el bajo en +0
	dec hl			;418c
	ld (hl),e			;418d
	inc hl			;418e   ; y HL se deja en la ficha+2, que es la que descuenta 0x4190
	inc hl			;418f
CANAL_SIGUE:
	dec (hl)			;4190
	ret			;4191
CANAL_FIN:		; Se acabo el programa: se calla el canal y se enciende el ruido
	inc a			;4192
	dec hl			;4193
	ld (hl),a			;4194   ; y el canal queda callado
	inc hl			;4195
	inc hl			;4196
	ld a,007h		;4197   ; al acabar el programa, la mezcla vuelve a dejar el ruido suelto
	out (0a0h),a		;4199
	ld a,0b8h		;419b
	out (0a1h),a		;419d
	ld b,000h		;419f
ESCRIBE_VOLUMEN:		; Registro 8+canal del PSG = B
	ld a,(hl)			;41a1
	rrca			;41a2   ; el `rrca` pasa de numero de canal a registro de volumen
	add a,008h		;41a3   ; registro 8+n del PSG: el volumen del canal n
	out (0a0h),a		;41a5
	out (c),b		;41a7
	ret			;41a9
CANAL_MIRA_ESCALON:
	ld a,(hl)			;41aa   ; aqui HL viene apuntando a la ficha+5, la cuenta de la nota que se apaga sola
	cp 003h		;41ab   ; con tres pasos o menos por delante se cae en 0x412F y el volumen baja un escalon; por encima, la nota se sostiene
	jr c,CANAL_BAJA_VOLUMEN		;41ad
	dec hl			;41af   ; de la ficha+5 de vuelta a la +2 para que 0x4190 la descuente
	dec hl			;41b0
	dec hl			;41b1
	jr CANAL_SIGUE		;41b2

; ----------------------------------------------------------------------
; INIT. Lo llama la BIOS al arrancar, con el cartucho ya mapeado en la pagina 1. Engancha la interrupcion, borra la RAM, pone la pila, apaga el PSG y carga la pantalla de titulo.
; ----------------------------------------------------------------------
INIT:
	di			;41b4
	ld hl,0fd9ah		;41b5   ; el gancho H.KEYI: `jp 0x4012` escrito a mano, byte a byte
	ld (hl),0c3h		;41b8
	ld hl,INTERRUPCION		;41ba
	ld (0fd9bh),hl		;41bd
	ld hl,0e000h		;41c0   ; borra los 2 KB de RAM del juego de un solo LDIR, y deja la pila en 0xE7FF
	ld de,0e001h		;41c3
	ld bc,007feh		;41c6
	ld (hl),l			;41c9   ; el truco de siempre: se siembra el primer byte y el LDIR lo arrastra
	ldir		;41ca
	ld sp,hl			;41cc
	ld de,081a2h		;41cd   ; registro 1 del VDP = 0xA2 antes de nada, para apagar la pantalla
	call PON_DIRECCION_VDP		;41d0
	ld a,00fh		;41d3
	out (0a0h),a		;41d5
	ld a,0cfh		;41d7   ; registro 15 del PSG: la seleccion del puerto de mando
	out (0a1h),a		;41d9
	ld a,0f0h		;41db
	out (0aah),a		;41dd   ; el nibble alto a unos: no se pulsa ninguna fila del teclado
	im 1		;41df   ; modo 1: la interrupcion salta al 0x38
	ld a,002h		;41e1
	ld (0e02bh),a		;41e3
	add a,a			;41e6
	ld (0e033h),a		;41e7
	ld a,007h		;41ea
	out (0a0h),a		;41ec
	ld a,0b8h		;41ee
	out (0a1h),a		;41f0
	ld b,003h		;41f2   ; los tres volumenes del PSG a cero
	ld c,008h		;41f4
CALLA_EL_PSG:
	ld a,c			;41f6
	out (0a0h),a		;41f7   ; registros 8, 9 y 10 del PSG: los tres volumenes
	xor a			;41f9
	out (0a1h),a		;41fa
	inc c			;41fc
	djnz CALLA_EL_PSG		;41fd   ; y el registro siguiente
ARRANQUE:		; El punto al que se vuelve al acabar una partida
	di			;41ff
	ld hl,0e0a0h		;4200
	ld bc,00300h		;4203   ; 0x300 bytes: las tres tablas de trabajo de 0xE0A0
	call BORRA_BC_BYTES		;4206
	ld de,04000h		;4209   ; borra los 16 KB de VRAM: 64 vueltas de 256 bytes
	call PON_DIRECCION_VDP		;420c
BORRA_LA_VRAM:
	ld b,e			;420f   ; B a cero son 256 bytes
	ld a,e			;4210
	call RELLENA_CON_A		;4211
	dec d			;4214
	jr nz,BORRA_LA_VRAM		;4215
	ld hl,049a3h		;4217   ; los ocho registros del VDP, de 0x49A3
	ld b,008h		;421a   ; ocho registros
	ld d,080h		;421c   ; los registros van del 0x80 al 0x87: el bit 7 dice que es registro y no VRAM
CARGA_LOS_REGISTROS:
	ld e,(hl)			;421e
	call PON_DIRECCION_VDP		;421f
	inc hl			;4222   ; el siguiente valor y el siguiente registro
	inc d			;4223
	djnz CARGA_LOS_REGISTROS		;4224
	ei			;4226
	ld a,001h		;4227   ; espera una unidad de 0xE018
	call ESPERA		;4229   ; la pantalla de titulo se carga con la interrupcion ya en marcha
	di			;422c
	ld b,00ch		;422d   ; doce bloques de caracteres, cada uno con su cabecera
	ld hl,04b36h		;422f
	call SUBE_BLOQUE_CON_CABECERA		;4232

; ----------------------------------------------------------------------
; EL MISMO JUEGO DE LETRAS, DOS VECES. Los doce bloques de 0x4B36 dejan las letras en los caracteres 0xD8 en adelante, y aqui los MISMOS bytes -0x4B39 y 0x4C34, que caen dentro del primer bloque- se suben otra vez a los caracteres 0x98 y 0xB7. No es un descuido: la tabla de color que se carga justo despues da 0x70 -cian- a los caracteres del 0x80 al 0xBF y 0xF0 -blanco- del 0xC0 al 0xFF. En SCREEN 2 el color va por linea de patron y no por casilla, asi que la unica forma de tener las mismas letras en dos colores es tenerlas dos veces. Las del menu salen en cian y las del marcador en blanco.
; ----------------------------------------------------------------------
	ld hl,04b39h		;4235   ; los mismos bytes del bloque anterior, ahora al caracter 0x98
	ld de,064c0h		;4238   ; 256 bytes: el 0 del tamano significa la tanda entera
	ld b,000h		;423b
	call SUBE_B_BYTES		;423d
	ld hl,04c34h		;4240   ; y estos al 0xB7
	ld b,048h		;4243   ; y 72 mas
	ld de,065b8h		;4245
	call SUBE_B_BYTES		;4248
	ld de,04008h		;424b   ; VRAM 0x0008: la tabla de color, desde el caracter 1
	call PON_DIRECCION_VDP		;424e
	ld b,002h		;4251   ; dos tandas de la lista de colores
	ld hl,04dd3h		;4253
	call SUBE_REPETIDOS		;4256
	ld de,Y_LA_FASE_DE_LOS_DOS		;4259
	call PON_DIRECCION_VDP		;425c
	ld b,004h		;425f   ; cuatro tandas mas, siguiendo la misma lista
	call SUBE_REPETIDOS		;4261
	ld de,00000h		;4264
	ld hl,04800h		;4267
	call REPARTE_EN_LOS_TERCIOS		;426a   ; los tres tercios de SCREEN 2 quedan iguales con UNA sola copia
	ld de,02000h		;426d
	ld hl,06800h		;4270
	call REPARTE_EN_LOS_TERCIOS		;4273
	ld a,(0e048h)		;4276   ; con la presentacion ya vista, se va derecho al titulo
	or a			;4279
	jr nz,A_LA_PANTALLA_DE_TITULO		;427a
	ld de,07a8bh		;427c   ; VRAM 0x3A8B: fila 20, columna 11. De ahi arranca la rana de la presentacion
LA_RANA_SUBE:		; La presentacion: una rana que sube la pantalla de 32 en 32
	ld hl,0e019h		;427f
	ld a,(hl)			;4282
	rrca			;4283
	jr nc,MIRA_SI_HAY_TECLA		;4284   ; solo se mueve en los fotogramas impares
	ld a,06bh		;4286   ; al llegar a VRAM 0x386B -fila 3- se para
	cp e			;4288
	jr nz,BORRA_Y_SUBE		;4289
	ld a,078h		;428b
	cp d			;428d
	jr z,MIRA_SI_ACABO		;428e
BORRA_Y_SUBE:
	di			;4290   ; se borra el rastro que dejo la rana al subir
	push de			;4291
	xor a			;4292
	ld (hl),a			;4293
	ld b,003h		;4294
	call RELLENA_FILA_CRECIENTE		;4296   ; tres tandas de 256 bytes de la tabla de nombres
	ld b,00bh		;4299
	call RELLENA_FILA_CRECIENTE		;429b
	ld b,00ch		;429e
	call RELLENA_FILA_CRECIENTE		;42a0
	ld b,00ch		;42a3
	call PON_DIRECCION_VDP		;42a5   ; y la rana en su sitio nuevo
	xor a			;42a8
	call RELLENA_CON_C		;42a9
	ei			;42ac
	or a			;42ad
	pop hl			;42ae
	ld de,00020h		;42af   ; una fila menos: 32 caracteres hacia arriba
	sbc hl,de		;42b2
	ex de,hl			;42b4
MIRA_SI_ACABO:
	ld hl,0e019h		;42b5
	ld a,071h		;42b8   ; al cabo de 0x71 fotogramas se deja de esperar
	cp (hl)			;42ba
	jr z,A_LA_PANTALLA_DE_TITULO		;42bb
MIRA_SI_HAY_TECLA:
	xor a			;42bd
	di			;42be
	call LEE_UNA_FILA		;42bf   ; fila 0 del teclado: cualquiera de las teclas 1 a 4 corta la presentacion
	ei			;42c2
	and 01eh		;42c3   ; cuatro bits: las teclas 1 a 4
	cp 01eh		;42c5
	jr z,LA_RANA_SUBE		;42c7
A_LA_PANTALLA_DE_TITULO:
	di			;42c9
	call PINTA_LA_PANTALLA_DE_TITULO		;42ca
	ld a,008h		;42cd
	ld (0e018h),a		;42cf   ; ocho puntos de espera con el titulo puesto
	ei			;42d2

; ----------------------------------------------------------------------
; LA PANTALLA DE TITULO. Deja correr la demo y espera a que se pulse una de las cuatro teclas. La 1 y la 2 juegan con joystick, la 3 y la 4 con el teclado; la 1 y la 3 son un jugador y la 2 y la 4 son dos. Cada una tiene su propia lista de rotulos, que es lo que se ve resaltado en la pantalla.
; ----------------------------------------------------------------------
PANTALLA_DE_TITULO:
	ld hl,0e014h		;42d3
	ld (hl),001h		;42d6   ; 0xE014 a uno: la demo en marcha
	ld a,(0e018h)		;42d8   ; mientras quede espera, corre la demo
	or a			;42db
	jp z,MONTA_LA_PARTIDA		;42dc
	xor a			;42df
	ld (0e021h),a		;42e0   ; los tres canales, callados
	ld (0e029h),a		;42e3
	ld (0e031h),a		;42e6
	ld (hl),a			;42e9
	ld a,001h		;42ea
	ld (0e007h),a		;42ec   ; de fabrica se juega con joystick; las teclas 3 y 4 lo cambian
	ld a,(0e048h)		;42ef
	or a			;42f2
	jr nz,MIRA_QUE_TECLA		;42f3
	xor a			;42f5
	di			;42f6
	call LEE_UNA_FILA		;42f7   ; fila 0 del teclado: las teclas 0 a 7
	ei			;42fa
MIRA_QUE_TECLA:
	rrca			;42fb   ; el bit 0 -la tecla 0- no se usa; se descarta de entrada
	ld hl,04a42h		;42fc
	rrca			;42ff   ; tecla 1: un jugador, joystick
	jr nc,UN_JUGADOR		;4300
	ld hl,04a60h		;4302
	rrca			;4305   ; tecla 2: dos jugadores, joystick
	jr nc,DOS_JUGADORES		;4306
	ex af,af'			;4308
	xor a			;4309
	ld (0e007h),a		;430a   ; teclas 3 y 4: se juega con el teclado
	ex af,af'			;430d
	ld hl,04a7eh		;430e
	rrca			;4311   ; tecla 3: un jugador, teclado
	jr nc,UN_JUGADOR		;4312
	ld hl,04a9ch		;4314
	rrca			;4317   ; tecla 4: dos jugadores, teclado
	jr nc,DOS_JUGADORES		;4318
	jr PANTALLA_DE_TITULO		;431a   ; sin tecla, se vuelve a dejar correr la demo
UN_JUGADOR:
	xor a			;431c   ; con un jugador, 0xE000 a cero
	jr ARRANCA_LA_PARTIDA		;431d
DOS_JUGADORES:
	ld a,001h		;431f
ARRANCA_LA_PARTIDA:
	ld (0e000h),a		;4321   ; y con dos, a uno
	xor a			;4324
	ld (0e019h),a		;4325   ; la cuenta de fotogramas vuelve a cero
PARPADEA_LA_ELECCION:
	ei			;4328
	ld a,(0e019h)		;4329
	bit 3,a		;432c   ; el bit 3 de la cuenta de fotogramas: se enciende y se apaga cada 8
	di			;432e
	jr z,MIRA_SI_EMPIEZA		;432f
	push hl			;4331   ; los dos bytes de destino de la lista
	ld d,(hl)			;4332
	inc hl			;4333
	ld e,(hl)			;4334
	inc hl			;4335
	ld b,01ah		;4336   ; 26 caracteres, todos a cero: la linea se apaga
	ld c,000h		;4338
	call RELLENA_CON_C		;433a
	pop hl			;433d
	jr PARPADEA_LA_ELECCION		;433e
MIRA_SI_EMPIEZA:
	push hl			;4340
	call PINTA_ROTULOS		;4341   ; y al otro medio segundo se vuelve a pintar
	ld hl,0e019h		;4344
	bit 6,(hl)		;4347   ; el bit 6 de la cuenta: unos dos segundos de margen
	pop hl			;4349
	jr z,PARPADEA_LA_ELECCION		;434a
	ei			;434c

; ----------------------------------------------------------------------
; MONTAR LA PARTIDA. Carga los caracteres y los sprites, genera las cuatro versiones desplazadas de cada dibujo, pone tres vidas y suelta la musica de arranque.
; ----------------------------------------------------------------------
MONTA_LA_PARTIDA:
	ld hl,00101h		;434d   ; el primer escalon de vida extra: 1 = 10000 puntos, para los dos jugadores
	ld (0e005h),hl		;4350
	ld hl,00000h		;4353   ; el marcador que se dibuja solo empieza sin nada pendiente
	ld (0e039h),hl		;4356
	di			;4359
	call BORRA_LA_PANTALLA		;435a   ; la pantalla entera a cero antes de cargar nada
	ld hl,0585eh		;435d   ; los caracteres de la partida
	ld b,001h		;4360   ; un solo bloque con cabecera
	call SUBE_BLOQUE_CON_CABECERA		;4362
	ld de,06080h		;4365   ; VRAM 0x2080: los patrones, a partir del caracter 0x10
	call PON_DIRECCION_VDP		;4368
	ld b,00ah		;436b   ; diez juegos de patrones, cada uno con sus cuatro versiones desplazadas
	ld hl,058d1h		;436d
	call SUBE_Y_ROTA		;4370
	ld hl,0e042h		;4373   ; bit 0 de 0xE042: el rotador tiene que mezclar dos capas
	set 0,(hl)		;4376
	ld hl,059bbh		;4378   ; VRAM 0x24F0, el caracter 0x9E
	ld de,064f0h		;437b   ; dos juegos mas
	call PON_DIRECCION_VDP		;437e
	ld b,002h		;4381   ; estos dos van mezclando dos capas, por el bit 0 de 0xE042
	call SUBE_Y_ROTA		;4383
	ld de,065f0h		;4386   ; y los otros dos en el 0xBE
	call PON_DIRECCION_VDP		;4389
	ld b,002h		;438c   ; dos juegos mas
	call SUBE_Y_ROTA		;438e
	ld b,014h		;4391   ; los veinte bloques de patrones de sprite
	ld hl,059ffh		;4393
	call SUBE_BLOQUE_CON_CABECERA		;4396
	ld de,059c0h		;4399   ; VRAM 0x19C0: 32 bytes a 0xFF, un sprite macizo
	ld c,0ffh		;439c
	ld b,020h		;439e
	call RELLENA_CON_C		;43a0
	ld de,04000h		;43a3   ; y ahora la tabla de color, desde el caracter 0
	call PON_DIRECCION_VDP		;43a6
	ld hl,05c34h		;43a9
	ld b,009h		;43ac   ; nueve tandas de color
	call SUBE_REPETIDOS		;43ae
	ld de,04080h		;43b1   ; desde el 0x10
	call PON_DIRECCION_VDP		;43b4
	ld hl,05c46h		;43b7
	ld b,006h		;43ba   ; seis tandas mas, esta vez del reves
	call SUBE_DEL_REVES		;43bc
	ld de,BORRA_Y_REARRANCA		;43bf   ; y el color de los caracteres del 0xBE
	call PON_DIRECCION_VDP		;43c2
	ld hl,05c7ch		;43c5
	ld b,001h		;43c8
	call SUBE_DEL_REVES		;43ca
	ld de,00000h		;43cd
	ld hl,04800h		;43d0
	call REPARTE_EN_LOS_TERCIOS		;43d3   ; otra vez la copia solapada, ahora con los dibujos de la partida
	ld de,02000h		;43d6   ; lo mismo con los patrones
	ld hl,06800h		;43d9
	call REPARTE_EN_LOS_TERCIOS		;43dc
	call MONTA_LOS_COCHES		;43df   ; las listas de los coches
	call MONTA_EL_RIO		;43e2   ; y las del rio
	ld a,(0e014h)		;43e5   ; en la demo no se ponen vidas
	or a			;43e8
	jr nz,PON_LAS_VIDAS		;43e9
	ld a,003h		;43eb   ; tres vidas
PON_LAS_VIDAS:
	ld hl,0e002h		;43ed
	ld (hl),a			;43f0
	inc hl			;43f1
	ld (hl),a			;43f2
	ld a,001h		;43f3   ; las dos partidas empiezan en la fase 1
	ld hl,0e082h		;43f5
	ld (hl),a			;43f8
	inc hl			;43f9
	inc hl			;43fa
	ld (hl),a			;43fb   ; la del jugador 2
	ld hl,0e08ah		;43fc
	ld (hl),a			;43ff
Y_LA_FASE_DE_LOS_DOS:
	inc hl			;4400
	inc hl			;4401
	ld (hl),a			;4402
	ld hl,04b02h		;4403   ; los rotulos fijos del marcador
	call PINTA_ROTULOS		;4406
	ld hl,04abah		;4409   ; y el aviso de que juega el primero
	call PINTA_ROTULOS		;440c
	ld de,07859h		;440f   ; el record, que sobrevive a la partida anterior
	ld hl,0e011h		;4412
	call PINTA_SEIS_CIFRAS		;4415   ; seis cifras: tres bytes en BCD
	ld hl,0e040h		;4418   ; 0xE040 bit 4: lo primero es montar la fase
	ld (hl),010h		;441b
	ld a,(0e014h)		;441d
	or a			;4420
	jr nz,EMPIEZA_LA_VIDA		;4421
	ld hl,0e043h		;4423
	set 0,(hl)		;4426   ; el bit 0 puesto: solo suena la musica
	ld hl,05d97h		;4428   ; las tres partituras de la musica de arranque, una por canal
	ld (0e020h),hl		;442b
	ld hl,05de9h		;442e
	ld (0e028h),hl		;4431
	ld hl,05e41h		;4434
	ld (0e030h),hl		;4437
	ei			;443a
	ld a,00ch		;443b   ; doce unidades de espera: lo que dura la musica
	call ESPERA		;443d
	ld hl,0e043h		;4440
	ld (hl),000h		;4443   ; y el reparto vuelve a la normalidad
EMPIEZA_LA_VIDA:
	ld a,(0e014h)		;4445   ; en la demo no hay mando que elegir, asi que 0x4451 se salta entero
	or a			;4448
	jr z,ELIGE_EL_MANDO		;4449
	xor a			;444b
	ld (0e000h),a		;444c   ; y la demo se juega siempre como si fuera un jugador, valga lo que valga 0xE000
	jr LA_VIDA		;444f
ELIGE_EL_MANDO:
	di			;4451
	call QUE_JUGADOR_ES		;4452
	ld a,00fh		;4455   ; registro 15 del PSG: 0x8F para el mando del jugador 1 y 0xCF para el del 2
	out (0a0h),a		;4457
	ld a,08fh		;4459
	jr z,PON_EL_MANDO		;445b
	ld a,0cfh		;445d
PON_EL_MANDO:
	out (0a1h),a		;445f
	ei			;4461
LA_VIDA:
	ld a,001h		;4462   ; a partir de aqui la interrupcion ya mueve cosas
	ld (0e015h),a		;4464   ; 0xE015 a uno: hay partida en marcha
	ld a,(0e000h)		;4467   ; con un solo jugador se borran los rotulos del segundo
	or a			;446a
	jr nz,MIRA_LAS_VIDAS		;446b
	ld de,07919h		;446d   ; en un jugador se borran los rotulos del segundo
	di			;4470
	ld b,002h		;4471   ; dos casillas: el rotulo de 2UP
	ld c,000h		;4473
	call RELLENA_CON_C		;4475
	ld de,07939h		;4478
	ld b,006h		;447b   ; seis casillas mas: su marcador
	call RELLENA_CON_C		;447d
MIRA_LAS_VIDAS:
	call FICHA_DE_VIDAS		;4480   ; las vidas que quedan, dibujadas una a una en el lateral
	ld de,079f9h		;4483   ; las vidas que quedan, dibujadas de una en una
	di			;4486
	ld b,007h		;4487   ; siete casillas: el hueco entero de las vidas
	ld c,000h		;4489   ; primero se borran las siete casillas
	call RELLENA_CON_C		;448b
	ei			;448e
	ld a,(hl)			;448f
	dec a			;4490
	jr z,RECORD_Y_VIDA_EXTRA		;4491
	cp 008h		;4493   ; no se dibujan mas de siete vidas aunque haya mas
	jr c,PINTA_LAS_VIDAS		;4495
	ld a,007h		;4497
PINTA_LAS_VIDAS:
	ld b,a			;4499
	ld de,079f9h		;449a   ; y luego se pintan las que hay
	di			;449d
	ld c,009h		;449e   ; el caracter 9 es la rana del lateral
	call RELLENA_CON_C		;44a0
	ei			;44a3

; ----------------------------------------------------------------------
; EL RECORD Y LA VIDA EXTRA. Compara los puntos del jugador con el record y, si lo pasa, lo copia. Despues mira si toca vida extra: el escalon esta en 0xE005 y se compara con el byte ALTO de los puntos, o sea con las decenas de millar. Arranca en 1 -10000 puntos- y sube de 5 en 5, asi que la segunda vida extra llega a los 60000 y luego cada 50000.
; ----------------------------------------------------------------------
RECORD_Y_VIDA_EXTRA:
	ld hl,0e00dh		;44a4
	call QUE_JUGADOR_ES		;44a7   ; los puntos del jugador que juega
	jr z,RESTA_LOS_TRES_BYTES		;44aa
	ld l,010h		;44ac
RESTA_LOS_TRES_BYTES:
	ld de,0e013h		;44ae   ; tres bytes, del mas bajo al mas alto
	ld b,003h		;44b1   ; tres bytes: las seis cifras
	or a			;44b3
COMPARA_CON_EL_RECORD:
	ld a,(de)			;44b4   ; resta de tres bytes, del mas bajo al mas alto
	sbc a,(hl)			;44b5
	dec hl			;44b6
	dec de			;44b7
	djnz COMPARA_CON_EL_RECORD		;44b8
	jr nc,PINTA_EL_RECORD		;44ba   ; sin acarreo el jugador ha pasado el record
	inc hl			;44bc   ; y si lo paso, los puntos pasan a ser el record
	inc de			;44bd
	ld bc,00003h		;44be   ; tres bytes: los puntos pasan a ser el record
	ldir		;44c1
PINTA_EL_RECORD:
	ld hl,0e011h		;44c3
	ld de,07859h		;44c6   ; VRAM 0x3859: fila 2, columna 25
	di			;44c9
	call PINTA_SEIS_CIFRAS		;44ca
	ei			;44cd
	ld hl,0e014h		;44ce
	ld a,(hl)			;44d1
	or a			;44d2
	jr nz,LA_DEMO_ESPERA_TECLA		;44d3
PINTA_LOS_PUNTOS:
	ld hl,0e00bh		;44d5
	ld de,078d9h		;44d8   ; VRAM 0x38D9 -fila 6- el jugador 1, y 0x3939 -fila 9- el jugador 2
	call QUE_JUGADOR_ES		;44db
	jr z,MIRA_LA_VIDA_EXTRA		;44de
	ld l,00eh		;44e0   ; el jugador 2 tiene sus puntos catorce bytes mas alla
	ld de,07939h		;44e2
MIRA_LA_VIDA_EXTRA:
	di			;44e5   ; el escalon del jugador que juega
	call PINTA_SEIS_CIFRAS		;44e6
	ei			;44e9
	ld de,0e00bh		;44ea
	ld hl,0e005h		;44ed
	call QUE_JUGADOR_ES		;44f0   ; el del segundo esta catorce bytes mas alla
	jr z,COMPARA_CON_EL_ESCALON		;44f3
	inc hl			;44f5
	ld e,00eh		;44f6
COMPARA_CON_EL_ESCALON:
	ld a,(de)			;44f8   ; el escalon se compara con el byte alto: las decenas de millar
	cp (hl)			;44f9
	jr nz,MIRA_SI_SE_ACABO_LA_VIDA		;44fa
	ex de,hl			;44fc
	ld hl,0e039h		;44fd
	call FICHA_DEL_JUGADOR		;4500   ; el escalon del que juega
	ld a,005h		;4503   ; el escalon sube 5, o sea 50000 puntos mas
	add a,(hl)			;4505
	daa			;4506
	ld (hl),a			;4507
	ld (de),a			;4508
	call FICHA_DE_VIDAS		;4509   ; una vida mas
	inc (hl)			;450c
	ld hl,05ed4h		;450d   ; y el sonido de la vida extra
	call PIDE_SONIDO		;4510
	jp MIRA_LAS_VIDAS		;4513
LA_DEMO_ESPERA_TECLA:
	di			;4516   ; en la demo, cualquier tecla la corta
	xor a			;4517
	call LEE_UNA_FILA		;4518
	ei			;451b
	and 01eh		;451c   ; cuatro bits: las teclas 1 a 4
	cp 01eh		;451e
	jr z,MIRA_SI_SE_ACABO_LA_VIDA		;4520
	ld (hl),000h		;4522   ; y se borran los puntos de los dos jugadores
	inc hl			;4524
	ld (hl),000h		;4525
	jp VUELTA_AL_TITULO		;4527
MIRA_SI_SE_ACABO_LA_VIDA:
	ld a,(0e004h)		;452a   ; mientras quede vida, se sigue
	or a			;452d
	jp z,RECORD_Y_VIDA_EXTRA		;452e
	di			;4531
	ld de,078b9h		;4532   ; borra el 1UP o el 2UP que parpadea
	ld hl,04b09h		;4535
	ld b,002h		;4538   ; dos casillas: el rotulo entero
	call SUBE_B_BYTES		;453a
	call QUE_JUGADOR_ES		;453d
	jr z,UNA_VIDA_MENOS		;4540
	ld de,07919h		;4542
	ld hl,04b14h		;4545
	ld b,002h		;4548
	call SUBE_B_BYTES		;454a
UNA_VIDA_MENOS:
	xor a			;454d
	ld (0e004h),a		;454e   ; 0xE004 y 0xE015 a cero: se acabo la vida
	ld (0e015h),a		;4551
	ei			;4554
	call FICHA_DE_VIDAS		;4555   ; una vida menos
	dec (hl)			;4558   ; sin vidas, se acabo
	jp z,FIN_DE_PARTIDA		;4559
	ld a,(0e000h)		;455c   ; con un solo jugador se sigue en la misma partida
	or a			;455f
	jp z,EMPIEZA_LA_VIDA		;4560
	call PASA_AL_OTRO_JUGADOR		;4563   ; en dos jugadores le toca al otro, si le quedan vidas
	jr c,CAMBIO_DE_JUGADOR		;4566
	ld a,b			;4568
	ld (0e001h),a		;4569
CAMBIO_DE_JUGADOR:
	di			;456c   ; la interrupcion se corta mientras se borra el area de juego
	call BORRA_EL_AREA_DE_JUEGO		;456d
	ei			;4570
	ld hl,04abah		;4571   ; 0x4ABA avisa de que juega el primero y 0x4AD2 de que juega el segundo
	call QUE_JUGADOR_ES		;4574   ; 0xE001 ya lo cambio 0x4563: el aviso es del que entra, no del que acaba de perder la vida
	jr z,AVISA_DE_QUIEN_JUEGA		;4577
	ld hl,04ad2h		;4579
AVISA_DE_QUIEN_JUEGA:
	call PINTA_ROTULOS		;457c
	ld a,004h		;457f
	call ESPERA		;4581   ; cuatro puntos de espera con el aviso puesto
	jp EMPIEZA_LA_VIDA		;4584

; ----------------------------------------------------------------------
; SE ACABO LA PARTIDA. Suelta la musica del final por dos canales y espera a que el canal 2 se calle sola, sin contar fotogramas.
; ----------------------------------------------------------------------
FIN_DE_PARTIDA:
	call CALLA_EL_SONIDO		;4587
	ld a,(0e014h)		;458a
	or a			;458d
	jr nz,BORRA_LOS_MARCADORES		;458e
	call CALLA_EL_SONIDO		;4590
	ld hl,05fb6h		;4593   ; las dos partituras del final
	ld (0e020h),hl		;4596
	ld hl,05fd8h		;4599
	ld (0e028h),hl		;459c
	ld hl,0e043h		;459f   ; 0xE043 = 0x40: en los fotogramas siguientes la interrupcion solo hace sonar
	ld (hl),040h		;45a2
	call QUE_JUGADOR_ES		;45a4
	ld hl,04abah		;45a7
	jr z,ROTULOS_DEL_FINAL		;45aa
	ld hl,04ad2h		;45ac
ROTULOS_DEL_FINAL:
	di			;45af
	call PINTA_ROTULOS		;45b0
	ld hl,04aeah		;45b3
	call PINTA_ROTULOS		;45b6
	ei			;45b9
ESPERA_A_QUE_ACABE:
	ld a,(0e029h)		;45ba   ; se espera a que el propio canal 2 se apague
	or a			;45bd
	jr nz,ESPERA_A_QUE_ACABE		;45be
	ld hl,0e043h		;45c0
	ld (hl),000h		;45c3   ; y el reparto vuelve a la normalidad
	ld a,(0e000h)		;45c5
	or a			;45c8
	jr z,BORRA_LOS_MARCADORES		;45c9
	call PASA_AL_OTRO_JUGADOR		;45cb
	jr c,CAMBIO_DE_JUGADOR		;45ce
BORRA_LOS_MARCADORES:
	xor a			;45d0
	ld b,006h		;45d1   ; seis bytes: los dos marcadores
	ld hl,0e00bh		;45d3
BORRA_SEIS_BYTES:
	ld (hl),a			;45d6   ; los seis bytes de puntos de los dos jugadores
	inc hl			;45d7
	djnz BORRA_SEIS_BYTES		;45d8
	ld (0e001h),a		;45da
VUELTA_AL_TITULO:
	ld bc,00060h		;45dd   ; borra de 0xE040 a 0xE0A0 -97 bytes, que BORRA_BC_BYTES borra BC+1-: fase, casas y puntos de los dos jugadores
	ld hl,0e040h		;45e0
	call BORRA_BC_BYTES		;45e3
	ld (0e048h),a		;45e6
	call CALLA_EL_SONIDO		;45e9
	ld hl,0e042h		;45ec
	xor a			;45ef
BORRA_Y_REARRANCA:
	ld (hl),a			;45f0
	di			;45f1   ; y se vuelve al arranque, sin pasar por INIT
	jp ARRANQUE		;45f2
LEE_EL_JOYSTICK:		; Registro 14 del PSG
	ld a,00eh		;45f5   ; registro 14 del PSG: el puerto del joystick
	out (0a0h),a		;45f7
	nop			;45f9   ; el `nop` es la espera que pide el PSG antes de leer
	in a,(0a2h)		;45fa
	ret			;45fc
LEE_UNA_FILA:		; Fila A del teclado -> A = sus ocho teclas, a cero las pulsadas
	or 0f0h		;45fd
	out (0aah),a		;45ff   ; el puerto C del PPI se escribe dos veces para dar tiempo a la matriz
	out (0aah),a		;4601
	in a,(0a9h)		;4603
	ret			;4605
LOS_CURSORES_COMO_JOYSTICK:
	ld a,008h		;4606   ; fila 8 del teclado: los cuatro cursores y el espacio
	call LEE_UNA_FILA		;4608
	cpl			;460b   ; el teclado da las teclas a cero: se invierten
	ld c,a			;460c
	rrca			;460d   ; cuatro rotaciones: los cursores estan en el nibble alto
	rrca			;460e
	rrca			;460f
	rrca			;4610
	and 00fh		;4611
	ld hl,049b7h		;4613   ; los cuatro cursores no salen en el mismo orden que el joystick: se traducen por la tabla de 0x49B7
	call HL_MAS_A		;4616
	ld a,(hl)			;4619
	cpl			;461a
	ret			;461b
PINTA_LA_PANTALLA_DE_TITULO:		; Las cinco listas de rotulos de 0x4A04
	call BORRA_LA_PANTALLA		;461c
	ld hl,04a04h		;461f
	ld b,005h		;4622   ; cinco listas de rotulos
CINCO_LISTAS:
	push bc			;4624
	call PINTA_ROTULOS		;4625
	pop bc			;4628
	djnz CINCO_LISTAS		;4629
	ret			;462b

; ----------------------------------------------------------------------
; EL INTERPRETE DE ROTULOS. Una lista empieza con la direccion de VRAM en dos bytes, el ALTO delante, y sigue con los caracteres tal cual. El 0x1F es "repetir": detras van cuantos y cual. El 0x0F cierra el trozo y detras viene la direccion del siguiente; dos 0x0F seguidos cierran la lista.
; ----------------------------------------------------------------------
PINTA_ROTULOS:
	ld d,(hl)			;462c   ; la direccion de VRAM, con el byte ALTO delante
	inc hl			;462d
	ld e,(hl)			;462e
	call PON_DIRECCION_VDP		;462f
SIGUIENTE_CARACTER:
	inc hl			;4632   ; caracter a caracter
	ld a,(hl)			;4633
	cp 01fh		;4634   ; 0x1F: detras van cuantas veces y que caracter
	jr nz,MIRA_SI_ACABA		;4636
	inc hl			;4638   ; detras del 0x1F van cuantos y cual
	ld b,(hl)			;4639
	inc hl			;463a
	ld a,(hl)			;463b
	call RELLENA_CON_A		;463c
	inc hl			;463f
	ld a,(hl)			;4640
MIRA_SI_ACABA:
	cp 00fh		;4641   ; 0x0F cierra el trozo
	jr z,MIRA_SI_HAY_MAS		;4643
	out (098h),a		;4645
	jr SIGUIENTE_CARACTER		;4647
MIRA_SI_HAY_MAS:
	inc hl			;4649
	ld a,(hl)			;464a
	cp 00fh		;464b   ; un segundo 0x0F seguido cierra la lista entera
	jr nz,PINTA_ROTULOS		;464d
	inc hl			;464f
	ret			;4650

; ----------------------------------------------------------------------
; PINTA TRES BYTES BCD. Seis cifras, de dos en dos por byte, empezando por el mas alto. Los patrones de las cifras estan en los codigos 0xE0 a 0xE9, asi que basta con sumar 0xE0 al digito.
; ----------------------------------------------------------------------
PINTA_SEIS_CIFRAS:
	call PON_DIRECCION_VDP		;4651
	ld b,003h		;4654   ; tres bytes: seis cifras
CIFRA_A_CIFRA:
	ld a,(hl)			;4656   ; dos cifras por byte, la de arriba primero
	ld e,(hl)			;4657
	ld d,0e0h		;4658   ; los patrones de las cifras empiezan en el codigo 0xE0
	and 0f0h		;465a   ; el nibble de arriba
	rrca			;465c   ; cuatro rotaciones para bajar el nibble alto
	rrca			;465d
	rrca			;465e
	rrca			;465f
	add a,d			;4660
	out (098h),a		;4661
	ld a,e			;4663
	and 00fh		;4664   ; y el de abajo
	add a,d			;4666
	out (098h),a		;4667
	inc hl			;4669
	djnz CIFRA_A_CIFRA		;466a   ; tres bytes, dos cifras cada uno
	ret			;466c
PASA_AL_OTRO_JUGADOR:		; Devuelve acarreo si al otro no le quedan vidas
	ld hl,0e001h		;466d   ; el jugador que juega, 0 o 1
	ld a,(hl)			;4670
	ld b,(hl)			;4671   ; se apunta cual era antes de cambiarlo
	inc a			;4672
	and 001h		;4673
	ld (hl),a			;4675
	inc hl			;4676
	call HL_MAS_A		;4677   ; y se mira si al otro le quedan vidas
	ld a,(hl)			;467a
	or a			;467b
	ret z			;467c
	scf			;467d   ; y con carry, el que entra puede jugar
	ret			;467e

; ----------------------------------------------------------------------
; EL 1UP QUE PARPADEA. Cada 64 fotogramas enciende o apaga el rotulo del jugador que juega.
; ----------------------------------------------------------------------
PARPADEO_DEL_JUGADOR:
	ld hl,0e016h		;467f
	dec (hl)			;4682   ; mientras no llegue a cero, no toca
	ret nz			;4683
	ld (hl),040h		;4684   ; 64 fotogramas por parpadeo
	inc hl			;4686
	ld de,04b09h		;4687
	call QUE_JUGADOR_ES		;468a
	jr z,ENCIENDE_O_APAGA		;468d
	ld de,04b14h		;468f
ENCIENDE_O_APAGA:
	ld a,(hl)			;4692   ; 0xE017 alterna entre 0 y 1 en cada parpadeo: es el estado del rotulo
	or a			;4693
	jr nz,APAGALO		;4694
	inc (hl)			;4696
	ld de,04adah		;4697   ; tocaba borrarlo, asi que se cogen los dos ceros de 0x4ADA en vez del 1UP
	jr ELIGE_LA_FILA		;469a
APAGALO:
	dec (hl)			;469c
ELIGE_LA_FILA:
	ex de,hl			;469d
	ld de,078b9h		;469e   ; VRAM 0x38B9 el jugador 1 y 0x3919 el jugador 2
	call QUE_JUGADOR_ES		;46a1
	jr z,DOS_CARACTERES		;46a4
	ld de,07919h		;46a6
DOS_CARACTERES:
	ld b,002h		;46a9   ; dos casillas: el rotulo entero
	jp SUBE_B_BYTES		;46ab

; ----------------------------------------------------------------------
; SUMAR PUNTOS. BC lleva lo que se suma, en BCD, y va a los tres bytes del jugador que juega. En la demo no se suma nada.
; ----------------------------------------------------------------------
SUMA_PUNTOS:
	ld a,(0e014h)		;46ae   ; la demo no puntua
	or a			;46b1
	ret nz			;46b2
	ld hl,0e00dh		;46b3
	call QUE_JUGADOR_ES		;46b6
	jr z,SUMA_BCD		;46b9
	ld l,010h		;46bb
SUMA_BCD:
	ld a,(hl)			;46bd   ; las unidades y las decenas
	add a,c			;46be
	daa			;46bf
	ld (hl),a			;46c0
	dec hl			;46c1   ; los millares y las centenas
	ld a,(hl)			;46c2
	adc a,b			;46c3
	daa			;46c4
	ld (hl),a			;46c5
	ret nc			;46c6   ; sin acarreo ya esta
	dec hl			;46c7
	ld a,(hl)			;46c8   ; y si lo hay, sube el byte de arriba
	add a,001h		;46c9
	daa			;46cb
	ld (hl),a			;46cc
	ret			;46cd
BORRA_LA_PANTALLA:		; Los 768 caracteres de la tabla de nombres
	ld de,07800h		;46ce
	call PON_DIRECCION_VDP		;46d1
	ld h,003h		;46d4   ; la tabla de nombres son tres tandas de 256
	xor a			;46d6
UN_TERCIO:
	ld b,a			;46d7   ; B a cero son 256 casillas
	call RELLENA_CON_A		;46d8
	dec h			;46db
	jr nz,UN_TERCIO		;46dc
	ret			;46de
BORRA_EL_AREA_DE_JUEGO:		; Solo 24 columnas de cada fila: el marcador del lateral se queda
	ld de,07800h		;46df
	ld h,018h		;46e2   ; 24 filas
FILA_A_FILA:
	ld b,018h		;46e4   ; 24 columnas por fila, y 24 filas
	ld c,000h		;46e6
	call RELLENA_CON_C		;46e8
	ex de,hl			;46eb
	ld a,020h		;46ec   ; de una fila a la siguiente van 32 caracteres
	call HL_MAS_A		;46ee
	ex de,hl			;46f1
	dec h			;46f2
	jr nz,FILA_A_FILA		;46f3
	ret			;46f5

; ----------------------------------------------------------------------
; EL CHOQUE. Compara la caja de la rana -en DE- con la del objeto -en BC- usando los cuatro margenes que la tabla de 0x49C7 guarda para cada tipo. Devuelve acarreo si se tocan.
; ----------------------------------------------------------------------
HAY_CHOQUE:
	ld hl,049c7h		;46f6
	rlca			;46f9   ; cuatro margenes por tipo, asi que el indice se multiplica por cuatro
	rlca			;46fa
	call HL_MAS_A		;46fb
	ld a,d			;46fe   ; primero la vertical
	sub b			;46ff
	jr nc,POR_ARRIBA		;4700
	cp (hl)			;4702
	jr c,NO_HAY_CHOQUE		;4703
	inc hl			;4705
	jr LA_HORIZONTAL		;4706
POR_ARRIBA:
	inc hl			;4708
	cp (hl)			;4709
	jr nc,NO_HAY_CHOQUE		;470a
LA_HORIZONTAL:
	ld a,e			;470c   ; y despues la horizontal
	sub c			;470d
	inc hl			;470e
	cp (hl)			;470f
	jr c,NO_HAY_CHOQUE		;4710
	inc hl			;4712
	cp (hl)			;4713
	jr nc,NO_HAY_CHOQUE		;4714
	scf			;4716   ; dentro de los cuatro margenes: chocan
	ret			;4717
NO_HAY_CHOQUE:
	or a			;4718   ; y si no, carry a cero
	ret			;4719

; ----------------------------------------------------------------------
; LOS TRES TERCIOS DE UNA COPIA. SCREEN 2 tiene los patrones y los colores partidos en tres tercios de 2 KB, y el juego los quiere iguales. En vez de tres copias hace UNA de 4095 bytes con el destino 2 KB por delante del origen: al pasar del primer tercio ya esta leyendo lo que acaba de escribir, asi que el segundo se propaga solo al tercero.
; ----------------------------------------------------------------------
REPARTE_EN_LOS_TERCIOS:
	ld bc,00fffh		;471a   ; 4095 bytes: los dos tercios que faltan, de una vez
BYTE_A_BYTE:
	call PON_DIRECCION_VDP		;471d   ; leer de la VRAM pide su propia direccion, y escribir otra
	inc de			;4720   ; se lee de una direccion y se escribe en otra, byte a byte
	in a,(098h)		;4721
	ex de,hl			;4723
	push af			;4724   ; el byte leido no cabe en ningun registro libre
	call PON_DIRECCION_VDP		;4725
	inc de			;4728
	pop af			;4729
	out (098h),a		;472a
	ex de,hl			;472c
	dec bc			;472d   ; 4095 vueltas
	ld a,b			;472e
	or c			;472f
	jr nz,BYTE_A_BYTE		;4730
	ret			;4732
ESPERA:		; Deja pasar A unidades de 0xE018, o sea 32 fotogramas cada una
	ld hl,0e018h		;4733
	ld (hl),a			;4736
ESPERANDO:
	ld a,(hl)			;4737
	or a			;4738
	jr nz,ESPERANDO		;4739
	ret			;473b

; ----------------------------------------------------------------------
; EL ROTADOR DE PATRONES. Los troncos, las tortugas y los coches se mueven de dos en dos pixeles sin usar sprites: lo que se guarda en la VRAM son CUATRO versiones de cada dibujo, desplazadas 0, 2, 4 y 6 pixeles. Esta rutina sube la version sin desplazar y luego genera las otras tres corriendo el juego entero de patrones dos bits cada vez, arrastrando los bits de un caracter al de al lado.
; ----------------------------------------------------------------------
SUBE_Y_ROTA:
	push bc			;473c
	call COPIA_HASTA_EL_0x11		;473d   ; copia el juego de patrones a 0xE308 y lo sube tal cual: esa es la version sin desplazar
	push hl			;4740
	ld hl,0e308h		;4741   ; y de ahi salen las otras tres
	call SUBE_HASTA_EL_0x11		;4744
	call LAS_TRES_VERSIONES_MAS		;4747
	pop hl			;474a
	pop bc			;474b
	djnz SUBE_Y_ROTA		;474c   ; tantos juegos como diga B
	ret			;474e
COPIA_HASTA_EL_0x11:		; El 0x11 cierra el grupo de patrones
	ld de,0e308h		;474f
GRUPO_A_GRUPO:
	ld bc,00008h		;4752   ; los patrones van de ocho en ocho, sin cabecera
	ldir		;4755
	ld a,(hl)			;4757   ; el 0x11 cierra el juego; no es un patron, es la marca
	cp 011h		;4758
	jr nz,GRUPO_A_GRUPO		;475a
	ld (de),a			;475c
	inc hl			;475d
	ret			;475e
LAS_TRES_VERSIONES_MAS:
	ld b,003h		;475f   ; tres pasadas mas: 2, 4 y 6 pixeles
UNA_DE_LAS_TRES:
	push bc			;4761   ; tres pasadas, y cada una deja el dibujo dos pixeles mas a la derecha
	ld hl,0e300h		;4762   ; 0xE300 esta ocho bytes por debajo de 0xE308: ahi cae el caracter de la izquierda
UN_PASE_ENTERO:
	ld b,008h		;4765   ; un caracter por vuelta, ocho bytes cada uno
UN_CARACTER:
	push bc			;4767   ; y dentro, byte a byte
	xor a			;4768
	ld c,a			;4769
	ld b,002h		;476a
DOS_BITS:
	sla (hl)		;476c   ; dos bits por pasada, y el acarreo pasa al caracter de al lado
	rl c		;476e   ; los dos bits que se salen por la izquierda se guardan en C
	djnz DOS_BITS		;4770   ; dos bits por pasada
	ld de,00008h		;4772   ; ocho bytes atras esta la misma linea del caracter anterior
	or a			;4775
	sbc hl,de		;4776
	ld a,(hl)			;4778
	or c			;4779   ; y ahi entran los dos bits que salieron
	ld (hl),a			;477a
	add hl,de			;477b
	inc hl			;477c
	pop bc			;477d
	djnz UN_CARACTER		;477e   ; ocho caracteres por juego
	ld a,011h		;4780   ; el 0x11 otra vez: se acabo el juego de patrones
	cp (hl)			;4782
	jr nz,UN_PASE_ENTERO		;4783
	ld a,(0e042h)		;4785   ; con el bit 0 de 0xE042 se mezclan dos capas con un OR
	bit 0,a		;4788
	jr z,SUBE_ESTA_VERSION		;478a
	ld b,008h		;478c   ; ocho bytes, que es un caracter
	ld hl,0e300h		;478e
	ld de,0e318h		;4791
	ld ix,0e310h		;4794   ; la capa de encima
MEZCLA_LAS_CAPAS:
	ld a,(hl)			;4798
	or (ix+000h)		;4799
	ld (de),a			;479c   ; las dos capas juntas, con un OR
	inc hl			;479d
	inc de			;479e
	inc ix		;479f
	djnz MEZCLA_LAS_CAPAS		;47a1   ; ocho bytes: un caracter
	ld a,011h		;47a3   ; y su propio 0x11 para cerrarla
	ld (de),a			;47a5
SUBE_ESTA_VERSION:
	ld hl,0e300h		;47a6
	call SUBE_HASTA_EL_0x11		;47a9   ; esta version ya se puede subir
	ld a,(0e042h)		;47ac
	bit 0,a		;47af
	jr z,SIGUIENTE_VERSION		;47b1
	ld hl,0e320h		;47b3
	ld b,008h		;47b6
BORRA_LA_CAPA:
	ld (hl),000h		;47b8   ; la capa se borra antes de la siguiente vuelta
	dec hl			;47ba
	djnz BORRA_LA_CAPA		;47bb   ; ocho bytes borrados
	ld (hl),011h		;47bd
SIGUIENTE_VERSION:
	pop bc			;47bf   ; se recupera la cuenta de 0x4761: quedan las versiones de 4 y de 6 pixeles
	djnz UNA_DE_LAS_TRES		;47c0
	ld hl,0e300h		;47c2   ; hechas las tres, el andamio de 0xE300 se deja a cero; 0x480E y 0x486D vuelven a usar esa misma RAM para las listas de patrones
	ld bc,000a0h		;47c5   ; 0xA0 bytes: el andamio entero
	call BORRA_BC_BYTES		;47c8
	ret			;47cb
SUBE_HASTA_EL_0x11:
	ld b,008h		;47cc
OCHO_BYTES:
	ld a,(hl)			;47ce   ; ocho bytes por caracter
	out (098h),a		;47cf
	inc hl			;47d1
	djnz OCHO_BYTES		;47d2   ; ocho bytes: un caracter
	ld a,011h		;47d4   ; hasta encontrar el 0x11
	cp (hl)			;47d6
	jr nz,SUBE_HASTA_EL_0x11		;47d7
	ret			;47d9
SUBE_DEL_REVES:		; Los mismos patrones, pero cada grupo escrito de atras adelante: asi salen los dibujos mirando al otro lado
	push bc			;47da
	ld b,(hl)			;47db   ; el primer byte de cada grupo dice cuantas veces va
	inc hl			;47dc
GRUPO_DERECHO:
	push bc			;47dd
	push hl			;47de
	ld b,008h		;47df
	call SUBE_B_BYTES_YA		;47e1   ; el dibujo tal cual
	pop hl			;47e4
	pop bc			;47e5
	djnz GRUPO_DERECHO		;47e6   ; tantas copias como diga la cuenta
	dec hl			;47e8   ; el mismo contador otra vez, ahora para la copia invertida
	ld b,(hl)			;47e9
	ld a,008h		;47ea
	call HL_MAS_A		;47ec   ; ocho adelante, para leerlo del reves
GRUPO_INVERTIDO:
	push bc			;47ef
	push hl			;47f0
	ld b,008h		;47f1
OCHO_BYTES_AL_REVES:
	ld a,(hl)			;47f3   ; los mismos ocho bytes, de atras adelante
	dec hl			;47f4
	out (098h),a		;47f5   ; se escribe leyendo hacia atras: eso es lo que da la vuelta al dibujo
	djnz OCHO_BYTES_AL_REVES		;47f7   ; ocho bytes, de atras adelante
	pop hl			;47f9
	pop bc			;47fa
	djnz GRUPO_INVERTIDO		;47fb   ; tantas copias invertidas como diga la cuenta
	inc hl			;47fd
	pop bc			;47fe
	djnz SUBE_DEL_REVES		;47ff   ; y el grupo siguiente
	ret			;4801
SUBE_REPETIDOS:		; Parejas (cuantos, que byte)
	push bc			;4802
	ld b,(hl)			;4803   ; el primer byte de la pareja es cuantos, y el segundo que byte
	inc hl			;4804
	ld a,(hl)			;4805
	call RELLENA_CON_A		;4806
	inc hl			;4809
	pop bc			;480a
	djnz SUBE_REPETIDOS		;480b   ; tantas parejas como diga B
	ret			;480d

; ----------------------------------------------------------------------
; LAS LISTAS DE PATRONES DE LOS COCHES. Cada tipo de vehiculo es una tira de caracteres consecutivos que se monta en RAM al arrancar. Los tres tamanos salen de aqui: 5, 7 y 9 caracteres de largo.
; LAS LISTAS DE LOS COCHES. Cada tipo de vehiculo se guarda en RAM como cuatro desplazamientos y cuatro listas de caracteres, una por version desplazada. Los tres tamanos -5, 7 y 9 caracteres- se generan aqui de cero, sin ninguna tabla en el cartucho: los codigos de caracter salen contados.
; ----------------------------------------------------------------------
MONTA_LOS_COCHES:
	ld hl,0e390h		;480e   ; el coche corto, cinco caracteres
	ld a,005h		;4811
	call MONTA_UN_COCHE		;4813
	ld hl,0e3beh		;4816   ; el mediano, siete
	ld a,007h		;4819
	call MONTA_UN_COCHE		;481b
	ld hl,0e3fch		;481e   ; y el largo, nueve
	ld a,009h		;4821
	call MONTA_UN_COCHE		;4823
	ret			;4826
MONTA_UN_COCHE:
	push af			;4827
	ld (hl),004h		;4828   ; los cuatro primeros bytes son los desplazamientos de las cuatro versiones
	inc hl			;482a
	ld b,a			;482b
	sla a		;482c   ; con A caracteres, la primera lista ocupa 2A-1+4 bytes
	dec a			;482e
	ld b,a			;482f
	add a,004h		;4830
	ld (hl),a			;4832
	inc hl			;4833
	ld c,a			;4834
	ld a,b			;4835
	add a,002h		;4836
	ld b,a			;4838
	add a,c			;4839
	ld (hl),a			;483a
	inc hl			;483b
	add a,b			;483c
	ld (hl),a			;483d
	inc hl			;483e
	pop af			;483f
	sub 003h		;4840   ; el morro, la cola y los A-3 tramos iguales de en medio
	ld b,a			;4842
	inc a			;4843
	ld d,a			;4844
	ld e,004h		;4845   ; cuatro versiones
	ld c,080h		;4847   ; los caracteres del coche arrancan en el 0x80, y los de su fila de abajo en el 0x8F
	ld a,08fh		;4849
PRIMERA_COLUMNA:
	ld (hl),c			;484b   ; el morro
	inc hl			;484c
	ld (hl),a			;484d
	inc hl			;484e
	inc c			;484f
	inc a			;4850
COLUMNAS_DE_ENMEDIO:
	ld (hl),c			;4851   ; los tramos de en medio, todos el mismo dibujo
	inc hl			;4852
	ld (hl),a			;4853
	inc hl			;4854
	djnz COLUMNAS_DE_ENMEDIO		;4855   ; tantos tramos como pida el largo del coche
	inc c			;4857
	inc a			;4858
	cp 092h		;4859   ; el 0x92 se salta: ese codigo esta ocupado
	jr c,ULTIMA_COLUMNA		;485b
	inc c			;485d
	inc a			;485e
ULTIMA_COLUMNA:
	ld (hl),c			;485f   ; la cola, y el 0xFF que cierra la lista
	inc hl			;4860
	ld (hl),a			;4861
	inc hl			;4862
	ld (hl),0ffh		;4863
	ld b,d			;4865   ; la siguiente version repite el mismo reparto
	inc hl			;4866
	inc c			;4867
	inc a			;4868
	dec e			;4869   ; cuatro versiones
	jr nz,PRIMERA_COLUMNA		;486a
	ret			;486c

; ----------------------------------------------------------------------
; LAS LISTAS DE PATRONES DEL RIO. Los troncos y las tortugas, con sus plantillas en 0x4DDF, 0x4DEB y 0x4E02.
; LAS LISTAS DEL RIO. Igual que los coches, pero partiendo de plantillas que si estan en el cartucho: 0x4DDF para los cuatro tramos de tronco y 0x4DEB y 0x4E02 para los troncos y las tortugas, cortos y largos.
; ----------------------------------------------------------------------
MONTA_EL_RIO:
	ld hl,04ddfh		;486d   ; los cuatro tamanos de tronco, de 0x4DDF
	ld de,0e304h		;4870
	ld ix,0e300h		;4873
	call MONTA_CUATRO_LARGOS		;4877
	inc hl			;487a
	ld de,0e322h		;487b
	ld ix,0e31eh		;487e
	call MONTA_CUATRO_LARGOS		;4882
	inc hl			;4885
	ld de,0e340h		;4886
	ld ix,0e33ch		;4889
	call MONTA_CUATRO_LARGOS		;488d
	inc hl			;4890
	ld de,0e366h		;4891
	ld ix,0e362h		;4894
	call MONTA_CUATRO_LARGOS		;4898
	ld hl,04debh		;489b
	ld de,0e44eh		;489e
	ld ix,0e44ah		;48a1
	call MONTA_DESDE_PLANTILLA		;48a5   ; la rana rescatable, con su propia plantilla
	ld hl,0e44ah		;48a8   ; y aqui se fabrican las fases de la tortuga hundiendose
	ld a,020h		;48ab   ; la de medio hundir: los mismos caracteres, 0x20 mas alla
	ex af,af'			;48ad
	ld a,02ah		;48ae
	ex af,af'			;48b0
	call COPIA_Y_DESPLAZA		;48b1
	ld a,080h		;48b4   ; y con el bit 7 puesto, la del todo sumergida
	call COPIA_Y_DESPLAZA		;48b6
	ld hl,04e02h		;48b9
	ld de,0e4d8h		;48bc
	ld ix,0e4d4h		;48bf
	call MONTA_DESDE_PLANTILLA		;48c3
	ld hl,0e4d4h		;48c6
	ld a,020h		;48c9
	ex af,af'			;48cb
	ld a,03ah		;48cc
	ex af,af'			;48ce
	call COPIA_Y_DESPLAZA		;48cf
	ld a,080h		;48d2
	jr COPIA_Y_DESPLAZA		;48d4
MONTA_CUATRO_LARGOS:
	ex af,af'			;48d6
	ld a,004h		;48d7   ; los cuatro desplazamientos, otra vez
	ld (ix+000h),a		;48d9
	ex af,af'			;48dc
	ld a,(hl)			;48dd   ; el primer caracter y cuanto se avanza de uno al siguiente
	inc hl			;48de
	ld c,(hl)			;48df
	inc hl			;48e0
	ld b,004h		;48e1   ; cuatro versiones
	or a			;48e3
UN_LARGO:
	push bc			;48e4
	ld b,(hl)			;48e5
	ex de,hl			;48e6
	jr nc,UN_CARACTER_DEL_LARGO		;48e7
	inc b			;48e9
UN_CARACTER_DEL_LARGO:
	ld (hl),a			;48ea   ; el de arriba
	inc hl			;48eb
	push af			;48ec
	add a,c			;48ed   ; y el de abajo, que va C mas alla
	ld (hl),a			;48ee
	pop af			;48ef
	inc a			;48f0
	inc hl			;48f1
	ex af,af'			;48f2
	add a,002h		;48f3   ; cada version empieza dos caracteres despues
	ex af,af'			;48f5
	djnz UN_CARACTER_DEL_LARGO		;48f6   ; tantos caracteres como diga el largo
	ld (hl),0ffh		;48f8   ; el 0xFF cierra la lista
	inc hl			;48fa
	pop bc			;48fb
	dec b			;48fc   ; cuatro largos de tronco
	jr nz,SIGUIENTE_LARGO		;48fd
	ex de,hl			;48ff
	ret			;4900
SIGUIENTE_LARGO:
	ex af,af'			;4901
	inc a			;4902
	inc ix		;4903
	ld (ix+000h),a		;4905   ; y el desplazamiento de la siguiente version se apunta en la cabecera
	ex af,af'			;4908
	ex de,hl			;4909
	scf			;490a   ; el `scf` avisa a la vuelta siguiente de que ya no es la primera
	jr UN_LARGO		;490b
MONTA_DESDE_PLANTILLA:
	ex af,af'			;490d
	ld a,004h		;490e   ; los cuatro desplazamientos empiezan en 4, que es donde acaba la cabecera
	ld (ix+000h),a		;4910
	ex af,af'			;4913
	ld b,004h		;4914   ; cuatro versiones
CUATRO_VECES:
	push bc			;4916   ; cuatro versiones
LISTA_HASTA_EL_0xFF:
	ld a,(hl)			;4917
	cp 0ffh		;4918   ; el 0xFF cierra la plantilla
	jr z,CIERRA_LA_LISTA		;491a
	ld (de),a			;491c
	inc de			;491d
	add a,00eh		;491e   ; la fila de abajo es la de arriba mas catorce
	ld (de),a			;4920
	inc de			;4921
	inc hl			;4922
	ex af,af'			;4923
	add a,002h		;4924   ; y la siguiente version, dos caracteres mas alla
	ex af,af'			;4926
	jr LISTA_HASTA_EL_0xFF		;4927
CIERRA_LA_LISTA:
	ld (de),a			;4929   ; el 0xFF que cierra tambien se copia
	inc hl			;492a
	inc de			;492b
	pop bc			;492c
	dec b			;492d   ; cuatro versiones y se acabo
	ret z			;492e
	ex af,af'			;492f
	inc a			;4930
	inc ix		;4931
	ld (ix+000h),a		;4933   ; y se apunta donde empieza la version siguiente
	ex af,af'			;4936
	jr CUATRO_VECES		;4937
COPIA_Y_DESPLAZA:
	ld bc,00004h		;4939   ; la cabecera de cuatro bytes se copia tal cual
	ldir		;493c
	ld c,a			;493e
	ex af,af'			;493f
	ld b,a			;4940
	ex af,af'			;4941
SUMA_A_CADA_UNO:
	ld a,(hl)			;4942
	cp 0ffh		;4943
	jr z,GUARDA_Y_SIGUE		;4945
	bit 7,c		;4947   ; con el bit 7 en A no se suma nada: se pone el caracter 1, el del agua
	jr nz,FUERA_DE_LA_TIRA		;4949
	add a,c			;494b   ; y si no, todos los caracteres se corren A de golpe
	jr GUARDA_Y_SIGUE		;494c
FUERA_DE_LA_TIRA:
	ld a,001h		;494e
GUARDA_Y_SIGUE:
	ld (de),a			;4950
	inc de			;4951
	inc hl			;4952   ; caracter a caracter hasta el 0xFF
	djnz SUMA_A_CADA_UNO		;4953
	ret			;4955
SUBE_BLOQUE_CON_CABECERA:		; La direccion de VRAM y el tamano van delante de los datos
	push bc			;4956
	ld d,(hl)			;4957   ; los dos primeros bytes son la direccion de VRAM, el ALTO delante
	inc hl			;4958
	ld e,(hl)			;4959
	inc hl			;495a
	ld b,(hl)			;495b   ; el tercero es cuantos van, y un cero significa 256
	inc hl			;495c
	call SUBE_B_BYTES		;495d   ; y detras, los datos
	pop bc			;4960
	djnz SUBE_BLOQUE_CON_CABECERA		;4961   ; el bloque siguiente empieza donde acabo este
	ret			;4963
RELLENA_FILA_CRECIENTE:		; B caracteres consecutivos, y despues salta a la fila de abajo
	push af			;4964
	call PON_DIRECCION_VDP		;4965
	pop af			;4968
UNO_A_UNO:
	out (098h),a		;4969   ; caracteres consecutivos, que es como se guardan los rotulos anchos
	inc a			;496b
	djnz UNO_A_UNO		;496c
	ex de,hl			;496e
	ld de,00020h		;496f   ; y al acabar la fila se baja una: 32 caracteres
	add hl,de			;4972
	ex de,hl			;4973
	ret			;4974
FICHA_DE_VIDAS:
	ld hl,0e002h		;4975
FICHA_DEL_JUGADOR:
	call QUE_JUGADOR_ES		;4978
	jp HL_MAS_A		;497b
HL_MAS_A:
	add a,l			;497e
	ld l,a			;497f
	ret nc			;4980   ; con acarreo, el byte alto tambien sube
	inc h			;4981
	ret			;4982
PON_DIRECCION_VDP:		; DE al puerto 0x99: con el bit 14 puesto, para escribir
	ld a,e			;4983
	out (099h),a		;4984
	ld a,d			;4986
	out (099h),a		;4987
	ret			;4989
SUBE_B_BYTES:
	call PON_DIRECCION_VDP		;498a
SUBE_B_BYTES_YA:
	ld a,(hl)			;498d
	out (098h),a		;498e
	inc hl			;4990
	djnz SUBE_B_BYTES_YA		;4991
	ret			;4993
RELLENA_CON_C:
	call PON_DIRECCION_VDP		;4994
	ld a,c			;4997
RELLENA_CON_A:
	out (098h),a		;4998
	nop			;499a
	djnz RELLENA_CON_A		;499b
	ret			;499d
QUE_JUGADOR_ES:		; Devuelve Z si es el primero
	ld a,(0e001h)		;499e
	or a			;49a1
	ret			;49a2

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros del VDP, que 0x421E sube del 0
;   al 7. SCREEN 2 con los nombres en 0x3800, los patrones en 0x2000, el color
;   en 0x0000, los atributos de sprite en 0x3B00 y sus patrones en 0x1800, con
;   sprites de 16x16.
;   0x49a3..0x49ab  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 49a3  .....v..

; ----------------------------------------------------------------------
; DATOS doce_bytes_que_nadie_lee: Doce bytes justo detras de los registros del
;   VDP a los que NO llega ninguna instruccion: el bucle de 0x421E lee ocho y
;   para. Tienen forma de tres fichas de sprite -Y, X, dibujo, color-, las
;   tres con Y = 0 y el dibujo 0x38, que es la cabeza del cocodrilo. Queda
;   como pregunta abierta.
;   0x49ab..0x49b7  (12 bytes)
DATA_doce_bytes_que_nadie_lee:
	defb 000h,070h,038h,070h	; 49ab
	defb 000h,0a0h,038h,070h	; 49af
	defb 000h,0f0h,038h,0f0h	; 49b3

; ----------------------------------------------------------------------
; DATOS cursores_a_joystick: Los cuatro cursores no salen del teclado en el
;   mismo orden en que los quiere el juego, asi que 0x4606 los pasa por aqui.
;   El indice se monta con izquierda, arriba, abajo y derecha, y el valor sale
;   en el orden del joystick: arriba, abajo, izquierda, derecha. Las dieciseis
;   combinaciones estan cubiertas, y las imposibles -arriba con abajo,
;   izquierda con derecha- dan 0x80, que no es ninguna direccion.
;   0x49b7..0x49c7  (16 bytes)
DATA_cursores_a_joystick:
	defb 000h,004h,001h,005h,002h,006h,080h,080h,008h,080h,009h,080h,00ah,080h,080h,080h	; 49b7  ................

; ----------------------------------------------------------------------
; DATOS margenes_de_choque: Cuatro margenes por cada uno de los CATORCE tipos
;   de objeto, en el orden en que los pide 0x46F6: arriba, abajo, izquierda y
;   derecha. Se ve de un vistazo lo largo que es cada cosa: el tipo 6 llega a
;   0x1E y es el tronco mas largo, y los tipos 0 y 1 se quedan en 6, que son
;   los coches. Los tipos 9 y 12 los tienen los cuatro a CERO, y no es un
;   descuido: son las tortugas del todo sumergidas, que no chocan con nada y
;   por eso no sostienen a la rana.
;   0x49c7..0x49ff  (56 bytes)
DATA_margenes_de_choque:
	defb 0fah,006h,000h,001h	; 49c7
	defb 0fah,006h,000h,001h	; 49cb
	defb 0fbh,00ah,000h,001h	; 49cf
	defb 0fch,00eh,000h,001h	; 49d3
	defb 0fbh,00eh,000h,001h	; 49d7
	defb 0fbh,016h,000h,001h	; 49db
	defb 0fbh,01eh,000h,001h	; 49df
	defb 0fbh,00eh,000h,001h	; 49e3
	defb 0fbh,00eh,000h,001h	; 49e7
	defb 000h,000h,000h,000h	; 49eb
	defb 0fbh,016h,000h,001h	; 49ef
	defb 0fbh,016h,000h,001h	; 49f3
	defb 000h,000h,000h,000h	; 49f7
	defb 0fbh,016h,000h,001h	; 49fb

; ----------------------------------------------------------------------
; DATOS cinco_bytes_sueltos: Cinco bytes -01 06 11 16 21- entre los margenes
;   de choque y el primer rotulo, sin ninguna instruccion que los alcance. Van
;   de cinco en cinco y de once en once. Pregunta abierta.
;   0x49ff..0x4a04  (5 bytes)
DATA_cinco_bytes_sueltos:
	defb 001h,006h,011h,016h,021h	; 49ff

; ----------------------------------------------------------------------
; DATOS rotulos_del_titulo: La pantalla de titulo, en cuatro trozos para
;   0x462C: filas 5, 6, 8 y 12, todas en la columna 11.
;   0x4a04..0x4a42  (62 bytes)
DATA_rotulos_del_titulo:
	defb 078h,0abh,020h,021h,022h,023h,024h,025h,026h,023h,027h,020h,021h,022h,00fh,078h	; 4a04  x. !"#$%&#' !".x
	defb 0cbh,028h,029h,02ah,02bh,02ch,02dh,02eh,02fh,030h,031h,032h,02ah,033h,00fh,079h	; 4a14  .()*+,-./012*3.y
	defb 00bh,0fah,000h,0fbh,0fch,0fdh,0feh,0ffh,000h,000h,0e1h,0e9h,0e8h,0e3h,00fh,079h	; 4a24  ...............y
	defb 08bh,0aah,0abh,0ach,0adh,000h,0b4h,0aeh,0abh,0aeh,0b9h,0b2h,00fh,00fh	; 4a34  ..............

; ----------------------------------------------------------------------
; DATOS rotulo_tecla_1: Los 26 caracteres de la fila 15 desde la columna 4: la
;   linea de la tecla 1, un jugador con joystick.
;   0x4a42..0x4a60  (30 bytes)
DATA_rotulo_tecla_1:
	defb 079h,0e4h	; 4a42
	defb 0a1h,09ch,09ah,09bh,000h,000h,0a1h,0aah,0abh,0ach,0adh,0aeh,0afh,000h,000h,098h,099h,000h,0b8h,0b6h,0adh,0b4h,0b2h,0b1h,0b9h,09fh	; 4a44  ..........................
	defb 00fh,00fh	; 4a5e

; ----------------------------------------------------------------------
; DATOS rotulo_tecla_2: Igual en la fila 17: la tecla 2, dos jugadores con
;   joystick.
;   0x4a60..0x4a7e  (30 bytes)
DATA_rotulo_tecla_2:
	defb 07ah,024h	; 4a60
	defb 0a2h,09ch,09ah,09bh,000h,000h,0a2h,0aah,0abh,0ach,0adh,0aeh,0afh,0b4h,000h,098h,099h,000h,0b8h,0b6h,0adh,0b4h,0b2h,0b1h,0b9h,09fh	; 4a62  ..........................
	defb 00fh,00fh	; 4a7c

; ----------------------------------------------------------------------
; DATOS rotulo_tecla_3: Fila 19: la tecla 3, un jugador con el teclado.
;   0x4a7e..0x4a9c  (30 bytes)
DATA_rotulo_tecla_3:
	defb 07ah,064h	; 4a7e
	defb 0a3h,09ch,09ah,09bh,000h,000h,0a1h,0aah,0abh,0ach,0adh,0aeh,0afh,000h,000h,098h,099h,000h,09fh,0aeh,0adh,09dh,0b6h,0ach,0afh,09eh	; 4a80  ..........................
	defb 00fh,00fh	; 4a9a

; ----------------------------------------------------------------------
; DATOS rotulo_tecla_4: Fila 21: la tecla 4, dos jugadores con el teclado.
;   0x4a9c..0x4aba  (30 bytes)
DATA_rotulo_tecla_4:
	defb 07ah,0a4h	; 4a9c
	defb 0a4h,09ch,09ah,09bh,000h,000h,0a2h,0aah,0abh,0ach,0adh,0aeh,0afh,0b4h,000h,098h,099h,000h,09fh,0aeh,0adh,09dh,0b6h,0ach,0afh,09eh	; 4a9e  ..........................
	defb 00fh,00fh	; 4ab8

; ----------------------------------------------------------------------
; DATOS rotulo_jugador_1: Dos trozos en las filas 9 y 10 desde la columna 6,
;   el aviso de a quien le toca.
;   0x4aba..0x4ad2  (24 bytes)
DATA_rotulo_jugador_1:
	defb 079h,026h,01fh,00eh,000h,00fh,079h,046h,000h,000h,000h,0eah,0ebh,0ech,0edh,0eeh	; 4aba  y&....yF........
	defb 0efh,000h,0e1h,000h,000h,000h,00fh,00fh	; 4aca  ........

; ----------------------------------------------------------------------
; DATOS rotulo_jugador_2: El mismo aviso para el segundo jugador. Los ocho
;   bytes de aqui son solo su primer trozo: el segundo empieza en 0x4ADA y se
;   usa TAMBIEN por su cuenta.
;   0x4ad2..0x4ada  (8 bytes)
DATA_rotulo_jugador_2:
	defb 079h,026h,01fh,00eh,000h,00fh,079h,046h	; 4ad2  y&....yF

; ----------------------------------------------------------------------
; DATOS borra_el_1up: Aqui se solapan dos usos. Como final del rotulo de
;   0x4AD2 es su segundo trozo; y por su cuenta, 0x4697 se lleva estos dos
;   primeros bytes -00 00- a la fila 5 columna 25 para apagar el 1UP que
;   parpadea.
;   0x4ada..0x4aea  (16 bytes)
DATA_borra_el_1up:
	defb 000h,000h,000h,0eah,0ebh,0ech,0edh,0eeh,0efh,000h,0e2h,000h,000h,000h,00fh,00fh	; 4ada  ................

; ----------------------------------------------------------------------
; DATOS rotulo_de_fin: Lo que sale al acabarse la partida, en las filas 11 y
;   12.
;   0x4aea..0x4b02  (24 bytes)
DATA_rotulo_de_fin:
	defb 079h,066h,000h,000h,0f5h,0ech,0f3h,0eeh,000h,000h,0f6h,0f7h,0eeh,0efh,000h,000h	; 4aea  yf..............
	defb 00fh,079h,086h,01fh,00eh,000h,00fh,00fh	; 4afa  .y......

; ----------------------------------------------------------------------
; DATOS marcador_hi: El marcador del lateral derecho, en ocho trozos para
;   0x462C. Este primero es el HI de la fila 1.
;   0x4b02..0x4b09  (7 bytes)
DATA_marcador_hi:
	defb 078h,039h,0f0h,0f1h,00fh,078h,0b9h	; 4b02

; ----------------------------------------------------------------------
; DATOS marcador_1up: Los dos primeros bytes -E1 EA- valen para dos cosas: son
;   el 1UP dentro del rotulo entero y, sueltos, los que 0x4535 y 0x4687
;   escriben para encenderlo. Detras siguen los seis ceros de la fila 6.
;   0x4b09..0x4b14  (11 bytes)
DATA_marcador_1up:
	defb 0e1h,0eah,00fh,078h,0d9h,01fh,006h,0e0h,00fh,079h,019h	; 4b09  ...x.....y.

; ----------------------------------------------------------------------
; DATOS marcador_2up_y_resto: Igual con el 2UP en sus dos primeros bytes, y
;   detras los seis ceros del segundo jugador, el STAGE de la fila 11, el
;   PLAYER de la 14 y el TIME de la 17, todos en la columna 25.
;   0x4b14..0x4b36  (34 bytes)
DATA_marcador_2up_y_resto:
	defb 0e2h,0eah,00fh,079h,039h,01fh,006h,0e0h,00fh,079h,079h,0f4h,0f2h,0ech,0f5h,0eeh	; 4b14  ...y9....yy.....
	defb 00fh,079h,0d9h,0eah,0ebh,0ech,0edh,0eeh,0efh,00fh,07ah,039h,0f2h,0f1h,0f3h,0eeh	; 4b24  .y........z9....
	defb 00fh,00fh	; 4b34

; ----------------------------------------------------------------------
; DATOS patrones_del_juego: Doce bloques con cabecera para 0x4956: dos bytes
;   de destino en la VRAM con el ALTO delante, uno de tamano y detras los
;   datos. El tercero al undecimo son retoques de tres bytes sobre caracteres
;   sueltos.
;   0x4b36..0x4dd3  (669 bytes)
DATA_patrones_del_juego:
	defb 066h,0c0h,0f8h,000h,000h,002h,000h,08ah,0aah,0aah,0dah,000h,000h,008h,048h,0eeh	; 4b36  f.............H.
	defb 04ah,04ah,06ah,000h,000h,040h,049h,05ah,073h,052h,059h,000h,000h,000h,092h,052h	; 4b46  JJj..@IZsRY....R
	defb 0ceh,002h,0dch,000h,000h,000h,000h,07eh,000h,000h,000h,000h,07eh,063h,063h,07eh	; 4b56  .......~....~cc~
	defb 063h,063h,07eh,000h,07ch,066h,063h,063h,063h,066h,07ch,000h,063h,066h,06ch,078h	; 4b66  cc~.|fcccf|.cflx
	defb 07ch,06eh,067h,000h,01ch,022h,063h,063h,063h,022h,01ch,000h,018h,038h,018h,018h	; 4b76  |ng.."ccc"...8..
	defb 018h,018h,07eh,000h,03eh,063h,006h,00eh,03ch,070h,07fh,000h,03eh,063h,003h,00eh	; 4b86  ..~.>c..<p..>c..
	defb 003h,063h,03eh,000h,00eh,01eh,036h,066h,066h,07fh,006h,000h,07fh,060h,07eh,063h	; 4b96  .c>...6ff....`~c
	defb 003h,063h,03eh,000h,03eh,063h,060h,07eh,063h,063h,03eh,000h,07fh,063h,066h,00ch	; 4ba6  .c>.>c`~cc>..cf.
	defb 018h,018h,018h,000h,03eh,063h,063h,03eh,063h,063h,03eh,000h,03eh,063h,063h,03fh	; 4bb6  ....>cc>cc>.>cc?
	defb 003h,063h,03eh,000h,07eh,063h,063h,063h,07eh,060h,060h,000h,060h,060h,060h,060h	; 4bc6  .c>.~ccc~``.````
	defb 060h,060h,07eh,000h,01ch,036h,063h,063h,07fh,063h,063h,000h,066h,066h,07eh,03ch	; 4bd6  ``~..6cc.cc.ff~<
	defb 018h,018h,018h,000h,07fh,060h,060h,07eh,060h,060h,07fh,000h,07eh,063h,063h,062h	; 4be6  .....``~``..~ccb
	defb 07ch,066h,063h,000h,063h,063h,063h,07fh,063h,063h,063h,000h,03ch,018h,018h,018h	; 4bf6  |fc.ccc.ccc.<...
	defb 018h,018h,03ch,000h,07eh,018h,018h,018h,018h,018h,018h,000h,063h,077h,07fh,07fh	; 4c06  ..<.~.......cw..
	defb 06bh,063h,063h,000h,03eh,063h,060h,03eh,003h,063h,03eh,000h,03eh,063h,060h,067h	; 4c16  kcc.>c`>.c>.>c`g
	defb 063h,063h,03fh,000h,03eh,063h,063h,063h,063h,063h,03eh,067h,0b8h,048h,000h,063h	; 4c26  cc?.>ccccc>g.H.c
	defb 063h,063h,063h,036h,01ch,008h,000h,01fh,006h,006h,006h,006h,066h,03ch,000h,03eh	; 4c36  ccc6........f<.>
	defb 063h,060h,060h,060h,063h,03eh,03ch,042h,099h,0a1h,0a1h,099h,042h,03ch,003h,067h	; 4c46  c```c><B....B<.g
	defb 06eh,07ch,079h,079h,07fh,06fh,080h,000h,000h,03dh,0adh,0adh,0adh,03dh,000h,000h	; 4c56  n|yy.o...=...=..
	defb 000h,0ceh,063h,06fh,06bh,06fh,000h,000h,000h,07ch,056h,056h,056h,056h,000h,000h	; 4c66  ..coko...|VVVV..
	defb 0c0h,000h,0c0h,0c0h,0c0h,0c0h,060h,00eh,002h,007h,00fh,060h,016h,01ah,0f8h,0f0h	; 4c76  ......`....`....
	defb 03eh,03eh,03eh,03eh,03fh,03fh,03fh,03fh,01fh,03fh,07fh,0ffh,0feh,0fch,0f8h,0f0h	; 4c86  >>>>????.?......
	defb 0e0h,0c0h,080h,000h,000h,000h,03eh,03eh,060h,035h,003h,01fh,07fh,0fbh,060h,03dh	; 4c96  ......>>`5....`=
	defb 003h,00fh,0cfh,0efh,060h,045h,003h,078h,0fch,0bch,060h,04dh,003h,03fh,07fh,0f3h	; 4ca6  ....`E.x..`M.?..
	defb 060h,055h,003h,087h,0c7h,0c7h,060h,05dh,003h,0bch,0feh,0dfh,060h,065h,06bh,078h	; 4cb6  `U....`]....`ekx
	defb 0fch,0bch,060h,0f0h,0f0h,060h,000h,0f0h,0f0h,0f0h,03fh,03fh,03eh,03eh,03eh,03eh	; 4cc6  ..`..`....??>>>>
	defb 03eh,03eh,0f8h,0fch,0feh,07fh,03fh,01fh,00fh,007h,03eh,03eh,03eh,07eh,0fch,0fch	; 4cd6  >>....?...>>>~..
	defb 0f8h,0e0h,0f1h,0f1h,0f1h,0f1h,0f1h,0fbh,07fh,01fh,0efh,0efh,0efh,0efh,0efh,0efh	; 4ce6  ................
	defb 0cfh,00fh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,0e1h,003h,03fh,0f1h,0e1h,0f3h	; 4cf6  ............?...
	defb 07fh,01eh,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,0e7h,08fh,08fh,08fh,08fh,08fh,08fh	; 4d06  ................
	defb 08fh,08fh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,01eh,0f1h,0f2h,0f5h,0f5h,0f5h,0f5h	; 4d16  ................
	defb 0f2h,0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h,0e0h,061h,000h,0a8h,0ffh,0ffh,0ffh	; 4d26  .....h.(..a.....
	defb 0f0h,0f0h,0f0h,0ffh,0ffh,0efh,0efh,0efh,00fh,00fh,00fh,0efh,0efh,0f8h,0feh,0feh	; 4d36  ................
	defb 01fh,00fh,00fh,01fh,0ffh,003h,00fh,01fh,03fh,03ch,07ch,078h,078h,0f0h,0fch,0feh	; 4d46  ........?<|xx...
	defb 03fh,00fh,00fh,007h,007h,001h,007h,00fh,01fh,01eh,0beh,0bch,0bch,0feh,0ffh,0ffh	; 4d56  ?...............
	defb 087h,001h,000h,000h,000h,0fch,0feh,0feh,00eh,002h,000h,000h,000h,0ffh,0f0h,0f0h	; 4d66  ................
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0efh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,0fch,0fch,01eh	; 4d76  ................
	defb 01eh,00fh,00fh,007h,007h,078h,078h,07ch,03ch,03fh,01fh,08fh,0c3h,007h,007h,00fh	; 4d86  .....xx|<?......
	defb 00fh,03fh,0feh,0fch,0f0h,0bch,0bch,0beh,01eh,01fh,00fh,007h,001h,00fh,00fh,00fh	; 4d96  .?..............
	defb 00fh,08fh,0ffh,0ffh,0feh,078h,078h,07ch,03ch,03fh,01fh,00fh,003h,01eh,01eh,01eh	; 4da6  .....xx|<?......
	defb 01eh,01eh,0feh,0feh,0fch,0ffh,0f0h,0f0h,0f0h,0f0h,0ffh,0ffh,0ffh,0efh,00fh,00fh	; 4db6  ................
	defb 00fh,00fh,0efh,0efh,0efh,000h,000h,000h,000h,000h,000h,080h,0c0h	; 4dc6  .............

; ----------------------------------------------------------------------
; DATOS color_y_ultimo_patron: Ocho bytes con dos usos a la vez. El bloque de
;   patrones que empieza en 0x4B36 llega hasta 0x4DDA, asi que estos son su
;   ultimo caracter; y 0x4253 los lee como parejas -cuantos, que byte- para
;   llenar la tabla de color: 248 veces el 0xF0 y 168 veces el 0x30 desde el
;   caracter 1, y despues cuatro tandas de 256 desde el 0x80.
;   0x4dd3..0x4ddf  (12 bytes)
DATA_color_y_ultimo_patron:
	defb 0f8h,0f0h	; 4dd3
	defb 0a8h,030h	; 4dd5
	defb 000h,070h	; 4dd7
	defb 000h,070h	; 4dd9
	defb 000h,0f0h	; 4ddb
	defb 000h,0f0h	; 4ddd

; ----------------------------------------------------------------------
; DATOS coches_por_tamano: Cuatro grupos de tres bytes para 0x486D: el primer
;   caracter, cuanto se avanza y cuantos caben. De aqui salen las listas de
;   los cuatro tipos de vehiculo.
;   0x4ddf..0x4deb  (12 bytes)
DATA_coches_por_tamano:
	defb 010h,00bh,002h	; 4ddf
	defb 026h,00bh,002h	; 4de2
	defb 03ch,00fh,003h	; 4de5
	defb 05ah,013h,004h	; 4de8

; ----------------------------------------------------------------------
; DATOS troncos_cortos: Cuatro listas de caracteres cerradas por 0xFF, que
;   0x490D convierte en las listas de patrones de los troncos y las tortugas
;   cortas.
;   0x4deb..0x4e02  (23 bytes)
DATA_troncos_cortos:
	defb 09eh,09fh,09eh,09fh,0ffh,0a0h,0a1h,0a3h,0a1h,0a2h,0ffh,0a4h,0a5h,0a7h,0a5h,0a6h	; 4deb  ................
	defb 0ffh,0a8h,0a9h,0abh,0a9h,0aah,0ffh	; 4dfb

; ----------------------------------------------------------------------
; DATOS troncos_largos: Las mismas cuatro listas, pero con un tramo mas de
;   lomo cada una: los troncos largos.
;   0x4e02..0x4e21  (31 bytes)
DATA_troncos_largos:
	defb 09eh,09fh,09eh,09fh,09eh,09fh,0ffh,0a0h,0a1h,0a3h,0a1h,0a3h,0a1h,0a2h,0ffh,0a4h	; 4e02  ................
	defb 0a5h,0a7h,0a5h,0a7h,0a5h,0a6h,0ffh,0a8h,0a9h,0abh,0a9h,0abh,0a9h,0aah,0ffh	; 4e12  ...............

; ======================================================================
; CODIGO 0x4e21..0x51f8  (983 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA RANA. Un salto por pulsacion, y no se admite otro hasta que se suelta el mando. Arriba y abajo mueven 16 pixeles -una fila entera- y los lados solo 8, o sea media. Cada salto cambia el dibujo: 0x04 mirando arriba, 0x10 abajo, 0x1C a la izquierda y 0x24 a la derecha. Mientras dura el salto, el segundo sprite se queda plantado en la casilla de la que salio.
; ----------------------------------------------------------------------
MUEVE_LA_RANA:
	ld a,(0e280h)		;4e21   ; con el bit 0 puesto la rana esta muerta y no se mueve
	rrca			;4e24
	ret c			;4e25
	ld hl,0e280h		;4e26
	bit 5,(hl)		;4e29   ; bit 5: esta a mitad de un salto
	jp nz,ACABA_EL_SALTO		;4e2b
	bit 1,(hl)		;4e2e   ; bit 1: ya se ha movido, y no se repite hasta soltar
	ret nz			;4e30
	set 1,(hl)		;4e31
	ld de,0e282h		;4e33
	ld l,086h		;4e36   ; 0xE286 es el segundo sprite, el que se queda atras
	ld a,(0e009h)		;4e38
	rrca			;4e3b   ; bit 0 arriba, bit 1 abajo, bit 2 izquierda y bit 3 derecha
	jr c,SALTA_ARRIBA		;4e3c
	rrca			;4e3e
	jr c,SALTA_ABAJO		;4e3f
	rrca			;4e41
	jr c,SALTA_A_LA_IZQUIERDA		;4e42
	rrca			;4e44
	jr c,SALTA_A_LA_DERECHA		;4e45
NO_SE_HA_PULSADO_NADA:
	ld hl,0e280h		;4e47
	res 1,(hl)		;4e4a   ; y si no se pulso nada, el aviso se retira
	ret			;4e4c
SALTA_ARRIBA:
	ld a,(de)			;4e4d
	ld (hl),a			;4e4e
	sub 010h		;4e4f   ; una fila entera son 16 pixeles
	ld (de),a			;4e51
	inc de			;4e52
	inc hl			;4e53
	ld a,(de)			;4e54
	ld (hl),a			;4e55
	inc de			;4e56
	inc hl			;4e57
	ld a,004h		;4e58   ; dibujo 4: la rana mirando arriba
	ld (de),a			;4e5a
	ld a,008h		;4e5b   ; y el sprite de atras, el 8
	ld (hl),a			;4e5d
	ld b,a			;4e5e
	inc hl			;4e5f
	inc hl			;4e60
	inc (hl)			;4e61   ; sube la cuenta de filas alcanzadas
	call ARRANCA_EL_SALTO		;4e62
	ld bc,00010h		;4e65   ; diez puntos por cada salto hacia adelante
	jp SUMA_PUNTOS		;4e68
SALTA_ABAJO:
	ld a,(de)			;4e6b
	cp 0a8h		;4e6c   ; por debajo de la fila 0xA8 no se puede bajar mas
	ret nc			;4e6e
	ld (hl),a			;4e6f
	add a,010h		;4e70   ; dieciseis pixeles, una fila entera
	ld (de),a			;4e72
	inc de			;4e73
	inc hl			;4e74
	ld a,(de)			;4e75
	ld (hl),a			;4e76
	inc de			;4e77
	inc hl			;4e78
	ld a,010h		;4e79
	ld (de),a			;4e7b   ; dibujo 0x10: la rana mirando abajo
	ld a,014h		;4e7c
	ld (hl),a			;4e7e
	inc hl			;4e7f
	inc hl			;4e80
	dec (hl)			;4e81   ; y una fila menos en la cuenta de lo alcanzado
	ld b,008h		;4e82
	jr ARRANCA_EL_SALTO		;4e84
SALTA_A_LA_IZQUIERDA:
	inc hl			;4e86
	inc de			;4e87
	ld a,(de)			;4e88
	cp 011h		;4e89   ; el borde izquierdo esta en 0x11
	ret c			;4e8b
	sub 008h		;4e8c   ; a los lados solo se mueve media casilla, 8 pixeles
	ld (de),a			;4e8e
	ld (hl),a			;4e8f
	inc de			;4e90
	ld a,01ch		;4e91   ; dibujo 0x1C: la rana mirando a la izquierda
	ld (de),a			;4e93
	jr EL_SALTO_EMPIEZA		;4e94
SALTA_A_LA_DERECHA:
	inc de			;4e96
	inc hl			;4e97
	ld a,(de)			;4e98
	cp 0b0h		;4e99   ; y el derecho en 0xB0
	ret nc			;4e9b
	add a,008h		;4e9c   ; ocho pixeles, media casilla
	ld (de),a			;4e9e
	ld (hl),a			;4e9f
	inc de			;4ea0
	ld a,024h		;4ea1   ; dibujo 0x24: mirando a la derecha
	ld (de),a			;4ea3
EL_SALTO_EMPIEZA:
	ld b,004h		;4ea4
ARRANCA_EL_SALTO:		; Lo comun a los cuatro sentidos: el sonido, el sprite y la cuenta
	ld a,(0e014h)		;4ea6   ; en la demo el salto no suena
	or a			;4ea9
	jr z,SUENA_EL_SALTO		;4eaa
	call CALLA_EL_SONIDO		;4eac
	ld hl,0e043h		;4eaf
	ld (hl),080h		;4eb2   ; 0xE043 a 0x80: solo suena, no se mueve nada
SUENA_EL_SALTO:
	ld hl,05ee6h		;4eb4   ; el sonido del salto
	call PIDE_SONIDO		;4eb7
	ld de,07b04h		;4eba
	ld hl,0e282h		;4ebd
	call SUBE_B_BYTES		;4ec0
	ld hl,0e280h		;4ec3
	set 5,(hl)		;4ec6   ; bit 5: queda saltando ocho fotogramas
	inc hl			;4ec8
	ld (hl),008h		;4ec9   ; ocho fotogramas dura el salto
	ret			;4ecb
ACABA_EL_SALTO:
	inc hl			;4ecc
	dec (hl)			;4ecd
	ret nz			;4ece
	ld a,(0e284h)		;4ecf   ; al posarse, el segundo sprite se recoge
	sub 004h		;4ed2
	ld (0e284h),a		;4ed4
	ld hl,0e280h		;4ed7
	res 5,(hl)		;4eda
	ld a,0cfh		;4edc
	ld (0e286h),a		;4ede   ; la Y 0xCF deja el segundo sprite fuera de la pantalla
ESCONDE_EL_SEGUNDO:
	ld b,008h		;4ee1   ; ocho bytes: los dos sprites
	ld de,07b04h		;4ee3
	ld hl,0e282h		;4ee6
	jp SUBE_B_BYTES		;4ee9

; ----------------------------------------------------------------------
; EL BICHO QUE CRUZA EL RIO. Solo aparece con el tiempo por debajo de 0x71 y con la rana en la mitad de arriba. Cruza en linea recta y, al cogerlo, la rana se lo lleva a casa.
; ----------------------------------------------------------------------
EL_BICHO_DEL_RIO:
	ld a,(0e052h)		;4eec   ; solo con el tiempo por debajo de 0x71
	cp 071h		;4eef
	ret nc			;4ef1
	ld hl,0e280h		;4ef2
	bit 6,(hl)		;4ef5   ; con la rana ya cargada no sale otro
	ret nz			;4ef7
	ld hl,0e0d5h		;4ef8   ; la posicion del carril de arriba del todo
	ld a,(hl)			;4efb
	cp 024h		;4efc   ; antes de 0x24 no ha entrado aun
	ret c			;4efe
	dec hl			;4eff
	cp 028h		;4f00   ; y a partir de 0x28 ya esta dentro
	jr c,EL_BICHO_SALE		;4f02
	bit 5,(hl)		;4f04
	jr nz,EL_BICHO_ANDA		;4f06
	ret			;4f08
EL_BICHO_SALE:
	set 5,(hl)		;4f09   ; sale una sola vez por pasada
	ld hl,0e290h		;4f0b   ; bit 5: hay bicho en pantalla
	set 5,(hl)		;4f0e
	inc hl			;4f10
	ld (hl),014h		;4f11   ; la cuenta de lo que dura
	inc hl			;4f13
	ld (hl),004h		;4f14
	inc hl			;4f16
	ld (hl),038h		;4f17   ; dibujo 0x38
	inc hl			;4f19
	call CUARTOS_A_PIXELES		;4f1a   ; la X sale de la posicion del carril
	ld (hl),a			;4f1d
	inc hl			;4f1e
	ld (hl),020h		;4f1f   ; color 0x20 y once de cuenta
	inc hl			;4f21
	ld (hl),00bh		;4f22
	ld hl,0e293h		;4f24
	ld de,07b00h		;4f27   ; se pinta en el sprite 0
	ld b,004h		;4f2a   ; cuatro bytes: el atributo entero
	jp SUBE_B_BYTES		;4f2c
EL_BICHO_ANDA:
	ld hl,0e291h		;4f2f
	dec (hl)			;4f32   ; cuando la cuenta llega a cero, se da la vuelta
	jr z,EL_BICHO_SE_VA		;4f33
	ld a,(hl)			;4f35
	cp 010h		;4f36   ; y a mitad de camino cambia de dibujo
	ret nz			;4f38
	ld a,01ch		;4f39
	dec hl			;4f3b
	bit 5,(hl)		;4f3c
	jr z,PON_EL_DIBUJO		;4f3e
	ld a,024h		;4f40
PON_EL_DIBUJO:
	ld (0e295h),a		;4f42   ; el dibujo nuevo, segun hacia donde vaya
	bit 5,(hl)		;4f45
	inc hl			;4f47
	inc hl			;4f48
	jr z,EL_BICHO_VUELVE		;4f49
	ld c,008h		;4f4b   ; ocho pixeles por paso
	dec (hl)			;4f4d
	jr nz,AVANZA_EL_BICHO		;4f4e
	dec hl			;4f50
	dec hl			;4f51
	res 5,(hl)		;4f52
AVANZA_EL_BICHO:
	ld a,(0e294h)		;4f54   ; y se mueve
	add a,c			;4f57
	ld (0e294h),a		;4f58
PINTA_EL_BICHO:
	ld b,004h		;4f5b   ; cuatro bytes: el atributo entero
	ld de,07b00h		;4f5d
	ld hl,0e293h		;4f60
	ld a,(0e294h)		;4f63   ; fuera de la pantalla se le pone Y = 0xCF, que lo esconde
	cp 010h		;4f66
	jr c,ESCONDE_EL_BICHO		;4f68
	cp 0b0h		;4f6a
	jr c,PINTALO		;4f6c
ESCONDE_EL_BICHO:
	ld (hl),0cfh		;4f6e
PINTALO:
	jp SUBE_B_BYTES		;4f70
EL_BICHO_SE_VA:
	ld (hl),014h		;4f73   ; vuelve al dibujo de entrada
	ld a,(0e295h)		;4f75
	sub 004h		;4f78   ; y el dibujo baja cuatro: vuelve al de antes
	ld (0e295h),a		;4f7a
	jr PINTA_EL_BICHO		;4f7d
EL_BICHO_VUELVE:
	ld c,0f8h		;4f7f   ; ocho pixeles hacia atras
	inc (hl)			;4f81
	ld a,004h		;4f82   ; cuatro pasos antes de girar
	cp (hl)			;4f84
	jr nz,AVANZA_EL_BICHO		;4f85
	dec hl			;4f87
	dec hl			;4f88
	set 5,(hl)		;4f89
	jr AVANZA_EL_BICHO		;4f8b

; ----------------------------------------------------------------------
; EL COCODRILO. Cuatro sprites en fila. Abre y cierra la boca en un ciclo de 32 pasos: 22 con el dibujo 0x40 -abierta- y 10 con el 0x3C. Con la boca abierta, la parte de delante mata en vez de sostener a la rana; lo comprueba 0x524F.
; ----------------------------------------------------------------------
EL_COCODRILO:
	ld iy,0e2b1h		;4f8d
	ld hl,0e2b1h		;4f91
	xor a			;4f94
	cp (hl)			;4f95   ; el ciclo dura 32 pasos del carril
	jr nz,BAJA_EL_CICLO		;4f96
	ld (hl),020h		;4f98   ; 32 pasos de ciclo
	dec hl			;4f9a
	res 0,(hl)		;4f9b
	inc hl			;4f9d
	ld (iy+007h),040h		;4f9e   ; dibujo 0x40: la boca abierta, y esa mata
BAJA_EL_CICLO:
	dec (hl)			;4fa2
	ld a,00ah		;4fa3
	cp (hl)			;4fa5   ; a los 10 pasos que quedan, el dibujo 0x3C
	jr nz,COLOCA_EL_COCODRILO		;4fa6
	dec hl			;4fa8
	set 0,(hl)		;4fa9   ; el bit 0 avisa de que la boca se va a abrir
	inc hl			;4fab
	ld (iy+007h),03ch		;4fac
COLOCA_EL_COCODRILO:
	ld a,(ix+001h)		;4fb0   ; la X del carril esta en cuartos de caracter, y 0x50E0 la pasa a pixeles
	call CUARTOS_A_PIXELES		;4fb3
	cp 010h		;4fb6
	jr c,POR_LA_IZQUIERDA		;4fb8
	cp 090h		;4fba
	jr c,MIRA_EL_BORDE		;4fbc
POR_LA_IZQUIERDA:
	cp 0f0h		;4fbe
	jr c,POR_LA_DERECHA		;4fc0
	ld (iy+009h),018h		;4fc2
	jr POR_LA_DERECHA		;4fc6
MIRA_EL_BORDE:
	cp 016h		;4fc8
	jr nc,PINTA_LOS_CUATRO		;4fca
	jr ESCONDE_EL_PRIMERO		;4fcc
POR_LA_DERECHA:
	cp 0e0h		;4fce   ; por la derecha, de 0xE0 en adelante ya se sale
	jr c,MUY_A_LA_IZQUIERDA		;4fd0
	inc hl			;4fd2
	ld (hl),018h		;4fd3   ; el primer trozo se recoge
	inc hl			;4fd5
	ld (hl),000h		;4fd6
	ld (iy+005h),018h		;4fd8   ; y el tercero tambien
	jr PINTA_LOS_CUATRO		;4fdc
MUY_A_LA_IZQUIERDA:
	cp 010h		;4fde
	jr nc,CASI_FUERA		;4fe0
	ld (iy+00dh),018h		;4fe2
	jr PINTA_LOS_CUATRO		;4fe6
CASI_FUERA:
	cp 0c0h		;4fe8
	jr c,MIRA_EL_TERCERO		;4fea
	ld (iy+00dh),0cfh		;4fec   ; la Y 0xCF esconde el sprite
ESCONDE_EL_PRIMERO:
	ld (iy+001h),0cfh		;4ff0
MIRA_EL_TERCERO:
	cp 0b0h		;4ff4
	jr c,MIRA_EL_SEGUNDO		;4ff6
	ld (iy+009h),0cfh		;4ff8
MIRA_EL_SEGUNDO:
	cp 0a0h		;4ffc
	jr c,MIRA_EL_CUARTO		;4ffe
	ld (iy+005h),0cfh		;5000
MIRA_EL_CUARTO:
	cp 090h		;5004
	jr c,PINTA_LOS_CUATRO		;5006
	ld (iy+001h),018h		;5008
	ld (iy+002h),0c0h		;500c
	jr PINTA_PARTIDO		;5010
PINTA_LOS_CUATRO:
	ld b,010h		;5012   ; 0x10 bytes: los cuatro sprites del cocodrilo
	ld hl,0e2b2h		;5014
	ld de,07b0ch		;5017
	call X_DE_LOS_TROZOS_DEL_COCODRILO		;501a
	jp SUBE_B_BYTES		;501d
PINTA_PARTIDO:
	ld b,004h		;5020   ; cuatro bytes: solo la cabeza
	ld hl,0e2b2h		;5022
	ld de,07b0ch		;5025
PINTA_LA_CABEZA:
	call SUBE_B_BYTES		;5028
	ld b,003h		;502b   ; tres trozos mas
	ld hl,0e2beh		;502d
	ld de,07b10h		;5030
	call X_DE_LOS_TROZOS_DEL_COCODRILO		;5033
TROZO_A_TROZO:
	ld c,b			;5036   ; una ficha de sprite, cuatro bytes
	ld b,004h		;5037
	call SUBE_B_BYTES		;5039   ; cuatro bytes por trozo
	push bc			;503c
	ld bc,0fff8h		;503d   ; ocho atras en el origen
	add hl,bc			;5040
	ld bc,00004h		;5041   ; y cuatro adelante en el destino: el trozo siguiente
	ex de,hl			;5044
	add hl,bc			;5045
	ex de,hl			;5046
	pop bc			;5047
	ld b,c			;5048
	djnz TROZO_A_TROZO		;5049
	ret			;504b
X_DE_LOS_TROZOS_DEL_COCODRILO:		; No colorea nada: reparte la X de los tres trozos de atras. Los colores los deja el LDIR de 0x54E4
	exx			;504c   ; el juego de registros alternativo, que HL, DE y B llevan ya preparado el volcado a la VRAM
	ld de,0fffch		;504d   ; -4 bytes: las fichas de sprite se recorren hacia atras
	ld b,003h		;5050   ; tres trozos
	ld a,(ix+001h)		;5052   ; (ix+001h) es la posicion del carril, y 0x50E0 la pasa a la X en pixeles del trozo de mas a la izquierda
	call CUARTOS_A_PIXELES		;5055
	ld hl,0e2bfh		;5058   ; 0xE2BF es la X del cuarto sprite del cocodrilo: la ficha es Y, X, dibujo y color, y los colores los deja el LDIR de 0x54E4
TRES_TROZOS:
	ld (hl),a			;505b   ; se escribe la X, del cuarto trozo al segundo
	add hl,de			;505c
	add a,010h		;505d   ; dieciseis pixeles de uno a otro, que es lo que mide un sprite
	djnz TRES_TROZOS		;505f   ; dieciseis pixeles de un trozo al siguiente
	exx			;5061   ; la cabeza queda fuera de la cuenta: su X la tocan 0x4FD6 y 0x500C
	ret			;5062

; ----------------------------------------------------------------------
; LA RANA QUE SE RESCATA. La que aparece en un tronco y hay que llevar a casa. NO sale hasta la fase 3: `cp 003h / ret c` lo corta antes. El dibujo se elige con el registro R del refresco de la memoria, asi que sale uno u otro sin ninguna tabla de azar.
; ----------------------------------------------------------------------
LA_RANA_RESCATABLE:
	ld hl,0e082h		;5063
	call FICHA_DEL_QUE_JUEGA		;5066
	ld a,(hl)			;5069
	cp 003h		;506a   ; antes de la fase 3 no aparece nunca
	ret c			;506c
	ld hl,0e2a1h		;506d
	ld de,0e2a5h		;5070
	ld iy,0e2a0h		;5073
	ld (iy+003h),058h		;5077   ; (iy+003h) es la Y del sprite, no su color: el LDIR de 0x54EF la habia dejado en 0xCF, que la esconde, y 0x58 la saca a la pantalla
BAJA_LA_CUENTA:
	dec (hl)			;507b
	jp z,CAMBIA_DE_SENTIDO		;507c
	ld a,010h		;507f
	cp (hl)			;5081
	ret nz			;5082
	ld a,(de)			;5083
	add a,004h		;5084
	ld (de),a			;5086
	inc hl			;5087
	dec (hl)			;5088
	jr nz,COLOCALA		;5089
	ld (hl),004h		;508b
	ld a,r		;508d   ; el registro de refresco hace de moneda al aire
	ld (iy+005h),02ch		;508f   ; dibujo 0x2C o 0x34, uno de cada dos
	rrca			;5093
	jr nc,COLOCALA		;5094
	ld (iy+005h),034h		;5096
COLOCALA:
	ld a,(iy+004h)		;509a
	ld c,008h		;509d
	cp 0b0h		;509f
	jr c,POR_LA_IZQUIERDA_TAMBIEN		;50a1
MIRA_EL_SENTIDO:
	ld a,(de)			;50a3   ; con el dibujo mirando a un lado no se cambia de sentido
	cp 034h		;50a4
	jr z,PASO_CORTO		;50a6
	cp 02ch		;50a8
	jr z,PASO_CORTO		;50aa
	add a,c			;50ac
	ld (de),a			;50ad
PASO_CORTO:
	ld (hl),004h		;50ae
MIRA_EL_DIBUJO:
	ld c,004h		;50b0   ; cuatro pixeles por paso
	ld a,(de)			;50b2
	cp 028h		;50b3
	jr z,MUEVELA		;50b5
	cp 02ch		;50b7
	jr z,MUEVELA		;50b9
	ld c,0fch		;50bb
MUEVELA:
	ld a,(iy+004h)		;50bd   ; (iy+004h) es 0xE2A4, la X de la rana que se rescata
	add a,c			;50c0   ; C vale +4 o -4 segun el dibujo que lleve puesto
	ld (iy+004h),a		;50c1
	ld de,07b1ch		;50c4   ; los cuatro bytes de 0xE2A3 se suben al sprite 7, en VRAM 0x3B1C
	ld hl,0e2a3h		;50c7
	ld b,004h		;50ca   ; cuatro bytes: el atributo entero
	jp SUBE_B_BYTES		;50cc
POR_LA_IZQUIERDA_TAMBIEN:
	cp 011h		;50cf   ; por el borde de la izquierda, igual pero al reves
	jr nc,MIRA_EL_DIBUJO		;50d1
	ld c,0f8h		;50d3
	jr MIRA_EL_SENTIDO		;50d5
CAMBIA_DE_SENTIDO:
	ld (hl),014h		;50d7   ; se para y arranca hacia el otro lado
	inc hl			;50d9
	ld a,(de)			;50da
	sub 004h		;50db
	ld (de),a			;50dd
	jr COLOCALA		;50de
CUARTOS_A_PIXELES:		; La posicion de los carriles va en cuartos de caracter: (A-0x24)*2+0x10
	sub 024h		;50e0   ; restar 0x24, doblar y sumar 0x10: eso pasa los cuartos a pixeles
	sla a		;50e2
	add a,010h		;50e4
	ret			;50e6

; ----------------------------------------------------------------------
; PIDE UN SONIDO EN EL CANAL 3. Solo entra si el canal esta libre o si la partitura que se pide esta en una direccion MAS BAJA que la que suena: la prioridad de cada efecto es su propia direccion en el cartucho.
; ----------------------------------------------------------------------
PIDE_SONIDO:
	ld a,(0e031h)		;50e7
	or a			;50ea
	jr z,PON_EL_SONIDO		;50eb
	ld de,(0e030h)		;50ed   ; la prioridad de un efecto es su direccion: gana la mas baja
	or a			;50f1
	push hl			;50f2
	sbc hl,de		;50f3
	pop hl			;50f5
	ret nc			;50f6
PON_EL_SONIDO:
	ld (0e030h),hl		;50f7
	ret			;50fa

; ----------------------------------------------------------------------
; EL RELOJ DE LA PARTIDA. El tiempo arranca en 0x96 y baja uno cada 20 fotogramas. La cuenta va en BCD -0x5104 resta con `add a,099h / daa` y los avisos se comparan con `cp 060h` y `cp 032h`-, asi que 0x96 son NOVENTA Y SEIS unidades, no 150: 32 segundos a 60 Hz. Al llegar a cero la rana muere. Por el camino pasan dos cosas que no se ven jugando: a los 0x60 cuatro objetos de la fila 15 se hacen mas rapidos, y a los 0x32 el caracter de la barra cambia de color.
; ----------------------------------------------------------------------
EL_RELOJ:
	ld hl,0e053h		;50fb
	dec (hl)			;50fe   ; una unidad de tiempo cada veinte fotogramas
	ret nz			;50ff
	ld (hl),014h		;5100   ; veinte fotogramas por unidad de tiempo
	dec hl			;5102
	ld a,(hl)			;5103
	add a,099h		;5104   ; restar uno en BCD es sumar 0x99 y ajustar
	daa			;5106
	ld (hl),a			;5107
	jr nz,MIRA_LOS_0x60		;5108
	ld b,011h		;510a   ; se acabo el tiempo: la rana muere
	ld hl,0e0b0h		;510c
QUITA_EL_BIT_DE_ENCIMA:
	res 4,(hl)		;510f   ; bit 4: el objeto lleva la rana encima. Se quita de las diecisiete fichas antes de matarla, para que ninguna siga tirando de ella
	inc hl			;5111   ; cuatro bytes de una ficha a la siguiente
	inc hl			;5112
	inc hl			;5113
	inc hl			;5114
	djnz QUITA_EL_BIT_DE_ENCIMA		;5115   ; las diecisiete, una a una
	jp SE_MUERE		;5117   ; y a morir por el mismo camino que un choque
MIRA_LOS_0x60:
	cp 060h		;511a   ; al llegar a 0x60, y una sola vez por fase, cuatro objetos de la fila 15 aceleran
	jr nz,MIRA_LOS_0x32		;511c
	push hl			;511e
	ld hl,0e083h		;511f
	call FICHA_DEL_QUE_JUEGA		;5122
	bit 1,(hl)		;5125
	jr nz,YA_ACELERARON		;5127
	set 1,(hl)		;5129
	ld hl,0e10ah		;512b   ; cuatro fichas seguidas, y a cada una se le baja la velocidad en uno
	ld b,004h		;512e   ; cuatro fichas
CUATRO_MAS_RAPIDOS:
	dec (hl)			;5130
	ld a,004h		;5131
	call HL_MAS_A		;5133   ; cuatro bytes de una ficha a la siguiente
	djnz CUATRO_MAS_RAPIDOS		;5136   ; las cuatro, una a una
YA_ACELERARON:
	pop hl			;5138
	jr LA_BARRA_DEL_TIEMPO		;5139
MIRA_LOS_0x32:
	push af			;513b   ; se guarda el tiempo, que 0x514B lo necesita otra vez
	jr nc,COMPARA_CON_0x32		;513c   ; el acarreo sigue siendo el de 0x511A: por encima de 0x60 no se pide musica
	ld a,(0e029h)		;513e   ; solo se recarga el canal 2 si ya se habia callado, y asi la partitura se encadena sola
	or a			;5141
	jr nz,COMPARA_CON_0x32		;5142
	ld hl,05ef0h		;5144   ; 0x5EF0 no arranca hasta que el tiempo baja de 0x60
	ld (0e028h),hl		;5147
COMPARA_CON_0x32:
	pop af			;514a
	cp 032h		;514b   ; al llegar a 0x32 la barra del tiempo se pone roja
	jr nz,LA_BARRA_DEL_TIEMPO		;514d
	ld hl,05ec1h		;514f
	call PIDE_SONIDO		;5152
	ld de,PINTA_LA_CABEZA		;5155   ; 32 bytes en la tabla de color: los caracteres de la barra
	ld c,080h		;5158
	ld b,020h		;515a   ; 0x20 casillas: la barra entera
	call RELLENA_CON_C		;515c

; ----------------------------------------------------------------------
; LA BARRA DEL TIEMPO. Ocho caracteres de 0xE055 en adelante, aunque solo se dibujan seis. Cada uno pasa por cinco dibujos -del 5 al 9- y luego se apaga; la barra avanza un paso cada cuatro unidades de tiempo.
; ----------------------------------------------------------------------
LA_BARRA_DEL_TIEMPO:
	ld hl,0e054h		;515f
	ld a,(hl)			;5162
	or a			;5163
	jr nz,BAJA_LA_CUENTA_DE_BARRA		;5164
	ld (hl),004h		;5166   ; un paso cada cuatro unidades de tiempo
BAJA_LA_CUENTA_DE_BARRA:
	ld hl,0e054h		;5168
	dec (hl)			;516b   ; mientras no llegue a cero, no toca
	ret nz			;516c
BUSCA_EL_TRAMO:
	inc hl			;516d   ; busca el primer tramo que aun no este apagado
	ld a,(hl)			;516e
	or a			;516f
	jr z,BUSCA_EL_TRAMO		;5170
	inc (hl)			;5172
	ld a,009h		;5173   ; al pasar del 9 el tramo se apaga
	cp (hl)			;5175
	jr nz,PINTA_LA_BARRA		;5176
	ld (hl),000h		;5178
PINTA_LA_BARRA:
	ld hl,0e055h		;517a
	ld de,07a59h		;517d   ; VRAM 0x3A59: fila 18, columna 25
	ld b,006h		;5180   ; seis casillas: la barra entera
	jp SUBE_B_BYTES		;5182

; ----------------------------------------------------------------------
; LOS CHOQUES. Se mira todo contra la rana en el mismo sitio: el bicho del rio, la rana que se rescata, los bordes de la pantalla y, si esta en el agua, la fila de troncos o tortugas que le toque segun a que altura haya llegado. Devuelve acarreo si la rana ha muerto.
; ----------------------------------------------------------------------
LOS_CHOQUES:
	ld b,011h		;5185   ; diecisiete fichas, y a todas se les quita el bit de "lleva la rana encima"
	ld hl,0e0b0h		;5187
QUITA_EL_BIT_4:
	res 4,(hl)		;518a   ; las diecisiete fichas, de cuatro en cuatro
	inc hl			;518c   ; cuatro bytes de una ficha a la siguiente
	inc hl			;518d
	inc hl			;518e
	inc hl			;518f
	djnz QUITA_EL_BIT_4		;5190
	ld hl,0e293h		;5192   ; la caja del bicho del rio
	ld c,(hl)			;5195
	inc hl			;5196
	ld b,(hl)			;5197
	ld l,082h		;5198   ; y la de la rana, que esta en 0xE282
	ld e,(hl)			;519a
	inc hl			;519b
	ld d,(hl)			;519c
	ld a,003h		;519d
	call HAY_CHOQUE		;519f   ; tipo 3: la caja del bicho del rio
	jr nc,CHOCA_CON_LA_RESCATABLE		;51a2
	ld hl,05edfh		;51a4   ; el sonido de cogerlo
	call PIDE_SONIDO		;51a7
	ld hl,0e280h		;51aa
	set 6,(hl)		;51ad   ; bit 6: la rana ya lleva algo a casa
	ld hl,0e0d4h		;51af   ; y la rana que se rescata deja de estar cogida
	res 5,(hl)		;51b2
	ld hl,0e293h		;51b4
	ld (hl),0cfh		;51b7   ; el bicho desaparece de la pantalla
	ld de,07b00h		;51b9
	ld b,004h		;51bc
	call SUBE_B_BYTES		;51be
	ld a,002h		;51c1   ; la rana cambia de dibujo: ya lleva algo
	ld (0e285h),a		;51c3
	ld (0e289h),a		;51c6
	call ESCONDE_EL_SEGUNDO		;51c9
CHOCA_CON_LA_RESCATABLE:
	ld hl,0e2a3h		;51cc   ; la caja de la rana que se rescata
	ld c,(hl)			;51cf
	inc hl			;51d0
	ld b,(hl)			;51d1
	ld l,082h		;51d2
	ld e,(hl)			;51d4
	inc hl			;51d5
	ld d,(hl)			;51d6
	ld a,003h		;51d7   ; tipo 3, la misma caja que el bicho
	call HAY_CHOQUE		;51d9   ; con acarreo esta cogida, y se sale sin mirar nada mas
	ret c			;51dc
MIRA_LOS_BORDES:
	ld hl,0e283h		;51dd   ; con esta no se muere: solo cuenta si se coge
	ld a,(hl)			;51e0
	cp 00ah		;51e1   ; fuera de 0x0A a 0xB8 la rana se ha salido por un lado
	ret c			;51e3
	cp 0b8h		;51e4
	ccf			;51e6
	ret c			;51e7
EN_QUE_FILA_ESTA:
	ld hl,0e28ah		;51e8
	ld a,(hl)			;51eb
	cp 006h		;51ec   ; por encima de la sexta fila ya no hay rio que valga
	jr nc,$+24		;51ee
	or a			;51f0
	ret z			;51f1
	cp 005h		;51f2
	ret z			;51f4
	call BUSCA_EN_TABLA		;51f5   ; y si esta en el agua, la fila que le toca: la 1 es la de mas abajo

; ----------------------------------------------------------------------
; DATOS filas_del_rio: Las cuatro filas de agua, de abajo arriba, para el
;   `call 0x57FF` de 0x51F5. La primera palabra es 0 porque la fila 0 no es
;   agua.
;   0x51f8..0x5203  (11 bytes)
DATA_filas_del_rio:
	defw 00000h	; 51f8
	defw 0e138h	; 51fa
	defw 0e11ch	; 51fc
	defw 0e108h	; 51fe
	defw 0e0f4h	; 5200
	defb 0ffh	; 5202

; ======================================================================
; CODIGO 0x5203..0x520f  (12 bytes)
; ======================================================================


MIRA_ESA_FILA:
	jp RECORRE_LA_FILA		;5203
LA_ORILLA_DE_ARRIBA:
	cp 00ah		;5206   ; la fila 10 es la de las casas
	jr z,$+108		;5208
	sub 006h		;520a   ; las cuatro filas de la carretera se numeran a partir de la 6
	call BUSCA_EN_TABLA		;520c

; ----------------------------------------------------------------------
; DATOS filas_de_la_carretera: Las cuatro filas de asfalto, para el `call
;   0x57FF` de 0x520C.
;   0x520f..0x5218  (9 bytes)
DATA_filas_de_la_carretera:
	defw 0e0e4h	; 520f
	defw 0e0d4h	; 5211
	defw 0e0c0h	; 5213
	defw 0e0b0h	; 5215
	defb 0ffh	; 5217

; ======================================================================
; CODIGO 0x5218..0x5301  (233 bytes)
; ======================================================================


MIRA_LA_CARRETERA:
	call RECORRE_LA_FILA		;5218
	jr c,SE_SUBE_ENCIMA		;521b
	scf			;521d
	ld hl,0e040h		;521e   ; en la carretera, tocar algo mata
	ld (hl),001h		;5221
	ret			;5223
SE_SUBE_ENCIMA:
	set 4,(hl)		;5224   ; bit 4: este objeto lleva la rana encima y tira de ella
	or a			;5226
	ret			;5227

; ----------------------------------------------------------------------
; RECORRE UNA FILA. Va ficha a ficha comparando con la rana hasta el que tiene el bit 7, que cierra la fila. En el agua, tocar algo es SALVARSE; el unico caso aparte es el cocodrilo -tipo 0x0D-, que con la boca abierta mata por delante.
; ----------------------------------------------------------------------
RECORRE_LA_FILA:
	push bc			;5228
	pop hl			;5229
FICHA_A_FICHA:
	inc hl			;522a
	ld a,(hl)			;522b   ; el segundo byte de la ficha es la posicion
	ld b,a			;522c
	push hl			;522d
	ld hl,0e282h		;522e   ; la caja de la rana
	ld c,(hl)			;5231
	ld e,(hl)			;5232
	inc hl			;5233
	ld a,(hl)			;5234
	srl a		;5235   ; la Y de la rana se parte por la mitad para pasarla a la escala del carril
	add a,01ch		;5237   ; la posicion del carril esta en otra escala
	ld d,a			;5239
	pop hl			;523a
	dec hl			;523b
	ld a,(hl)			;523c
	and 00fh		;523d
	push hl			;523f
	call HAY_CHOQUE		;5240   ; y se compara con la caja del objeto
	pop hl			;5243
	jr c,MIRA_SI_ES_COCODRILO		;5244
	bit 7,(hl)		;5246   ; bit 7: esta era la ultima ficha de la fila
	ret nz			;5248
	inc hl			;5249   ; no ha chocado con este: al siguiente, cuatro bytes mas alla
	inc hl			;524a
	inc hl			;524b
	inc hl			;524c
	jr FICHA_A_FICHA		;524d
MIRA_SI_ES_COCODRILO:
	ld a,(hl)			;524f
	and 00fh		;5250   ; el nibble de abajo es el tipo
	cp 00dh		;5252   ; tipo 0x0D: el cocodrilo
	jr nz,ESTA_A_SALVO		;5254
	push hl			;5256
	ld hl,0e283h		;5257   ; la X de la rana
	ld d,(hl)			;525a
	ld a,040h		;525b   ; con el dibujo 0x40 la boca esta abierta
	ld hl,0e2b8h		;525d
	cp (hl)			;5260
	jr nz,NO_LE_HA_COMIDO		;5261
	dec hl			;5263
	ld b,(hl)			;5264   ; la caja de la cabeza del cocodrilo, tres bytes por debajo
	dec hl			;5265
	ld e,(hl)			;5266
	ld c,(hl)			;5267
	xor a			;5268
	call HAY_CHOQUE		;5269   ; y entonces la cabeza mata en vez de sostener
	jr c,SE_LO_HA_COMIDO		;526c
NO_LE_HA_COMIDO:
	pop hl			;526e
ESTA_A_SALVO:
	scf			;526f
	ret			;5270
SE_LO_HA_COMIDO:
	pop hl			;5271
	or a			;5272
	ret			;5273
MIRA_SI_ENTRA_EN_CASA:
	ld hl,0e283h		;5274
	ld a,(hl)			;5277   ; la casa cae cada 32 pixeles, con 8 de margen
	add a,004h		;5278
	and 01fh		;527a
	cp 008h		;527c
	jr nc,ESTA_A_SALVO		;527e
	ld hl,0e285h		;5280
	ld (hl),000h		;5283
	call PINTA_LOS_DOS_SPRITES		;5285
	ld hl,0e040h		;5288   ; 0xE040 bit 1: se pasa al bonus del tiempo
	ld (hl),002h		;528b
	or a			;528d
	ret			;528e

; ----------------------------------------------------------------------
; METER LA RANA EN CASA. Las cinco casas estan en las columnas 4, 8, 12, 16 y 20, y cada una tiene su bit en 0xE080. Si el bit YA estaba puesto, la casa esta ocupada y la rana muere: `jp 0x5305` sin mas.
; ----------------------------------------------------------------------
ENTRA_EN_CASA:
	ld hl,0e283h		;528f
	ld a,(hl)			;5292
	push af			;5293
	ld hl,0e080h		;5294
	call FICHA_DEL_QUE_JUEGA		;5297
	pop af			;529a
	cp 025h		;529b   ; por debajo de 0x25 es la primera casa
	jr c,CASA_1		;529d
	cp 045h		;529f
	jr c,CASA_2		;52a1
	cp 065h		;52a3
	jr c,CASA_3		;52a5
	cp 085h		;52a7
	jr c,CASA_4		;52a9
	bit 4,(hl)		;52ab   ; y por encima de 0x85, la quinta
	jr nz,CASA_OCUPADA_SE_MUERE		;52ad   ; la casa ya estaba ocupada: se muere
	set 4,(hl)		;52af
	ld de,07834h		;52b1
	jr CUENTA_LA_CASA		;52b4
CASA_1:
	bit 0,(hl)		;52b6
	jr nz,CASA_OCUPADA_SE_MUERE		;52b8
	set 0,(hl)		;52ba
	ld de,07824h		;52bc
	jr CUENTA_LA_CASA		;52bf
CASA_2:
	bit 1,(hl)		;52c1
	jr nz,$+66		;52c3
	set 1,(hl)		;52c5
	ld de,07828h		;52c7
	jr CUENTA_LA_CASA		;52ca
CASA_3:
	bit 2,(hl)		;52cc
	jr nz,CASA_OCUPADA_SE_MUERE		;52ce
	set 2,(hl)		;52d0
	ld de,0782ch		;52d2
	jr CUENTA_LA_CASA		;52d5
CASA_4:
	bit 3,(hl)		;52d7
	jr nz,CASA_OCUPADA_SE_MUERE		;52d9
	set 3,(hl)		;52db
	ld de,07830h		;52dd
CUENTA_LA_CASA:
	inc hl			;52e0
	inc (hl)			;52e1   ; una casa mas de las cinco
PINTA_LA_RANA_EN_CASA:
	ld hl,05301h		;52e2   ; la rana en casa es un cuadrado de 2x2: 0A 0B arriba, 0C 0D abajo
	ld b,002h		;52e5
	call SUBE_B_BYTES		;52e7
	push hl			;52ea
	ex de,hl			;52eb
	ld a,020h		;52ec
	call HL_MAS_A		;52ee   ; +32 caracteres para bajar una fila
	ex de,hl			;52f1
	pop hl			;52f2
	ld b,002h		;52f3
	call SUBE_B_BYTES		;52f5
	ld hl,0e040h		;52f8
	ld (hl),004h		;52fb   ; 0xE040 bit 2: fase superada
	ret			;52fd
CASA_OCUPADA_SE_MUERE:
	jp SE_MUERE		;52fe

; ----------------------------------------------------------------------
; DATOS rana_en_casa: Los cuatro caracteres con los que se dibuja una rana
;   metida en su casa: 0x0A y 0x0B arriba, 0x0C y 0x0D abajo.
;   0x5301..0x5305  (4 bytes)
DATA_rana_en_casa:
	defb 00ah,00bh	; 5301
	defb 00ch,00dh	; 5303

; ======================================================================
; CODIGO 0x5305..0x5457  (338 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA MUERTE. Devuelve la rana a la orilla de abajo, calla lo que sonara y suelta la musica de la muerte.
; ----------------------------------------------------------------------
SE_MUERE:
	ld hl,0e040h		;5305   ; 0xE040 bit 0: desde el fotograma siguiente la interrupcion entra por 0x40BC
	ld (hl),001h		;5308
	ld hl,0e083h		;530a   ; 0xE083 es la bandera de fase del jugador 1 y 0xE08B la del 2
	call QUE_JUGADOR_ES		;530d
	jr nz,BORRA_LA_BANDERA		;5310   ; y esta al reves: con Z juega el primero y aun asi se coge 0xE08B. Comparese con 0x5406, que para lo mismo pasa por FICHA_DEL_QUE_JUEGA
	ld l,08bh		;5312
BORRA_LA_BANDERA:
	ld (hl),000h		;5314   ; la unica bandera que vive en este byte es el bit 1 que pone 0x5129: los cuatro objetos de la fila 15 ya han acelerado en esta fase
	call MUEVE_LOS_CARRILES		;5316   ; pero los carriles siguen moviendose mientras se muere
	call EL_BICHO_DEL_RIO		;5319
	call LA_RANA_RESCATABLE		;531c
	ld hl,0e018h		;531f
	ld a,(hl)			;5322
	or a			;5323
	jr nz,ACABA_LA_MUERTE		;5324
	ld (hl),009h		;5326
	ld hl,0e283h		;5328   ; la rana vuelve a la orilla, sin salirse por los lados
	ld a,(hl)			;532b
	cp 0aeh		;532c
	jr c,MIRA_EL_BORDE_IZQUIERDO		;532e
	ld (hl),0aeh		;5330
MIRA_EL_BORDE_IZQUIERDO:
	cp 012h		;5332
	jr nc,LA_RANA_TUMBADA		;5334
	ld (hl),012h		;5336
LA_RANA_TUMBADA:
	inc hl			;5338
	ld (hl),050h		;5339   ; Y = 0x50 y el dibujo 0x0A: la rana tumbada
	inc hl			;533b
	ld (hl),00ah		;533c
	call PINTA_LOS_DOS_SPRITES		;533e
	call CALLA_EL_SONIDO		;5341
	ld hl,05e99h		;5344   ; la musica de la muerte, en el canal 3
	ld (0e030h),hl		;5347
	ret			;534a
ACABA_LA_MUERTE:
	ld hl,0e018h		;534b
	ld a,(hl)			;534e
	cp 001h		;534f   ; al llegar a 1 se pasa a la escena de fin de vida
	jr nz,ESCONDE_O_TUMBA		;5351
	call BORRA_LOS_SPRITES		;5353
	ld hl,0e040h		;5356
	ld (hl),008h		;5359
	ret			;535b
ESCONDE_O_TUMBA:
	xor a			;535c   ; HL viene de 0x534B con 0xE018, la espera que le queda a la muerte
	bit 0,(hl)		;535d   ; su bit 0 cambia cada 32 fotogramas, asi que la rana muerta parpadea
	ld (0e285h),a		;535f   ; color 0, que en un sprite es transparente
	jr nz,PINTA_LOS_DOS_SPRITES		;5362
	ld a,00ah		;5364   ; y el 0x0A con el que sale de 0x558C
	ld (0e285h),a		;5366
PINTA_LOS_DOS_SPRITES:
	ld hl,0e286h		;5369
	ld (hl),0cfh		;536c   ; el segundo sprite se aparta con Y = 0xCF
	ld l,082h		;536e
	ld de,07b04h		;5370
	ld b,008h		;5373
	jp SUBE_B_BYTES		;5375

; ----------------------------------------------------------------------
; EL BONUS DEL TIEMPO. Con la rana ya en casa, el reloj se vacia de golpe y cada unidad que quedaba vale diez puntos. Si con esa era la quinta casa, sube la fase.
; ----------------------------------------------------------------------
BONUS_DEL_TIEMPO:
	ld hl,0e043h		;5378
	bit 1,(hl)		;537b   ; bit 1 de 0xE043: mientras suena la musica, no se descuenta
	jr z,CUENTA_EL_BONUS		;537d
	ld a,(0e021h)		;537f
	or a			;5382
	ret nz			;5383
	jp A_MONTAR_OTRA_FASE		;5384
CUENTA_EL_BONUS:
	ld hl,0e019h		;5387
	bit 0,(hl)		;538a   ; un paso cada dos fotogramas
	ret z			;538c
	ld hl,0e052h		;538d
	ld a,(hl)			;5390
	add a,099h		;5391   ; una unidad menos de tiempo, en BCD
	daa			;5393
	jr z,SE_ACABO_EL_BONUS		;5394
	ld (hl),a			;5396
	jr z,SE_ACABO_EL_BONUS		;5397
	ld bc,00010h		;5399   ; diez puntos por unidad
	call SUMA_PUNTOS		;539c
	call LA_BARRA_DEL_TIEMPO		;539f
	ld a,(0e014h)		;53a2
	or a			;53a5
	jr nz,MIRA_SI_TRAIA_ALGO		;53a6
	ld hl,05edbh		;53a8   ; el tic de la cuenta
	call PIDE_SONIDO		;53ab
MIRA_SI_TRAIA_ALGO:
	ld hl,0e280h		;53ae
	bit 6,(hl)		;53b1   ; bit 6: la rana traia algo, y se dibuja en la casa
	ret z			;53b3
	inc hl			;53b4
	inc hl			;53b5
	inc hl			;53b6
	ld a,(hl)			;53b7   ; la X de la rana, que es donde se queda lo que traia
	ld hl,0e2e8h		;53b8
	ld (hl),001h		;53bb   ; Y = 1: la fila de arriba del todo
	inc hl			;53bd
	ld (hl),a			;53be
	inc hl			;53bf
	ld (hl),04ch		;53c0   ; dibujo 0x4C, en blanco
	inc hl			;53c2
	ld (hl),00fh		;53c3
	ld hl,0e2e8h		;53c5
	ld de,07b70h		;53c8   ; en el sprite 28, que no lo usa nadie mas
	ld b,004h		;53cb
	call SUBE_B_BYTES		;53cd
	ld hl,0e280h		;53d0
	res 6,(hl)		;53d3
	ret			;53d5
SE_ACABO_EL_BONUS:
	ld hl,0e2e8h		;53d6
	ld (hl),0cfh		;53d9   ; y se recoge en cuanto acaba el bonus
	ld de,07b70h		;53db
	ld b,004h		;53de
	call SUBE_B_BYTES		;53e0
	ld hl,0e081h		;53e3   ; cuantas casas lleva
	call FICHA_DEL_QUE_JUEGA		;53e6
	ld a,(hl)			;53e9
	cp 005h		;53ea   ; con las cinco casas llenas se cambia de fase
	jr nz,A_MONTAR_OTRA_FASE		;53ec
	xor a			;53ee   ; se vacian las cinco para la fase siguiente
	ld (hl),a			;53ef
	dec hl			;53f0
	ld (hl),a			;53f1
	inc hl			;53f2
	inc hl			;53f3
	inc (hl)			;53f4
	ld a,064h		;53f5   ; la fase da la vuelta al pasar de 99
	cp (hl)			;53f7
	jr nz,SUBE_EL_NUMERO		;53f8
	ld (hl),001h		;53fa
SUBE_EL_NUMERO:
	inc hl			;53fc
	inc hl			;53fd
	ld a,(hl)			;53fe   ; y el numero que se ve, en BCD, no puede quedarse en cero
	inc a			;53ff
	daa			;5400
	or a			;5401
	jr nz,GUARDA_EL_NUMERO		;5402
	inc a			;5404
GUARDA_EL_NUMERO:
	ld (hl),a			;5405   ; el numero que se ve en el marcador
	ld hl,0e083h		;5406
	call FICHA_DEL_QUE_JUEGA		;5409
	ld (hl),000h		;540c
	ld hl,05f18h		;540e   ; las dos partituras de la fase superada
	ld (0e020h),hl		;5411
	ld hl,05f5eh		;5414
	ld (0e028h),hl		;5417
	ld hl,0e043h		;541a
	set 1,(hl)		;541d
	ret			;541f
A_MONTAR_OTRA_FASE:
	ld hl,0e043h		;5420
	res 1,(hl)		;5423
	ld l,040h		;5425
	ld (hl),010h		;5427
	ret			;5429

; ----------------------------------------------------------------------
; MONTAR LA FASE. La disposicion de una fase no se guarda una por una: se elige con `(fase-1) mod 5` entre CINCO entradas de las que dos apuntan al mismo sitio, asi que trazados distintos solo hay CUATRO. Lo que separa la fase 3 de la 2 no es el trazado -es el mismo- sino dos retoques: el primer objeto de la fila de arriba pasa a ser cocodrilo y a la fila 15 se le quita un objeto. Encima van tres escalones de dificultad, en las fases 2, 6 y 11.
; ----------------------------------------------------------------------
MONTA_LA_FASE:
	ld hl,0e280h		;542a   ; limpia de 0xE280 a 0xE29F: la rana y lo que la acompana
	ld bc,00020h		;542d
	call BORRA_BC_BYTES		;5430
	ld hl,0e280h		;5433
	set 1,(hl)		;5436
	call BORRA_LOS_SPRITES		;5438
	ld hl,0e082h		;543b
	call FICHA_DEL_QUE_JUEGA		;543e
	ld a,(hl)			;5441
	inc hl			;5442
	bit 0,(hl)		;5443   ; con la fase ya montada no se vuelve a montar
	jp nz,PON_EL_TIEMPO		;5445
	set 0,(hl)		;5448
	dec a			;544a
RESTA_CINCO:
	cp 005h		;544b   ; (fase-1) mod 5, restando de cinco en cinco
	jr c,ELIGE_EL_TRAZADO		;544d
	sub 005h		;544f
	jr RESTA_CINCO		;5451
ELIGE_EL_TRAZADO:
	push af			;5453
	call BUSCA_EN_TABLA		;5454   ; y con eso, cual de los cuatro trazados

; ----------------------------------------------------------------------
; DATOS trazados_por_fase: Los cinco huecos del ciclo de fases, para el `call
;   0x57FF` de 0x5454. El segundo y el tercero apuntan a la MISMA descripcion
;   -0x5CCD-: las fases 2 y 3 llevan el mismo trazado y solo las separan los
;   retoques de 0x5497.
;   0x5457..0x5462  (11 bytes)
DATA_trazados_por_fase:
	defw 05c85h	; 5457  -> DATA_trazado_1
	defw 05ccdh	; 5459  -> DATA_trazado_2_y_3
	defw 05ccdh	; 545b  -> DATA_trazado_2_y_3
	defw 05d11h	; 545d  -> DATA_trazado_4
	defw 05d55h	; 545f  -> DATA_trazado_5
	defb 0ffh	; 5461

; ======================================================================
; CODIGO 0x5462..0x558c  (298 bytes)
; ======================================================================


MONTA_LAS_FICHAS:
	push bc			;5462   ; la descripcion empieza con la velocidad de la fila
	pop hl			;5463
	ld de,0e0b0h		;5464
OTRA_FILA:
	ld c,(hl)			;5467
	inc hl			;5468
OTRA_FICHA:
	ld b,002h		;5469
DOS_BYTES:
	ld a,(hl)			;546b   ; y despues las parejas tipo/posicion, hasta el 0xFF
	ld (de),a			;546c
	inc de			;546d
	inc hl			;546e
	djnz DOS_BYTES		;546f
	ld a,c			;5471   ; la velocidad va igual en las tres fichas de la fila
	ld (de),a			;5472
	inc de			;5473
	xor a			;5474
	ld (de),a			;5475
	inc de			;5476
	dec a			;5477   ; 0xFF cierra la fila
	cp (hl)			;5478
	jr nz,OTRA_FICHA		;5479
	inc hl			;547b
	ld a,(hl)			;547c
	cp 0ffh		;547d   ; y un 0xFF donde iria la siguiente velocidad cierra la descripcion
	jr z,LOS_RETOQUES		;547f
SALTA_EN_EL_DESTINO:
	ex de,hl			;5481   ; el byte de detras dice cuanto se avanza en las fichas: asi cada fila cae en su sitio
	call HL_MAS_A		;5482
	ex de,hl			;5485
	inc hl			;5486
	jr OTRA_FILA		;5487
LOS_RETOQUES:
	ld hl,0e0c3h		;5489   ; las dos tortugas que se hunden de salida: la primera de la fila 5 y la segunda de la fila 9. Desde la fase 6, 0x54D6 anade una tercera
	ld (hl),080h		;548c
	ld l,0ebh		;548e   ; arrancan con el contador desfasado -0x80 y 0x8A- para no hundirse a la vez
	ld (hl),08ah		;5490
	pop af			;5492
	cp 002h		;5493   ; en el tercer hueco del ciclo -fases 3, 8, 13...- y solo ahi
	jr nz,LA_DIFICULTAD		;5495
	ld hl,0e0b0h		;5497
	ld (hl),00dh		;549a   ; el primer objeto de la fila de arriba pasa a ser cocodrilo
	ld hl,0e10ch		;549c   ; y a la fila 15 se le pone el bit de "ultimo" al segundo, o sea que se queda con dos objetos en vez de tres
	set 7,(hl)		;549f
LA_DIFICULTAD:
	ld hl,0e082h		;54a1
	call FICHA_DEL_QUE_JUEGA		;54a4
	ld a,(hl)			;54a7
	cp 002h		;54a8   ; desde la fase 2: ocho objetos del rio suben dos de tipo
	push af			;54aa
	jr c,PON_LOS_RELOJES		;54ab
	ld hl,0e11ch		;54ad
	ld b,008h		;54b0
SUBE_OCHO_TIPOS:
	inc (hl)			;54b2
	inc (hl)			;54b3
	ld a,008h		;54b4
	call HL_MAS_A		;54b6
	djnz SUBE_OCHO_TIPOS		;54b9
PON_LOS_RELOJES:
	ld hl,0e0a1h		;54bb
	ld b,004h		;54be
OCHO_RELOJES:
	ld (hl),021h		;54c0
	inc hl			;54c2
	ld (hl),022h		;54c3
	inc hl			;54c5
	djnz OCHO_RELOJES		;54c6
	pop af			;54c8
	cp 006h		;54c9   ; desde la fase 6: los relojes de las filas 9 y 13 a 0x11, o sea un paso por turno
	jr c,COPIA_LAS_FICHAS_FIJAS		;54cb
DESDE_LA_FASE_6:
	push af			;54cd
	ld hl,0e0a4h		;54ce
	ld a,011h		;54d1   ; dos fichas mas en la fila de arriba
	ld (hl),a			;54d3
	inc hl			;54d4
	ld (hl),a			;54d5
	ld l,0e7h		;54d6   ; y la primera tortuga de la fila 9 empieza a hundirse tambien: es la TERCERA
	ld (hl),08fh		;54d8
	pop af			;54da
	cp 00bh		;54db   ; desde la fase 11: el bit 7 de la fila 7
	jr c,COPIA_LAS_FICHAS_FIJAS		;54dd
DESDE_LA_FASE_11:
	ld hl,0e0d4h		;54df
	set 7,(hl)		;54e2
COPIA_LAS_FICHAS_FIJAS:
	ld hl,05594h		;54e4
	ld de,0e2b2h		;54e7   ; el cocodrilo, que es fijo en todas las fases
	ld bc,00010h		;54ea
	ldir		;54ed
	ld de,0e2a1h		;54ef   ; y la rana que se rescata
	ld hl,05849h		;54f2
	ld bc,00006h		;54f5
	ldir		;54f8
	ld hl,0e049h		;54fa   ; la lista de la demo vuelve al principio en cada fase
	ld de,0584fh		;54fd
	ld (hl),d			;5500
	inc hl			;5501
	ld (hl),e			;5502
PON_EL_TIEMPO:
	ld hl,0e052h		;5503
	ld (hl),096h		;5506   ; el tiempo arranca en 0x96, y como toda la cuenta va en BCD eso son NOVENTA Y SEIS unidades, no 150: a 20 fotogramas por unidad son 32 s a 60 Hz
	ld hl,0e053h		;5508
	ld (hl),014h		;550b   ; veinte fotogramas por unidad
	inc hl			;550d
	ld (hl),003h		;550e
	inc hl			;5510
	ld b,008h		;5511
OCHO_TRAMOS:
	ld (hl),005h		;5513   ; los ocho tramos de la barra, todos al dibujo 5
	inc hl			;5515
	djnz OCHO_TRAMOS		;5516
	call PINTA_LA_BARRA		;5518
	ld de,05028h		;551b   ; la barra empieza azul; a los 0x32 se pondra roja
	ld c,040h		;551e
	ld b,020h		;5520
	call RELLENA_CON_C		;5522
	ld de,0e282h		;5525   ; la rana a su sitio: dos sprites, Y = 0xA8 y X = 0x58
	ld bc,00008h		;5528
	ld hl,0558ch		;552b
	ldir		;552e
	call PINTA_LOS_DOS_SPRITES		;5530
	ld de,0799dh		;5533
	call PON_DIRECCION_VDP		;5536
	ld hl,0e084h		;5539
	call FICHA_DEL_QUE_JUEGA		;553c
	ld b,001h		;553f
	call CIFRA_A_CIFRA		;5541   ; el numero de la fase
	ld hl,055a4h		;5544
	call PINTA_ROTULOS		;5547
	ld de,07804h		;554a
	call PON_DIRECCION_VDP		;554d
	ld b,005h		;5550   ; las cinco casas vacias, cuatro caracteres cada una
CINCO_CASAS:
	ld hl,055e1h		;5552   ; cinco casas, cuatro caracteres cada una
	push bc			;5555
	ld b,004h		;5556
	call SUBE_B_BYTES_YA		;5558   ; y van seguidas, sin volver a fijar la direccion
	pop bc			;555b
	djnz CINCO_CASAS		;555c
	ld de,07822h		;555e
	ld hl,055c4h		;5561
	ld b,016h		;5564
	call SUBE_B_BYTES		;5566
	ld hl,0e080h		;5569   ; y las ranas que ya estuvieran metidas, que se vuelven a pintar
	call FICHA_DEL_QUE_JUEGA		;556c
	ld a,(hl)			;556f
	ld de,07824h		;5570
	ld c,a			;5573
	ld b,005h		;5574
CASA_A_CASA:
	srl c		;5576   ; los cinco bits de 0xE080 van saliendo por el acarreo, empezando por la casa de la izquierda
	push bc			;5578
	jr nc,SIGUIENTE_CASA		;5579
	push de			;557b
	call PINTA_LA_RANA_EN_CASA		;557c   ; 0x52E2 acaba dejando 0xE040 a 4, y por eso 0x5587 lo tiene que volver a poner a cero
	pop de			;557f
SIGUIENTE_CASA:
	inc de			;5580   ; cuatro caracteres hasta la casa siguiente
	inc de			;5581
	inc de			;5582
	inc de			;5583
	pop bc			;5584
	djnz CASA_A_CASA		;5585
	xor a			;5587   ; 0xE040 a cero: la fase ya esta montada
	ld (0e040h),a		;5588
	ret			;558b

; ----------------------------------------------------------------------
; DATOS rana_de_salida: Las dos fichas de sprite de la rana recien puesta: Y =
;   0xA8, X = 0x58, dibujos 0x00 y 0x08, color 0x0A.
;   0x558c..0x5594  (8 bytes)
DATA_rana_de_salida:
	defb 0a8h,058h,000h,00ah	; 558c
	defb 0a8h,058h,008h,00ah	; 5590

; ----------------------------------------------------------------------
; DATOS cocodrilo: Las cuatro fichas de sprite del cocodrilo, que se copian a
;   0xE2B2: la cabeza con el dibujo 0x38 en negro y tres tramos de lomo -0x40,
;   0x44, 0x48- en rojo claro.
;   0x5594..0x55a4  (16 bytes)
DATA_cocodrilo:
	defb 018h,000h,038h,001h	; 5594
	defb 018h,000h,040h,009h	; 5598
	defb 018h,000h,044h,009h	; 559c
	defb 018h,000h,048h,009h	; 55a0

; ----------------------------------------------------------------------
; DATOS decorado: Rotulos para 0x462C: la mediana en las filas 11 y 12 -22
;   veces el caracter 3-, la orilla de abajo en las filas 21, 22 y 23 -22
;   veces el 4- y el borde de las casas en la fila 2.
;   0x55a4..0x55c4  (32 bytes)
DATA_decorado:
	defb 079h,062h,01fh,016h,003h,00fh,079h,082h,01fh,016h,003h,00fh,07ah,0a2h,01fh,016h	; 55a4  yb....y.....z...
	defb 004h,00fh,07ah,0c2h,01fh,016h,004h,00fh,07ah,0e2h,01fh,016h,004h,00fh,078h,042h	; 55b4  ..z.....z.....xB

; ----------------------------------------------------------------------
; DATOS borde_de_las_casas: Los 22 caracteres de la fila 1, la que separa las
;   casas del rio.
;   0x55c4..0x55da  (22 bytes)
DATA_borde_de_las_casas:
	defb 002h,002h,000h,000h,002h,002h,000h,000h,002h,002h,000h,000h,002h,002h,000h,000h,002h,002h,000h,000h,002h,002h	; 55c4  ......................

; ----------------------------------------------------------------------
; DATOS fin_del_decorado: La cola del rotulo anterior: el 0x0F que cierra el
;   trozo y el que cierra la lista.
;   0x55da..0x55e1  (7 bytes)
DATA_fin_del_decorado:
	defb 00fh,078h,002h,002h,002h,00fh,00fh	; 55da

; ----------------------------------------------------------------------
; DATOS casa_vacia: Los cuatro caracteres de una casa sin rana, que 0x5552
;   escribe cinco veces seguidas en la fila 0.
;   0x55e1..0x55e5  (4 bytes)
DATA_casa_vacia:
	defb 00eh,00fh,002h,002h	; 55e1

; ======================================================================
; CODIGO 0x55e5..0x5748  (355 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MOTOR DE LOS CARRILES. Ocho filas se mueven -cuatro de rio y cuatro de carretera- y no caben en un fotograma, asi que van repartidas en tres: en el primero las filas 3, 5 y 7; en el segundo las 17 y 19; y en el tercero las 9, 13 y 15. Cada fila tiene ademas su propio reloj, asi que dentro de su turno solo se mueve cuando le toca.
; ----------------------------------------------------------------------
MUEVE_LOS_CARRILES:
	ld hl,0e0a0h		;55e5
	inc (hl)			;55e8   ; tres fotogramas por vuelta
	ld a,(hl)			;55e9
	cp 003h		;55ea
	jr nz,QUE_TURNO_TOCA		;55ec
	ld (hl),000h		;55ee
QUE_TURNO_TOCA:
	ld a,(hl)			;55f0
	or a			;55f1
	jr z,TURNO_DE_ARRIBA		;55f2
	rrca			;55f4
	jr c,TURNO_DE_ENMEDIO		;55f5
	ld hl,0e0a7h		;55f7
	call LE_TOCA_A_ESTE_CARRIL		;55fa
	ld ix,0e11ch		;55fd   ; fila 17 de la pantalla
	ld iy,07a22h		;5601
	call z,FILA_A_LA_DERECHA		;5605
	ld hl,0e0a8h		;5608
	call LE_TOCA_A_ESTE_CARRIL		;560b
	ld ix,0e138h		;560e
	ld iy,07a62h		;5612   ; y fila 19
	call z,FILA_A_LA_IZQUIERDA		;5616
	ret			;5619
TURNO_DE_ARRIBA:
	ld hl,0e0a1h		;561a
	call LE_TOCA_A_ESTE_CARRIL		;561d   ; la fila 3, la de arriba del rio
	ld ix,0e0b0h		;5620   ; fila 3    C 0x5631 fila 5    C 0x5642 fila 7
	ld iy,07862h		;5624
	call z,FILA_A_LA_DERECHA_MEZCLADA		;5628
	ld hl,0e0a2h		;562b   ; la fila 5
	call LE_TOCA_A_ESTE_CARRIL		;562e
	ld ix,0e0c0h		;5631
	ld iy,078a2h		;5635
	call z,FILA_A_LA_IZQUIERDA_MEZCLADA		;5639
	ld hl,0e0a3h		;563c   ; y la fila 7
	call LE_TOCA_A_ESTE_CARRIL		;563f
	ld ix,0e0d4h		;5642
	ld iy,078e2h		;5646
	call z,FILA_A_LA_DERECHA_MEZCLADA		;564a
	ret			;564d
TURNO_DE_ENMEDIO:
	ld hl,0e0a4h		;564e
	call LE_TOCA_A_ESTE_CARRIL		;5651   ; la fila 9, la ultima del rio
	ld ix,0e0e4h		;5654   ; fila 9    C 0x5665 fila 13   C 0x5676 fila 15
	ld iy,07922h		;5658
	call z,FILA_A_LA_IZQUIERDA_MEZCLADA		;565c
	ld hl,0e0a5h		;565f
	call LE_TOCA_A_ESTE_CARRIL		;5662   ; la fila 13, la primera de asfalto
	ld ix,0e0f4h		;5665
	ld iy,079a2h		;5669
	call z,FILA_A_LA_DERECHA		;566d
	ld hl,0e0a6h		;5670
	call LE_TOCA_A_ESTE_CARRIL		;5673   ; y la fila 15
	ld ix,0e108h		;5676
	ld iy,079e2h		;567a
	call z,FILA_A_LA_IZQUIERDA		;567e
	ret			;5681

; ----------------------------------------------------------------------
; EL RELOJ DE UN CARRIL. Un solo byte para las dos cosas: el nibble de abajo cuenta y el de arriba dice cada cuanto. Al llegar el de abajo a cero se recarga con el de arriba y se devuelve Z, que es lo que autoriza a mover la fila.
; ----------------------------------------------------------------------
LE_TOCA_A_ESTE_CARRIL:
	dec (hl)			;5682
	ld a,(hl)			;5683
	and 00fh		;5684   ; mientras el nibble de abajo no llegue a cero, no toca
	ret nz			;5686
	ld a,(hl)			;5687   ; y al llegar, se recarga con el de arriba
	rrca			;5688
	rrca			;5689
	rrca			;568a
	rrca			;568b
	or (hl)			;568c
	ld (hl),a			;568d
	xor a			;568e
	ret			;568f
FILA_A_LA_DERECHA_MEZCLADA:
	ld a,001h		;5690
	jr A_LA_DERECHA_EMPIEZA		;5692
FILA_A_LA_DERECHA:
	xor a			;5694
A_LA_DERECHA_EMPIEZA:
	call LIMPIA_EL_BUFER		;5695
OBJETO_A_LA_DERECHA:
	ld a,(ix+002h)		;5698   ; la posicion avanza lo que diga la velocidad
	add a,(ix+001h)		;569b
	ld (ix+001h),a		;569e
	cp 07ch		;56a1   ; pasado 0x7C, el objeto vuelve a entrar por el 0x04
	jr c,MIRA_EL_TIPO		;56a3
	ld (ix+001h),004h		;56a5
MIRA_EL_TIPO:
	ld a,(ix+000h)		;56a9
	and 00fh		;56ac
	cp 00dh		;56ae   ; tipo 0x0D: el cocodrilo, que ademas abre y cierra la boca
	jr nz,PINTA_ESTE		;56b0
	push iy		;56b2
	call EL_COCODRILO		;56b4
	pop iy		;56b7
	call ARRASTRA_LA_RANA		;56b9
	jr MIRA_SI_ES_EL_ULTIMO		;56bc
PINTA_ESTE:
	call PINTA_UN_OBJETO		;56be
MIRA_SI_ES_EL_ULTIMO:
	bit 7,(ix+000h)		;56c1   ; bit 7: era el ultimo de la fila, asi que toca volcarla
	jp nz,VUELCA_LA_FILA		;56c5
	inc ix		;56c8
	inc ix		;56ca
	inc ix		;56cc
	inc ix		;56ce
	jr OBJETO_A_LA_DERECHA		;56d0
FILA_A_LA_IZQUIERDA_MEZCLADA:
	ld a,001h		;56d2
	jr A_LA_IZQUIERDA_EMPIEZA		;56d4
FILA_A_LA_IZQUIERDA:
	xor a			;56d6
A_LA_IZQUIERDA_EMPIEZA:
	call LIMPIA_EL_BUFER		;56d7
OBJETO_A_LA_IZQUIERDA:
	ld a,(ix+002h)		;56da
	add a,(ix+001h)		;56dd
	ld (ix+001h),a		;56e0
	cp 004h		;56e3   ; por debajo de 0x04, el objeto vuelve a entrar por el 0x7C
	jr nc,MIRA_SI_SE_HUNDE		;56e5
	ld (ix+001h),07ch		;56e7

; ----------------------------------------------------------------------
; LAS TORTUGAS QUE SE HUNDEN. Solo se aplica a los tipos 7 a 12, y solo si el cuarto byte de la ficha lleva el bit 7 puesto -que 0x5489 pone a mano en DOS fichas de toda la fase-. El contador da una vuelta de 0x80 a 0xC0, y por el camino el tipo sube uno en 0x90 y otro en 0xA0, y vuelve a bajar en 0xB0 y en 0xC0. Como el tipo es el que elige el dibujo, la tortuga se hunde y vuelve a salir sola.
; ----------------------------------------------------------------------
MIRA_SI_SE_HUNDE:
	ld a,(ix+000h)		;56eb
	and 00fh		;56ee
	cp 007h		;56f0   ; solo los tipos del 7 al 12
	jr c,PINTA_Y_SIGUE		;56f2
	cp 00dh		;56f4
	jr nc,PINTA_Y_SIGUE		;56f6
	bit 7,(ix+003h)		;56f8   ; y solo con el bit 7 del cuarto byte, que se pone a mano en 0x5489
	jr z,PINTA_Y_SIGUE		;56fc
	inc (ix+003h)		;56fe
	ld b,(ix+000h)		;5701
	ld a,(ix+003h)		;5704
	cp 090h		;5707   ; en 0x90 se hunde un paso
	jr nz,MIRA_LOS_0xA0		;5709
	inc b			;570b
MIRA_LOS_0xA0:
	cp 0a0h		;570c   ; y en 0xA0 otro: ahi esta debajo del agua
	jr nz,MIRA_LOS_0xB0		;570e
	inc b			;5710
MIRA_LOS_0xB0:
	cp 0b0h		;5711   ; en 0xB0 empieza a salir
	jr nz,MIRA_LOS_0xC0		;5713
	dec b			;5715
MIRA_LOS_0xC0:
	cp 0c0h		;5716   ; y en 0xC0 vuelve a estar entera, y el contador da la vuelta
	jr nz,GUARDA_EL_TIPO		;5718
	dec b			;571a
	ld (ix+003h),080h		;571b
GUARDA_EL_TIPO:
	ld (ix+000h),b		;571f
PINTA_Y_SIGUE:
	call PINTA_UN_OBJETO		;5722
	bit 7,(ix+000h)		;5725   ; con el bit 7 se acaba la fila
	jp nz,VUELCA_LA_FILA		;5729
	inc ix		;572c   ; y si no, cuatro bytes mas alla esta la siguiente ficha
	inc ix		;572e
	inc ix		;5730
	inc ix		;5732
	jr OBJETO_A_LA_IZQUIERDA		;5734
LIMPIA_EL_BUFER:		; Las dos filas de 40 columnas de 0xE600, con el caracter del fondo
	ld hl,0e600h		;5736
	ld b,050h		;5739
OCHENTA_BYTES:
	ld (hl),a			;573b
	inc hl			;573c
	djnz OCHENTA_BYTES		;573d
	ret			;573f
PINTA_UN_OBJETO:
	ld a,(ix+000h)		;5740   ; el nibble bajo del primer byte es el tipo
	and 00fh		;5743
	call BUSCA_EN_TABLA		;5745   ; y con el, la lista de patrones que le corresponde

; ----------------------------------------------------------------------
; DATOS listas_de_patrones: Los catorce tipos de objeto, cada uno con su lista
;   de caracteres montada en RAM al arrancar. Es la tabla del `call 0x57FF` de
;   0x5745.
;   0x5748..0x5765  (29 bytes)
DATA_listas_de_patrones:
	defw 0e300h	; 5748
	defw 0e31eh	; 574a
	defw 0e33ch	; 574c
	defw 0e362h	; 574e
	defw 0e390h	; 5750
	defw 0e3beh	; 5752
	defw 0e3fch	; 5754
	defw 0e44ah	; 5756
	defw 0e478h	; 5758
	defw 0e4a6h	; 575a
	defw 0e4d4h	; 575c
	defw 0e512h	; 575e
	defw 0e550h	; 5760
	defw 0e58eh	; 5762
	defb 0ffh	; 5764

; ======================================================================
; CODIGO 0x5765..0x57f7  (146 bytes)
; ======================================================================


VUELCA_AL_BUFER:
	ld a,(ix+001h)		;5765   ; los dos bits de abajo de la posicion eligen cual de las CUATRO versiones desplazadas -0, 2, 4 y 6 pixeles- se usa
	and 003h		;5768
	bit 0,a		;576a
	jr z,QUE_VERSION_DESPLAZADA		;576c
	xor 002h		;576e
QUE_VERSION_DESPLAZADA:
	ld l,a			;5770
	ld h,000h		;5771
	add hl,bc			;5773
	ld l,(hl)			;5774
	ld h,000h		;5775
	add hl,bc			;5777
	ld a,(ix+001h)		;5778
	rrca			;577b   ; y el resto, entre cuatro, es la columna
	rrca			;577c
	and 03fh		;577d
	ld c,a			;577f
	ld b,000h		;5780
	ex de,hl			;5782
	ld hl,0e600h		;5783
	add hl,bc			;5786
	ld bc,00028h		;5787   ; de la fila de arriba a la de abajo van 40 bytes
COLUMNA_A_COLUMNA:
	ld a,(de)			;578a
	ld (hl),a			;578b   ; el caracter de arriba
	inc de			;578c
	push hl			;578d
	add hl,bc			;578e   ; y cuarenta mas alla el de abajo
	ld a,(de)			;578f
	ld (hl),a			;5790
	pop hl			;5791
	inc hl			;5792
	inc de			;5793
	ld a,(de)			;5794
	cp 0ffh		;5795   ; el 0xFF cierra la lista del objeto
	jr nz,COLUMNA_A_COLUMNA		;5797

; ----------------------------------------------------------------------
; LA RANA VA MONTADA. Si el objeto lleva el bit 4, la rana esta encima y se la arrastra: se le suma DOS VECES la velocidad, porque la del carril va en cuartos de caracter y la de la rana en pixeles. El bit 5 hace lo mismo con la rana que se rescata.
; ----------------------------------------------------------------------
ARRASTRA_LA_RANA:
	bit 4,(ix+000h)		;5799   ; bit 4: este objeto lleva la rana encima
	jr z,ARRASTRA_LA_OTRA		;579d
	ld hl,0e280h		;579f
	bit 5,(hl)		;57a2
	jr nz,ARRASTRA_LA_OTRA		;57a4
	inc hl			;57a6
	inc hl			;57a7
	inc hl			;57a8
	ld a,(ix+002h)		;57a9
	push af			;57ac
	add a,(hl)			;57ad   ; dos veces la velocidad: de cuartos de caracter a pixeles
	ld (hl),a			;57ae
	pop af			;57af
	add a,(hl)			;57b0
	ld (hl),a			;57b1
	call PINTA_LOS_DOS_SPRITES		;57b2
ARRASTRA_LA_OTRA:
	bit 5,(ix+000h)		;57b5   ; bit 5: y este lleva la rana que se rescata
	ret z			;57b9
	ld hl,0e294h		;57ba   ; la X de la rana que se rescata
	ld a,(ix+002h)		;57bd
	push af			;57c0
	add a,(hl)			;57c1
	ld (hl),a			;57c2
	pop af			;57c3
	add a,(hl)			;57c4
	ld (hl),a			;57c5
	jp PINTA_EL_BICHO		;57c6
VUELCA_LA_FILA:
	push iy		;57c9   ; 22 columnas por fila, que es el ancho del area de juego
	pop de			;57cb
	ld hl,0e609h		;57cc
	ld b,016h		;57cf
	call SUBE_B_BYTES		;57d1   ; 22 caracteres de la fila de arriba
	push iy		;57d4
	pop de			;57d6
	ld hl,00020h		;57d7
	add hl,de			;57da
	ex de,hl			;57db
	ld hl,0e631h		;57dc   ; y los 22 de la de abajo, 32 mas alla en la VRAM
	ld b,016h		;57df
	jp SUBE_B_BYTES		;57e1
SE_ACABO_LA_PARTIDA_YA:
	ld hl,0e004h		;57e4
	ld (hl),001h		;57e7
	ld hl,0e040h		;57e9
	ld (hl),010h		;57ec
	ret			;57ee
BORRA_BC_BYTES:
	push hl			;57ef   ; DE queda en HL+1: el LDIR se copia sobre si mismo y va propagando el cero
	pop de			;57f0
	inc de			;57f1
	ld (hl),000h		;57f2
	ldir		;57f4   ; se borran BC+1 bytes, no BC; el primero lo pone el `ld (hl),000h` de arriba
	ret			;57f6

; ----------------------------------------------------------------------
; DATOS busca_en_tabla_por_bytes: Es CODIGO, y no lo llama nadie: la version
;   de esta rutina para tablas de un byte. `ex (sp),hl / ld c,a / ld b,0 / add
;   hl,bc / ld b,(hl) / jr 0x5809` deja en B el byte numero A de la tabla que
;   va detras del call y sigue en 0x5809, que es donde la version de dos bytes
;   se salta la tabla. Quedo en el cartucho sin un solo llamador.
;   0x57f7..0x57ff  (8 bytes)
DATA_busca_en_tabla_por_bytes:
	defb 0e3h,04fh,006h,000h,009h,046h,018h,00ah	; 57f7  .O...F..

; ======================================================================
; CODIGO 0x57ff..0x5838  (57 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL BUSCADOR DE TABLAS. No es un despachador que salte: coge la direccion de retorno como base de una tabla incrustada DETRAS del propio call, devuelve en BC la palabra numero A, avanza hasta el 0xFF que la cierra y hace `ret` al byte de despues. Lo usan cuatro sitios, y por eso esas cuatro tablas hay que declararlas a mano: el trazador, si no, las lee como codigo.
; ----------------------------------------------------------------------
BUSCA_EN_TABLA:
	ex (sp),hl			;57ff   ; la direccion de retorno ES la tabla
	sla a		;5800   ; palabras, asi que el indice se dobla
	ld c,a			;5802
	ld b,000h		;5803
	add hl,bc			;5805
	ld c,(hl)			;5806
	inc hl			;5807
	ld b,(hl)			;5808
HASTA_EL_0xFF:
	ld a,(hl)			;5809   ; y ahora hay que saltarse la tabla para volver detras de ella
	cp 0ffh		;580a
	inc hl			;580c   ; se avanza aunque el byte sea el 0xFF: hay que quedarse DETRAS de el
	jr nz,HASTA_EL_0xFF		;580d
	ex (sp),hl			;580f
	ret			;5810
BORRA_LOS_SPRITES:		; Y = 0xCF en los 32, que los saca de la pantalla
	ld de,07b00h		;5811
	ld b,080h		;5814
	ld c,0cfh		;5816
	call RELLENA_CON_C		;5818
	ret			;581b
CALLA_EL_SONIDO:
	push bc			;581c
	xor a			;581d
	ld (0e021h),a		;581e
	ld (0e029h),a		;5821
	ld (0e031h),a		;5824
	ld b,00ch		;5827   ; doce, porque cada vuelta se lleva tres: los dos outi y el djnz
	ld hl,05838h		;5829
PAREJA_A_PAREJA:
	ld c,0a0h		;582c   ; 0xA0 es el puerto donde se dice que registro del PSG se va a tocar
	outi		;582e   ; el outi saca el numero de registro y deja HL en el valor
	ld c,0a1h		;5830   ; 0xA1 es el puerto del dato
	outi		;5832
	djnz PAREJA_A_PAREJA		;5834
	pop bc			;5836   ; BC vuelve como estaba: 0x581C lo guardo porque el outi se come B
	ret			;5837

; ----------------------------------------------------------------------
; DATOS psg_al_silencio: Cuatro parejas registro/valor para callar el PSG: la
;   mezcla al 0xB8 y los tres volumenes a cero.
;   0x5838..0x5840  (8 bytes)
DATA_psg_al_silencio:
	defb 007h,0b8h	; 5838
	defb 008h,000h	; 583a
	defb 009h,000h	; 583c
	defb 00ah,000h	; 583e

; ======================================================================
; CODIGO 0x5840..0x5849  (9 bytes)
; ======================================================================


FICHA_DEL_QUE_JUEGA:		; Ocho bytes mas si le toca al segundo jugador
	call QUE_JUGADOR_ES		;5840
	ret z			;5843
	ld a,008h		;5844
	jp HL_MAS_A		;5846

; ----------------------------------------------------------------------
; DATOS rana_rescatable: La ficha con la que arranca la rana que hay que
;   llevar a casa: la cuenta, el paso, Y = 0xCF -escondida-, X = 0x60, dibujo
;   0x28 y color 1.
;   0x5849..0x584f  (6 bytes)
DATA_rana_rescatable:
	defb 020h,004h,0cfh,060h,028h,001h	; 5849

; ----------------------------------------------------------------------
; DATOS la_demo: LA DEMO ENTERA, en quince bytes. Uno por movimiento, con el
;   mismo formato que los mandos: 0x01 arriba, 0x08 a la derecha, 0x00 quieta.
;   La lista es 00 08 01 01 01 01 01 08 01 01 01 01 08 00 01, o sea: espera,
;   derecha, cinco veces arriba, derecha, cuatro arriba, derecha, espera y una
;   arriba. El puntero de 0xE049 vuelve aqui al montar cada fase, y como solo
;   se le incrementa el byte bajo, la lista no puede cruzar de pagina.
;   0x584f..0x585e  (15 bytes)
DATA_la_demo:
	defb 000h,008h,001h,001h,001h,001h,001h,008h,001h,001h,001h,001h,008h,000h,001h	; 584f  ...............

; ----------------------------------------------------------------------
; DATOS patrones_de_la_partida: Un bloque con cabecera para 0x4956: 112 bytes
;   a partir del caracter 2.
;   0x585e..0x58d1  (115 bytes)
DATA_patrones_de_la_partida:
	defb 060h,010h,070h,000h,000h,042h,024h,018h,010h,000h,000h,000h,0feh,0feh,0feh,000h	; 585e  `.p..B$.........
	defb 0efh,0efh,0efh,018h,010h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; 586e  ................
	defb 0ffh,0ffh,0ffh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,00fh,00fh,00fh,00fh,00fh	; 587e  ...????????.....
	defb 00fh,00fh,00fh,003h,003h,003h,003h,003h,003h,003h,003h,000h,05ah,07eh,03eh,03eh	; 588e  ............Z~>>
	defb 07eh,05ah,000h,000h,004h,00ah,00bh,007h,00eh,00dh,02bh,000h,020h,050h,0d0h,0e0h	; 589e  ~Z........+. P..
	defb 070h,0b0h,0d4h,07fh,06fh,03fh,01fh,01dh,074h,00ah,000h,0feh,0f6h,0fch,0f8h,0b8h	; 58ae  p...o?..t.......
	defb 02eh,050h,000h,001h,003h,007h,00dh,01fh,03bh,06fh,0ffh,080h,0c0h,0e0h,0b0h,0f8h	; 58be  .P......;o......
	defb 0ech,0f6h,0ffh	; 58ce

; ----------------------------------------------------------------------
; DATOS patrones_rotables: Diez juegos de caracteres, separados por un 0x11,
;   que 0x473C sube y despues corre dos bits tres veces mas. De cada uno salen
;   CUATRO versiones en la VRAM, desplazadas 0, 2, 4 y 6 pixeles, y con ellas
;   se mueven los troncos y los coches sin gastar un solo sprite.
;   0x58d1..0x59bb  (234 bytes)
DATA_patrones_rotables:
	defb 000h,00fh,000h,00fh,03ch,063h,063h,063h,000h,01eh,000h,0fch,00eh,0f2h,0f2h,0f2h	; 58d1  ....<ccc........
	defb 011h,063h,063h,063h,03ch,00fh,000h,00fh,000h,0f2h,0f2h,0f2h,00eh,0fch,000h,01eh	; 58e1  .ccc<...........
	defb 000h,011h,000h,0ffh,0ffh,0ffh,018h,0ffh,0feh,0feh,000h,003h,003h,002h,01fh,0d6h	; 58f1  ................
	defb 077h,046h,011h,0feh,0feh,0ffh,018h,0ffh,0ffh,0ffh,000h,046h,077h,0d6h,01fh,002h	; 5901  wF.........Fw...
	defb 003h,003h,000h,011h,000h,000h,003h,003h,003h,000h,00fh,038h,000h,001h,0f1h,0f1h	; 5911  ...........8....
	defb 0f1h,000h,0ffh,03fh,000h,0fch,0fch,0fch,0fch,000h,0f8h,068h,011h,038h,00fh,000h	; 5921  ...?.......h.8..
	defb 003h,003h,003h,000h,000h,03fh,0ffh,000h,0f1h,0f1h,0f1h,001h,000h,068h,0f8h,000h	; 5931  .....?.......h..
	defb 0fch,0fch,0fch,0fch,000h,011h,000h,007h,007h,000h,00fh,00fh,00fh,00fh,000h,080h	; 5941  ................
	defb 080h,000h,0ffh,0ffh,0ffh,0ffh,000h,0f0h,0f0h,000h,0fch,0fch,0fch,0fch,000h,0f0h	; 5951  ................
	defb 0f0h,000h,0fch,0fch,0fch,0fch,011h,00fh,00fh,00fh,00fh,000h,007h,007h,000h,0ffh	; 5961  ................
	defb 0ffh,0ffh,0ffh,000h,080h,080h,000h,0fch,0fch,0fch,0fch,000h,0f0h,0f0h,000h,0fch	; 5971  ................
	defb 0fch,0fch,0fch,000h,0f0h,0f0h,000h,011h,0ceh,027h,07fh,0ffh,0c3h,0ffh,0ffh,0beh	; 5981  .........'......
	defb 0cch,0e7h,0bch,0ffh,0c3h,0ffh,0ffh,0beh,0c0h,0ceh,07ch,0feh,08fh,0ffh,0fdh,0bdh	; 5991  ..........|.....
	defb 011h,0ffh,0ffh,0ffh,0ffh,0ffh,07eh,01fh,0ceh,0ffh,0ffh,0ffh,0ffh,0ffh,07eh,01fh	; 59a1  ......~.......~.
	defb 0cch,0fdh,0fdh,0ffh,0ffh,0feh,0fch,098h,0c0h,011h	; 59b1  ..........

; ----------------------------------------------------------------------
; DATOS patrones_rotables_mezclados: Cuatro juegos mas, subidos con el bit 0
;   de 0xE042 puesto: ademas de correrse, se mezclan con la capa de al lado.
;   0x59bb..0x59ff  (68 bytes)
DATA_patrones_rotables_mezclados:
	defb 010h,03ch,014h,007h,00fh,00dh,06fh,0efh,002h,00fh,00ah,0fch,0fch,0b6h,0feh,0ffh	; 59bb  .<....o.........
	defb 011h,06fh,00dh,00fh,007h,014h,03ch,020h,000h,0feh,0b6h,0fch,0fch,00ah,00fh,002h	; 59cb  .o....< ........
	defb 000h,011h,000h,006h,000h,00eh,070h,0a7h,0afh,00fh,000h,070h,000h,070h,004h,0e5h	; 59db  ......p....p.p..
	defb 0f5h,0f0h,011h,00fh,0afh,0a7h,020h,007h,000h,006h,000h,0f0h,0f5h,0e5h,004h,070h	; 59eb  ...... ........p
	defb 000h,060h,000h,011h	; 59fb

; ----------------------------------------------------------------------
; DATOS patrones_de_sprite: Veinte bloques con cabecera para 0x4956, todos a
;   la tabla de patrones de sprite. Aqui estan la rana, el cocodrilo, el bicho
;   del rio y la rana que se rescata.
;   0x59ff..0x5c34  (565 bytes)
DATA_patrones_de_sprite:
	defb 058h,002h,05ah,001h,003h,015h,037h,017h,01fh,00fh,017h,03fh,03fh,07fh,037h,013h	; 59ff  X.Z...7....??.7.
	defb 001h,000h,000h,080h,0c0h,0a8h,0ech,0e8h,0f8h,0f0h,0e8h,0fch,0fch,0feh,0ech,0c8h	; 5a0f  ................
	defb 080h,000h,010h,030h,018h,010h,010h,011h,013h,035h,037h,01fh,00fh,00fh,007h,00fh	; 5a1f  ...0.....57.....
	defb 01fh,000h,008h,00ch,018h,008h,008h,088h,0c8h,0ach,0ech,0f8h,0f0h,0f0h,0e0h,0f0h	; 5a2f  ................
	defb 0f8h,01fh,01fh,01bh,019h,018h,010h,010h,010h,010h,030h,020h,040h,000h,000h,000h	; 5a3f  ..........0 @...
	defb 000h,0f8h,0f8h,0d8h,098h,018h,008h,008h,008h,008h,00ch,004h,002h,058h,060h,03fh	; 5a4f  .............X`?
	defb 001h,013h,037h,07fh,03fh,03fh,017h,00fh,01fh,017h,037h,015h,003h,001h,000h,000h	; 5a5f  ..7.??....7.....
	defb 080h,0c8h,0ech,0feh,0fch,0fch,0e8h,0f0h,0f8h,0e8h,0ech,0a8h,0c0h,080h,000h,000h	; 5a6f  ................
	defb 01fh,00fh,007h,00fh,00fh,01fh,037h,035h,013h,011h,010h,010h,018h,030h,010h,000h	; 5a7f  ......75.....0..
	defb 0f8h,0f0h,0e0h,0f0h,0f0h,0f8h,0ech,0ach,0c8h,088h,008h,008h,018h,00ch,008h,058h	; 5a8f  ...............X
	defb 0a4h,00ch,040h,020h,030h,010h,010h,010h,010h,018h,019h,01bh,01fh,01fh,058h,0b4h	; 5a9f  ..@ 0.........X.
	defb 02bh,002h,004h,00ch,008h,008h,008h,008h,018h,098h,0d8h,0f8h,0f8h,000h,000h,008h	; 5aaf  +...............
	defb 01eh,033h,067h,00bh,01fh,01fh,00bh,067h,033h,01eh,008h,000h,000h,000h,008h,03ch	; 5abf  .3g....g3......<
	defb 07eh,038h,0fch,0feh,0ffh,0ffh,0feh,0fch,038h,07eh,03ch,008h,058h,0e2h,03ch,010h	; 5acf  ~8......8~<.X.<.
	defb 07eh,023h,00fh,017h,03fh,03fh,017h,00fh,023h,07eh,010h,000h,000h,000h,000h,001h	; 5adf  ~#..??..#~......
	defb 01fh,078h,0f0h,0f8h,0fch,0fch,0f8h,0f0h,0e8h,01fh,001h,000h,000h,000h,010h,03ch	; 5aef  .x.............<
	defb 07eh,01ch,03fh,07fh,0ffh,0ffh,07fh,03fh,01ch,07eh,03ch,010h,000h,000h,000h,010h	; 5aff  ~.?....?.~<.....
	defb 078h,0cch,0e6h,0d0h,0f8h,0f8h,0d0h,0e6h,0cch,078h,010h,059h,022h,01ch,080h,0f8h	; 5b0f  x........x.Y"...
	defb 01eh,00fh,01fh,03fh,03fh,01fh,00fh,01eh,0f8h,080h,000h,000h,000h,000h,008h,07eh	; 5b1f  ...??..........~
	defb 0c4h,0f0h,0e8h,0fch,0fch,0e8h,0f0h,0c4h,07eh,008h,059h,043h,01bh,001h,001h,001h	; 5b2f  ........~.YC....
	defb 000h,000h,006h,00eh,04bh,059h,071h,021h,000h,000h,000h,000h,0e0h,0b0h,0f8h,0f5h	; 5b3f  ....KYq!........
	defb 0c2h,060h,030h,038h,018h,038h,0f0h,0e0h,059h,063h,02bh,001h,001h,001h,000h,000h	; 5b4f  .`08.8..Yc+.....
	defb 000h,080h,081h,043h,076h,01ch,000h,000h,000h,000h,0e0h,0b0h,0fah,0f5h,0c0h,060h	; 5b5f  ...Cv..........`
	defb 03ch,00eh,086h,0c7h,06eh,03ch,000h,000h,000h,000h,007h,00dh,01fh,0afh,043h,006h	; 5b6f  <...n<........C.
	defb 00ch,01ch,018h,01ch,00fh,007h,059h,093h,01bh,080h,080h,080h,000h,000h,060h,070h	; 5b7f  ......Y.......`p
	defb 0d2h,09ah,08eh,084h,000h,000h,000h,000h,007h,00dh,05fh,0afh,003h,006h,03ch,070h	; 5b8f  .........._...<p
	defb 061h,0e3h,076h,03ch,059h,0b3h,00bh,080h,080h,080h,000h,000h,000h,001h,081h,0c2h	; 5b9f  a.v<Y...........
	defb 06eh,038h,059h,0e6h,008h,070h,0f8h,0c8h,0c8h,0ffh,0ffh,0fah,0ffh,059h,0f8h,006h	; 5baf  n8Y..p.......Y..
	defb 01ch,014h,0fch,0fch,0a8h,0fch,05ah,005h,009h,070h,0f9h,08fh,0ffh,0fch,0f0h,0e2h	; 5bbf  ......Z..p......
	defb 0ffh,0ffh,05ah,013h,00bh,00fh,01ah,07eh,0f0h,0c0h,000h,000h,000h,0aah,0ffh,0feh	; 5bcf  ..Z....~........
	defb 05ah,028h,006h,089h,0ddh,0ffh,099h,0ffh,0ffh,05ah,037h,007h,089h,0ddh,0ffh,0ffh	; 5bdf  Z(.......Z7.....
	defb 08dh,0ffh,0ffh,05ah,04bh,003h,001h,01fh,07fh,05ah,059h,00dh,009h,009h,0dfh,0ffh	; 5bef  ...ZK....ZY.....
	defb 0ffh,000h,000h,061h,092h,016h,026h,0c2h,0f1h,05ah,070h,006h,086h,049h,059h,059h	; 5bff  ...a..&..Zp..IYY
	defb 049h,086h,05ah,080h,040h,000h,001h,007h,00dh,00fh,007h,012h,00ah,004h,002h,001h	; 5c0f  I.Z.@...........
	defb 001h,002h,004h,008h,010h,000h,080h,0e0h,0b0h,0f0h,0f0h,048h,050h,020h,040h,080h	; 5c1f  ...........HP @.
	defb 080h,040h,020h,010h,008h	; 5c2f

; ----------------------------------------------------------------------
; DATOS color_de_los_sprites: Otro solape a proposito: el ultimo bloque de
;   sprites llega hasta 0x5C53, y estos dieciocho bytes son ademas las nueve
;   parejas -cuantos, que byte- que 0x43A9 usa para colorear.
;   0x5c34..0x5c46  (18 bytes)
DATA_color_de_los_sprites:
	defb 008h,000h	; 5c34
	defb 008h,044h	; 5c36
	defb 008h,043h	; 5c38
	defb 008h,080h	; 5c3a
	defb 008h,005h	; 5c3c
	defb 020h,040h	; 5c3e
	defb 008h,0a0h	; 5c40
	defb 020h,0a0h	; 5c42
	defb 010h,083h	; 5c44

; ----------------------------------------------------------------------
; DATOS caracteres_y_su_espejo: Seis grupos de nueve bytes para 0x47DA: un
;   byte de cuantos y ocho de dibujo. Cada uno se sube tal cual y despues del
;   reves, que es como salen los dibujos mirando al otro lado.
;   0x5c46..0x5c7c  (54 bytes)
DATA_caracteres_y_su_espejo:
	defb 00bh,000h,040h,000h,090h,090h,090h,090h,090h	; 5c46  ..@......
	defb 00bh,000h,0e0h,0e0h,0e0h,020h,020h,020h,020h	; 5c4f  .....    
	defb 00fh,000h,000h,0d0h,0d0h,0d0h,000h,080h,080h	; 5c58  .........
	defb 013h,000h,040h,040h,000h,0f0h,0f0h,0f0h,0f0h	; 5c61  ..@@.....
	defb 00fh,0f4h,064h,064h,064h,064h,064h,064h,064h	; 5c6a  ..ddddddd
	defb 00eh,0f4h,0f4h,0f4h,0f4h,034h,034h,034h,034h	; 5c73  .....4444

; ----------------------------------------------------------------------
; DATOS caracter_y_su_espejo: Un grupo mas, con el mismo formato.
;   0x5c7c..0x5c85  (9 bytes)
DATA_caracter_y_su_espejo:
	defb 00eh,0e4h,0e4h,0e4h,0e4h,0e4h,0e4h,0e4h,0e4h	; 5c7c  .........

; ----------------------------------------------------------------------
; DATOS trazado_1: El de las fases 1, 6, 11... Ocho filas: rio con troncos de
;   tres tamanos y tortugas, y carretera con los cuatro tipos de vehiculo.
;   Ninguna fila pasa de cuatro objetos.
;   0x5c85..0x5ccd  (72 bytes)
DATA_trazado_1:
	defb 001h,005h,004h,005h,02ch,084h,054h,0ffh,004h,0ffh,007h,024h,007h,048h,007h,068h	; 5c85  ....,.T....$.H.h
	defb 087h,088h,0ffh,004h,001h,005h,004h,004h,030h,086h,050h,0ffh,004h,0ffh,00ah,02ch	; 5c95  ........0.P....,
	defb 00ah,078h,08ah,054h,0ffh,004h,001h,003h,004h,083h,044h,0ffh,00ch,0ffh,002h,008h	; 5ca5  .x.T......D.....
	defb 002h,034h,082h,058h,0ffh,008h,001h,001h,020h,001h,04ch,081h,078h,0ffh,010h,0ffh	; 5cb5  .4.X.... .L.x...
	defb 000h,008h,000h,02ch,080h,04ch,0ffh,0ffh	; 5cc5  ...,.L..

; ----------------------------------------------------------------------
; DATOS trazado_2_y_3: Lo usan DOS huecos del ciclo, el segundo y el tercero,
;   porque la tabla de 0x5457 apunta aqui dos veces. Las fases 2 y 3 llevan
;   por tanto el mismo trazado; lo unico que las separa son los dos retoques
;   de 0x5493, que en la 3 convierten el primer objeto de la fila de arriba en
;   cocodrilo y le quitan uno a la fila 15.
;   0x5ccd..0x5d11  (68 bytes)
DATA_trazado_2_y_3:
	defb 001h,004h,03ch,086h,00ch,0ffh,008h,0ffh,007h,00ch,007h,03ch,087h,060h,0ffh,008h	; 5ccd  ..<........<.`..
	defb 001h,006h,004h,085h,040h,0ffh,008h,0ffh,00ah,024h,00ah,078h,08ah,050h,0ffh,004h	; 5cdd  ....@....$.x.P..
	defb 001h,003h,004h,003h,020h,083h,048h,0ffh,008h,0feh,002h,008h,002h,058h,082h,028h	; 5ced  .... .H......X.(
	defb 0ffh,008h,001h,001h,008h,001h,03ch,081h,064h,0ffh,010h,0ffh,000h,008h,000h,024h	; 5cfd  ......<.d......$
	defb 080h,040h,0ffh,0ffh	; 5d0d

; ----------------------------------------------------------------------
; DATOS trazado_4: El de las fases 4, 9, 14... Ya trae un cocodrilo de serie
;   -tipo 0x0D- y la fila 15 va a velocidad -3, la mas rapida de las cuatro
;   descripciones.
;   0x5d11..0x5d55  (68 bytes)
DATA_trazado_4:
	defb 001h,005h,00ch,0cdh,04ch,0ffh,008h,0feh,007h,018h,007h,044h,087h,070h,0ffh,008h	; 5d11  ....L......D.p..
	defb 002h,006h,010h,085h,058h,0ffh,008h,0ffh,00ah,018h,08ah,058h,0ffh,008h,001h,003h	; 5d21  ....X......X....
	defb 004h,003h,020h,083h,044h,0ffh,008h,0fdh,002h,014h,002h,044h,082h,060h,0ffh,008h	; 5d31  .. .D......D.`..
	defb 001h,001h,008h,001h,024h,001h,034h,081h,058h,0ffh,00ch,0feh,000h,008h,000h,038h	; 5d41  ....$.4.X......8
	defb 080h,058h,0ffh,0ffh	; 5d51

; ----------------------------------------------------------------------
; DATOS trazado_5: El de las fases 5, 10, 15... La fila de arriba se queda con
;   UN SOLO objeto, y es el cocodrilo.
;   0x5d55..0x5d97  (66 bytes)
DATA_trazado_5:
	defb 001h,0cdh,04ch,0ffh,00ch,0feh,007h,018h,007h,044h,087h,070h,0ffh,008h,002h,006h	; 5d55  ..L......D.p....
	defb 010h,085h,058h,0ffh,008h,0ffh,00ah,018h,08ah,058h,0ffh,008h,001h,003h,004h,003h	; 5d65  ..X......X......
	defb 020h,083h,044h,0ffh,008h,0fdh,002h,014h,002h,028h,082h,060h,0ffh,008h,001h,001h	; 5d75   .D......(.`....
	defb 008h,001h,034h,081h,058h,0ffh,010h,0feh,000h,008h,000h,020h,000h,038h,080h,058h	; 5d85  ..4.X...... .8.X
	defb 0ffh,0ffh	; 5d95

; ----------------------------------------------------------------------
; DATOS musica_de_arranque_1: 27 notas. La melodia con la que empieza la
;   partida, en el canal 1.
;   0x5d97..0x5de9  (82 bytes)
DATA_musica_de_arranque_1:
	defb 0feh,0b0h,08ch	; 5d97
	defb 040h,0b1h,08ch	; 5d9a
	defb 040h,0b1h,08ch	; 5d9d
	defb 040h,0b1h,08ch	; 5da0
	defb 0feh,0b0h,08ch	; 5da3
	defb 040h,0b1h,08ch	; 5da6
	defb 040h,0b1h,08ch	; 5da9
	defb 040h,0b1h,08ch	; 5dac
	defb 0f0h,0b0h,08ch	; 5daf
	defb 0f0h,0b0h,08ch	; 5db2
	defb 0feh,0b0h,08ch	; 5db5
	defb 0feh,0b0h,08ch	; 5db8
	defb 01dh,0b1h,098h	; 5dbb
	defb 000h,000h,018h	; 5dbe
	defb 0f0h,0b0h,08ch	; 5dc1
	defb 0f0h,0b0h,08ch	; 5dc4
	defb 0feh,0b0h,08ch	; 5dc7
	defb 0feh,0b0h,08ch	; 5dca
	defb 01dh,0b1h,08ch	; 5dcd
	defb 01dh,0b1h,08ch	; 5dd0
	defb 0beh,0b0h,08ch	; 5dd3
	defb 0beh,0b0h,08ch	; 5dd6
	defb 0d6h,0b0h,08ch	; 5dd9
	defb 0f0h,0b0h,08ch	; 5ddc
	defb 0feh,0b0h,08ch	; 5ddf
	defb 01dh,0b1h,08ah	; 5de2
	defb 040h,0b1h,098h	; 5de5
	defb 0ffh	; 5de8

; ----------------------------------------------------------------------
; DATOS musica_de_arranque_2: 29 notas, el canal 2 de esa misma melodia.
;   0x5de9..0x5e41  (88 bytes)
DATA_musica_de_arranque_2:
	defb 081h,0b2h,08ch	; 5de9
	defb 0fdh,0b1h,08ch	; 5dec
	defb 057h,0b3h,08ch	; 5def
	defb 0fdh,0b1h,08ch	; 5df2
	defb 081h,0b3h,08ch	; 5df5
	defb 0fdh,0b1h,08ch	; 5df8
	defb 057h,0b3h,08ch	; 5dfb
	defb 0fdh,0b1h,08ch	; 5dfe
	defb 03bh,0b2h,08ch	; 5e01
	defb 0e0h,0b1h,08ch	; 5e04
	defb 057h,0b3h,08ch	; 5e07
	defb 0e0h,0b1h,08ch	; 5e0a
	defb 03bh,0b2h,08ch	; 5e0d
	defb 0e0h,0b1h,08ch	; 5e10
	defb 057h,0b3h,08ch	; 5e13
	defb 0e0h,0b1h,08ch	; 5e16
	defb 03bh,0b2h,08ch	; 5e19
	defb 0e0h,0b1h,08ch	; 5e1c
	defb 057h,0b3h,08ch	; 5e1f
	defb 0e0h,0b1h,08ch	; 5e22
	defb 03bh,0b2h,08ch	; 5e25
	defb 0e0h,0b1h,08ch	; 5e28
	defb 057h,0b3h,08ch	; 5e2b
	defb 0e0h,0b1h,08ch	; 5e2e
	defb 03bh,0b2h,08ch	; 5e31
	defb 0e0h,0b1h,08ch	; 5e34
	defb 057h,0b3h,08ch	; 5e37
	defb 0e0h,0b1h,08ch	; 5e3a
	defb 0fdh,0b1h,098h	; 5e3d
	defb 0ffh	; 5e40

; ----------------------------------------------------------------------
; DATOS musica_de_arranque_3: 29 notas, el canal 3.
;   0x5e41..0x5e99  (88 bytes)
DATA_musica_de_arranque_3:
	defb 081h,0b2h,08ch	; 5e41
	defb 0a7h,0b2h,08ch	; 5e44
	defb 057h,0b3h,08ch	; 5e47
	defb 0a7h,0b2h,08ch	; 5e4a
	defb 081h,0b2h,08ch	; 5e4d
	defb 0a7h,0b2h,08ch	; 5e50
	defb 057h,0b3h,08ch	; 5e53
	defb 0a7h,0b2h,08ch	; 5e56
	defb 03bh,0b2h,08ch	; 5e59
	defb 03bh,0b2h,08ch	; 5e5c
	defb 057h,0b3h,08ch	; 5e5f
	defb 03bh,0b2h,08ch	; 5e62
	defb 03bh,0b2h,08ch	; 5e65
	defb 03bh,0b2h,08ch	; 5e68
	defb 057h,0b3h,08ch	; 5e6b
	defb 03bh,0b2h,08ch	; 5e6e
	defb 03bh,0b2h,08ch	; 5e71
	defb 03bh,0b2h,08ch	; 5e74
	defb 057h,0b3h,08ch	; 5e77
	defb 03bh,0b2h,08ch	; 5e7a
	defb 03bh,0b2h,08ch	; 5e7d
	defb 03bh,0b2h,08ch	; 5e80
	defb 057h,0b3h,08ch	; 5e83
	defb 03bh,0b2h,08ch	; 5e86
	defb 03bh,0b2h,08ch	; 5e89
	defb 03bh,0b2h,08ch	; 5e8c
	defb 057h,0b3h,08ch	; 5e8f
	defb 03bh,0b2h,08ch	; 5e92
	defb 081h,0b2h,098h	; 5e95
	defb 0ffh	; 5e98

; ----------------------------------------------------------------------
; DATOS musica_de_la_muerte: 13 notas, en el canal 3.
;   0x5e99..0x5ec1  (40 bytes)
DATA_musica_de_la_muerte:
	defb 080h,0c0h,001h	; 5e99
	defb 070h,0c0h,001h	; 5e9c
	defb 060h,0c0h,001h	; 5e9f
	defb 050h,0c0h,001h	; 5ea2
	defb 080h,0c0h,002h	; 5ea5
	defb 0e0h,0c0h,002h	; 5ea8
	defb 040h,0c1h,002h	; 5eab
	defb 0a0h,0c1h,002h	; 5eae
	defb 000h,0c2h,002h	; 5eb1
	defb 060h,0c2h,002h	; 5eb4
	defb 0c0h,0c2h,002h	; 5eb7
	defb 010h,0c3h,002h	; 5eba
	defb 070h,0c3h,004h	; 5ebd
	defb 0ffh	; 5ec0

; ----------------------------------------------------------------------
; DATOS aviso_de_tiempo: 6 notas. Suena una sola vez, cuando al reloj le
;   quedan 0x32; en ese mismo momento el caracter de la barra se pone rojo.
;   0x5ec1..0x5ed4  (19 bytes)
DATA_aviso_de_tiempo:
	defb 0bdh,0c0h,014h	; 5ec1
	defb 077h,0c0h,014h	; 5ec4
	defb 0bdh,0c0h,014h	; 5ec7
	defb 077h,0c0h,014h	; 5eca
	defb 0bdh,0c0h,014h	; 5ecd
	defb 077h,0c0h,014h	; 5ed0
	defb 0ffh	; 5ed3

; ----------------------------------------------------------------------
; DATOS sonido_de_vida_extra: 2 notas.
;   0x5ed4..0x5edb  (7 bytes)
DATA_sonido_de_vida_extra:
	defb 06bh,0d0h,003h	; 5ed4
	defb 07fh,0d0h,003h	; 5ed7
	defb 0ffh	; 5eda

; ----------------------------------------------------------------------
; DATOS tic_del_bonus: Una sola nota, la que suena por cada unidad de tiempo
;   que se cobra al llegar a casa.
;   0x5edb..0x5edf  (4 bytes)
DATA_tic_del_bonus:
	defb 0efh,0c0h,085h	; 5edb
	defb 0ffh	; 5ede

; ----------------------------------------------------------------------
; DATOS sonido_de_coger_el_bicho: 2 notas.
;   0x5edf..0x5ee6  (7 bytes)
DATA_sonido_de_coger_el_bicho:
	defb 0efh,0c0h,00ah	; 5edf
	defb 0efh,0c0h,00ah	; 5ee2
	defb 0ffh	; 5ee5

; ----------------------------------------------------------------------
; DATOS sonido_del_salto: 3 notas. La que mas veces suena de todo el cartucho.
;   0x5ee6..0x5ef0  (10 bytes)
DATA_sonido_del_salto:
	defb 07bh,0b0h,005h	; 5ee6
	defb 0a9h,0b0h,005h	; 5ee9
	defb 0d0h,0b0h,005h	; 5eec
	defb 0ffh	; 5eef

; ----------------------------------------------------------------------
; DATOS musica_de_la_partida: 13 notas en el canal 2. Es la que suena todo el
;   rato mientras se juega: 0x5144 la vuelve a poner cada vez que baja el
;   reloj, pero solo si el canal ya se ha callado, asi que se encadena sola.
;   0x5ef0..0x5f18  (40 bytes)
DATA_musica_de_la_partida:
	defb 080h,09ah,007h	; 5ef0
	defb 078h,0aah,007h	; 5ef3
	defb 098h,0bah,007h	; 5ef6
	defb 088h,0cah,007h	; 5ef9
	defb 074h,0cah,007h	; 5efc
	defb 098h,0bah,007h	; 5eff
	defb 094h,0aah,007h	; 5f02
	defb 083h,08ah,007h	; 5f05
	defb 07ah,06ah,007h	; 5f08
	defb 080h,05ah,007h	; 5f0b
	defb 084h,04ah,007h	; 5f0e
	defb 08ch,03ah,007h	; 5f11
	defb 078h,03ah,007h	; 5f14
	defb 0ffh	; 5f17

; ----------------------------------------------------------------------
; DATOS musica_de_fase_superada_1: 23 notas, canal 1.
;   0x5f18..0x5f5e  (70 bytes)
DATA_musica_de_fase_superada_1:
	defb 040h,0b1h,08ah	; 5f18
	defb 01dh,0b1h,08ah	; 5f1b
	defb 0feh,0b0h,08ah	; 5f1e
	defb 0f0h,0b0h,08ah	; 5f21
	defb 0d6h,0b0h,094h	; 5f24
	defb 0feh,0b0h,094h	; 5f27
	defb 040h,0b1h,08ah	; 5f2a
	defb 01dh,0b1h,08ah	; 5f2d
	defb 0feh,0b0h,08ah	; 5f30
	defb 01dh,0b1h,08ah	; 5f33
	defb 040h,0b1h,094h	; 5f36
	defb 040h,0b1h,094h	; 5f39
	defb 040h,0b1h,08ah	; 5f3c
	defb 01dh,0b1h,08ah	; 5f3f
	defb 0feh,0b0h,08ah	; 5f42
	defb 0f0h,0b0h,08ah	; 5f45
	defb 0d6h,0b0h,094h	; 5f48
	defb 0feh,0b0h,094h	; 5f4b
	defb 0d6h,0b0h,08ah	; 5f4e
	defb 0f0h,0b0h,08ah	; 5f51
	defb 0feh,0b0h,08ah	; 5f54
	defb 01dh,0b1h,08ah	; 5f57
	defb 040h,0b1h,0a8h	; 5f5a
	defb 0ffh	; 5f5d

; ----------------------------------------------------------------------
; DATOS musica_de_fase_superada_2: 29 notas, canal 2.
;   0x5f5e..0x5fb6  (88 bytes)
DATA_musica_de_fase_superada_2:
	defb 0fdh,0b1h,08ah	; 5f5e
	defb 0ach,0b1h,08ah	; 5f61
	defb 0fdh,0b1h,08ah	; 5f64
	defb 0ach,0b1h,08ah	; 5f67
	defb 0fdh,0b1h,08ah	; 5f6a
	defb 0ach,0b1h,08ah	; 5f6d
	defb 0fdh,0b1h,08ah	; 5f70
	defb 0ach,0b1h,08ah	; 5f73
	defb 0fdh,0b1h,08ah	; 5f76
	defb 0ach,0b1h,08ah	; 5f79
	defb 0fdh,0b1h,08ah	; 5f7c
	defb 0ach,0b1h,08ah	; 5f7f
	defb 0fdh,0b1h,08ah	; 5f82
	defb 0ach,0b1h,08ah	; 5f85
	defb 0fdh,0b1h,08ah	; 5f88
	defb 0ach,0b1h,08ah	; 5f8b
	defb 0fdh,0b1h,08ah	; 5f8e
	defb 0ach,0b1h,08ah	; 5f91
	defb 0fdh,0b1h,08ah	; 5f94
	defb 0ach,0b1h,08ah	; 5f97
	defb 0fdh,0b1h,08ah	; 5f9a
	defb 0ach,0b1h,08ah	; 5f9d
	defb 0fdh,0b1h,08ah	; 5fa0
	defb 0ach,0b1h,08ah	; 5fa3
	defb 0e0h,0b1h,08ah	; 5fa6
	defb 0ach,0b1h,08ah	; 5fa9
	defb 0fdh,0b1h,08ah	; 5fac
	defb 0ach,0b1h,08ah	; 5faf
	defb 0fdh,0b1h,0a8h	; 5fb2
	defb 0ffh	; 5fb5

; ----------------------------------------------------------------------
; DATOS musica_del_final_1: 11 notas, canal 1.
;   0x5fb6..0x5fd8  (34 bytes)
DATA_musica_del_final_1:
	defb 0d6h,0b0h,08ah	; 5fb6
	defb 0beh,0b0h,08ah	; 5fb9
	defb 0aah,0b0h,094h	; 5fbc
	defb 08fh,0b0h,094h	; 5fbf
	defb 08fh,0b0h,08ah	; 5fc2
	defb 0aah,0b0h,08ah	; 5fc5
	defb 0d6h,0b0h,08ah	; 5fc8
	defb 0beh,0b0h,08ah	; 5fcb
	defb 0aah,0b0h,094h	; 5fce
	defb 01dh,0b1h,094h	; 5fd1
	defb 0d6h,0b0h,094h	; 5fd4
	defb 0ffh	; 5fd7

; ----------------------------------------------------------------------
; DATOS musica_del_final_2: 8 notas, canal 2. El programa principal se queda
;   mirando este canal hasta que se calla, y solo entonces vuelve al titulo.
;   0x5fd8..0x5ff1  (25 bytes)
DATA_musica_del_final_2:
	defb 000h,000h,094h	; 5fd8
	defb 0a7h,0a2h,094h	; 5fdb
	defb 03bh,0a2h,094h	; 5fde
	defb 0b3h,0a2h,094h	; 5fe1
	defb 0a7h,0a2h,094h	; 5fe4
	defb 03bh,0a2h,094h	; 5fe7
	defb 0a7h,0a2h,094h	; 5fea
	defb 057h,0a3h,094h	; 5fed
	defb 0ffh	; 5ff0

; ----------------------------------------------------------------------
; DATOS relleno: Los quince bytes que sobran al final del cartucho, todos a
;   0xFF.
;   0x5ff1..0x6000  (15 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 5ff1  ...............
