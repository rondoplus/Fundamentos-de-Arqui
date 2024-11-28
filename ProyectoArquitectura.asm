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
  
    la $a0, menu           # Imprimir el menú
    li $v0, 4
    syscall

    li $v0, 5             
    syscall
    move $t0, $v0          

    # Verificacion
    li $t1, 1              # Opción 1: Codificar
    beq $t0, $t1, codificar
    li $t1, 2              # Opción 2: Decodificar
    beq $t0, $t1, decodificar
    li $t1, 3              # Opción 3: Salir
    beq $t0, $t1, CerrarPrograma

    # Opción inválida
    la $a0, Invalida
    li $v0, 4
    syscall
    j BucleMenu

#######################################

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
    addi $t5, $t5, -1  # Decrementa correctamente
    bgtz $t5, cargarBloques_Loop
    jal resetDisplay    # Llamar a la función de reinicio del display

    j end

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
    sw $t0, 0($t7)           # Escribir el color en el framebuffer
    addiu $t7, $t7, 4
    bne $t7, $t8, rectangleXLoop

    addiu $t4, $t4, 2048     # Mover a la siguiente fila (512 píxeles * 4 bytes por píxel)
    subi $t6, $t6, 1
    bgtz $t6, rectangleYLoop

    jr $ra                    # Retornar
    
    
codificar:
    # Leer el texto del usuario
    la $a0, Mensaje       # Imprimir mensaje de entrada
    li $v0, 4
    syscall

    la $a0, Espacio        # Dirección del Espacio de texto
    li $v0, 8             # Leer string
    li $a1, 100           # Longitud máxima
    syscall

    # Leer la clave de cifrado
    
    la $a0, Clave    # Imprimir mensaje de entrada de clave
    li $v0, 4
    syscall

    li $v0, 5             # Leer entero (clave)
    syscall
    move $t1, $v0         # Almacenar la clave en $t1

    # Codificar el texto
    
    la $a0, TextoCodificado   # Mensaje: Texto codificado
    li $v0, 4
    syscall

    la $a0, Espacio        # Dirección del texto original
    la $a1, SalidaEspacio # Dirección del texto codificado
    jal CodificarA            # Llamar a la función CodificarA

    # Imprimir texto codificado
    j cuadrado

decodificar:
    # Leer el texto codificado
    
    la $a0, TextoCodificado_dos # Mensaje: Ingresa texto a decodificar
    li $v0, 4
    syscall

    la $a0, Espacio        # Leer el texto codificado
    li $v0, 8
    li $a1, 100
    syscall

    # Leer la clave para decodificar
    
    la $a0, TextoParaDecodificar # Mensaje: Ingresa clave para decodificar
    li $v0, 4
    syscall

    li $v0, 5             # Leer entero (clave de decodificación)
    syscall
    move $t1, $v0         # Almacenar la clave en $t1

    # Decodificar el texto
    
    la $a0, TextoDecodificado   # Mensaje: Texto decodificado
    li $v0, 4
    syscall

    la $a0, Espacio        # Dirección del texto codificado
    la $a1, SalidaEspacio # Dirección del texto decodificado
    neg $t1, $t1          # Invertir clave para decodificar
    jal CodificarA            # Llamar a la función CodificarA

    # Imprimir texto decodificado
    
    j cuadrado



CodificarA:
    li $t2, 0             # Índice (contador)
CodificarA_Bucle:
    lb $t3, 0($a0)        # Leer un byte del texto original
    beqz $t3, CodificarA_done # Si es null, termina el loop
    addi $a0, $a0, 1      # Avanzar al siguiente byte

    # Aplicar cifrado solo a caracteres alfabéticos
    
    li $t4, 65            # 'A'
    li $t5, 90            # 'Z'
    li $t6, 97            # 'a'
    li $t7, 122           # 'z'

    # Mayúsculas
    
    bge $t3, $t4, Verificar1
    j Guardar_Caracter
Verificar1:
    ble $t3, $t5, CodificarA_1
    j Verificar2
CodificarA_1:
    sub $t3, $t3, $t4     # Normalizar a rango 0-25
    add $t3, $t3, $t1     # Aplicar desplazamiento
    rem $t3, $t3, 26      # Asegurar rango (circular)
    add $t3, $t3, $t4     # Volver al rango ASCII
    j Guardar_Caracter

    # Minúsculas
    
Verificar2:
    bge $t3, $t6, Verificar2_Rango
    j Guardar_Caracter
Verificar2_Rango:
    ble $t3, $t7, CodificarA_2
    j Guardar_Caracter
CodificarA_2:
    sub $t3, $t3, $t6     # Normalizar a rango 0-25
    add $t3, $t3, $t1     # Aplicar desplazamiento
    rem $t3, $t3, 26      # Asegurar rango (circular)
    add $t3, $t3, $t6     # Volver al rango ASCII

Guardar_Caracter:
    sb $t3, 0($a1)        # Almacenar el carácter en el texto codificado
    addi $a1, $a1, 1      # Avanzar al siguiente byte
    j CodificarA_Bucle

CodificarA_done:
    sb $zero, 0($a1)      # Agregar terminador muy
    jr $ra                # Retornar    
cuadrado:
    # Configuración inicial
    li $a1, 20               # Ancho de cada bloque
    li $a3, 20               # Altura de los bloques
    lw $t0, color            # Cargar color blanco

    # Posición inicial de la barra
    li $t1, 400              # Límite derecho
    mul $t2, $a1, 10         # Ancho total de los bloques
    sub $t2, $t1, $t2
    srl $a0, $t2, 1          # Centrar
    li $a2, 180              # Posición vertical

    li $t5, 10               # Contador de bloques
    jal cargarBloques_Loop
# Subrutina para resetear el display (llenar framebuffer con un color)
resetDisplay:
    la $t0, frameBuffer     # Dirección base del framebuffer
    li $t1, 0x80000         # Tamaño del framebuffer (512 x 256 x 4 bytes)
    lw $t2, negro           # Color de reinicio (negro)

resetLoop:
    sw $t2, 0($t0)          # Escribir color en la dirección actual
    addiu $t0, $t0, 4       # Avanzar al siguiente píxel (4 bytes por píxel)
    subi $t1, $t1, 4        # Reducir el contador
    bgtz $t1, resetLoop     # Repetir hasta que se llene todo el framebuffer

    jr $ra                  # Retornar
   
CerrarPrograma:
    # Salir del programa
    
    li $v0, 10
    syscall
end:
    # Salir del programa+    
    la $a0, SalidaEspacio
    li $v0, 4
    syscall
    j BucleMenu        # Volver al menú

