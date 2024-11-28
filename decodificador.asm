.data
frameBuffer: .space 0x80000        # Espacio para la pantalla (512 x 256, 4 bytes por píxel)
color: .word 0xFFFFFFFF            # Color rojo para los bloques
negro: .word 0x00000000            # Color negro para limpiar
menu: .asciiz "Selecciona una opción:\n1. Codificar\n2. Decodificar\n3. Salir\nOpción: "
Invalida: .asciiz "Opción no válida. Intenta de nuevo.\n"
Mensaje: .asciiz "Ingresa el texto a codificar: "
Clave: .asciiz "Ingresa el desplazamiento (clave): "
TextoCodificado: .asciiz "Texto codificado: "
TextoCodificado_dos: .asciiz "Ingresa el texto codificado a decodificar: "
TextoParaDecodificar: .asciiz "Ingresa la clave para decodificar: "
TextoDecodificado: .asciiz "Texto decodificado: "
Espacio: .space 100                # Espacio para almacenar el texto
SalidaEspacio: .space 100          # Espacio para el texto codificado o decodificado
newline: .asciiz "\n"

.text
main:
BucleMenu:
    # Imprimir el menú
    la $a0, menu
    li $v0, 4
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    # Verificar opción seleccionada
    li $t1, 1
    beq $t0, $t1, codificar
    li $t1, 2
    beq $t0, $t1, decodificar
    li $t1, 3
    beq $t0, $t1, CerrarPrograma

    # Opción inválida
    la $a0, Invalida
    li $v0, 4
    syscall
    j BucleMenu

codificar:
    # Leer el texto del usuario
    la $a0, Mensaje
    li $v0, 4
    syscall

    la $a0, Espacio
    li $v0, 8
    li $a1, 100
    syscall

    # Leer la clave
    la $a0, Clave
    li $v0, 4
    syscall

    li $v0, 5
    syscall
    move $t1, $v0

    # Dibujar la barra de carga
    jal cargarBloques

    # Codificar el texto
    la $a0, Espacio
    la $a1, SalidaEspacio
    jal CodificarA

    # Imprimir texto codificado
    la $a0, TextoCodificado
    li $v0, 4
    syscall

    la $a0, SalidaEspacio
    li $v0, 4
    syscall

    j BucleMenu

decodificar:
    # Leer el texto codificado
    la $a0, TextoCodificado_dos
    li $v0, 4
    syscall

    la $a0, Espacio
    li $v0, 8
    li $a1, 100
    syscall

    # Leer la clave
    la $a0, TextoParaDecodificar
    li $v0, 4
    syscall

    li $v0, 5
    syscall
    move $t1, $v0
    neg $t1, $t1

    # Dibujar la barra de carga
    jal cargarBloques

    # Decodificar el texto
    la $a0, Espacio
    la $a1, SalidaEspacio
    jal CodificarA

    # Imprimir texto decodificado
    la $a0, TextoDecodificado
    li $v0, 4
    syscall

    la $a0, SalidaEspacio
    li $v0, 4
    syscall

    j BucleMenu

CerrarPrograma:
    # Salir del programa
    li $v0, 10
    syscall

# Función para dibujar la barra de carga
cargarBloques:
    li $a1, 20               # Ancho de cada bloque
    li $a3, 20               # Altura de los bloques
    lw $t0, color            # Cargar color rojo

    # Posición inicial de la barra
    li $t1, 400              # Límite derecho
    mul $t2, $a1, 10         # Ancho total de los bloques
    sub $t2, $t1, $t2
    srl $a0, $t2, 1          # Centrar
    li $a2, 180              # Posición vertical

    li $t5, 10               # Contador de bloques

cargarBloques_Loop:
    # Dibujar un bloque
    jal rectangle

    # Delay entre bloques
    li $v0, 32
    li $t3, 500000
    syscall

    # Mover al siguiente bloque
    addi $a0, $a0, 30

    # Reducir contador de bloques y verificar
    subi $t5, $t5, 1
    bgtz $t5, cargarBloques_Loop

    jr $ra                   # Retornar al programa principal

# Subrutina para dibujar un bloque
rectangle:
    move $t6, $a3            # Altura del bloque

    sll $t1, $a0, 2          # Escalar X
    sll $t2, $a1, 2          # Escalar ancho
    sll $t3, $a2, 9          # Escalar Y

    la $t4, frameBuffer
    addu $t4, $t4, $t3
    addu $t4, $t4, $t1

rectangleYLoop:
    move $t7, $t4
    add $t8, $t4, $t2

rectangleXLoop:
    sw $t0, 0($t7)
    addiu $t7, $t7, 4
    bne $t7, $t8, rectangleXLoop

    addiu $t4, $t4, 2048
    subi $t6, $t6, 1
    bgtz $t6, rectangleYLoop

    jr $ra

# Codificación y decodificación
CodificarA:
    li $t2, 0
CodificarA_Bucle:
    lb $t3, 0($a0)
    beqz $t3, CodificarA_done
    addi $a0, $a0, 1

    li $t4, 65
    li $t5, 90
    li $t6, 97
    li $t7, 122

    bge $t3, $t4, Verificar1
    j Guardar_Caracter
Verificar1:
    ble $t3, $t5, CodificarA_1
    j Verificar2
CodificarA_1:
    sub $t3, $t3, $t4
    add $t3, $t3, $t1
    rem $t3, $t3, 26
    add $t3, $t3, $t4
    j Guardar_Caracter

Verificar2:
    bge $t3, $t6, Verificar2_Rango
    j Guardar_Caracter
Verificar2_Rango:
    ble $t3, $t7, CodificarA_2
    j Guardar_Caracter
CodificarA_2:
    sub $t3, $t3, $t6
    add $t3, $t3, $t1
    rem $t3, $t3, 26
    add $t3, $t3, $t6

Guardar_Caracter:
    sb $t3, 0($a1)
    addi $a1, $a1, 1
    j CodificarA_Bucle

CodificarA_done:
    sb $zero, 0($a1)
    jr $ra