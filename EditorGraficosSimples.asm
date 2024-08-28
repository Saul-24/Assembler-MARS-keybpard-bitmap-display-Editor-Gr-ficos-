############################################################
#            Editor de gráficos simples                    #
# USA "W" ARRIBA, "S" ABAJO, "D" DERECHA, "A" IZQUIERDA    #
# CAMBIA COLOR CON LOS NUMEROS:				   #
# 							   #
#  1=AZUL                                                  #
#  2=ROJO                                                  #
#  3=VERDE                                                 #
#  4=AMARILLO                                              #
#  DEFAULT=AZUL                                            #
#                                                          #
############################################################


#####################################################################################
#			Bitmap Display y Keyboard simulator MMOI                    #
# Unit width     : 1				                                    #
# Unit height    : 2				                                    #
# Display width  : 512					                            #
# Display height : 256					                            #
# Base address for display  : 0x100100000 (static data)				    #	
# Keyboard: 0xffff004							            #
#####################################################################################


.data
BUFFER: .space 524288       # Espacio para el buffer de pantalla 512*256*4,  4=bytes
cursor_x: .word 0           # Posición X inicial del cursor; declaramos variables para almacenar la posiciones del cursor inicia en 0 (estara en la esquina superior izquierda del display) 
cursor_y: .word 0           # Posición Y inicial del cursor
color:    .word 0x0000FF    # Color inicial (azul)

.text
.globl main

main:
    # Inicializar el buffer de la pantalla (opcional si el Bitmap Display está limpio)
    la $s0, BUFFER
    li $t0, 524288
    li $t1, 0x00000000  # Color negro
    li $t2, 0  #inicializa $t2 en 0 este sera el contador

Iniciar_buffer:
    sw $t1, 0($s0)   # en $t1 esta el color nego que lo va apuntar $s0 que es la posicion buffer 
    addi $s0, $s0, 4 # estara incrementando en 4 avanzado al siguiente pixel (cada pixel ocupa 4 bytes) 
    addi $t2, $t2, 4
    blt $t2, $t0, Iniciar_buffer # maneja el tamano del buffer, si es menor que 524288 regresa a Iniciar_bufer que continua llenando

# Bucle principal del programa
Loop_prg:
    lw $t0, 0xffff0004  # Leer entrada del tecladdo (Keyboard MMOI simulator)
    li $t1, 0x1b        # Código ASCII de ESC
    beq $t0, $t1, FinLoop_prg # basicamente compara si se presiono esc para salir, terminando el bucle

    # cambio de dirección
    li $t1, 'w'   # Carga el valor de ASCII de las teclas y los guarda en $t1
    beq $t0, $t1, Mover_arriba # compara si se presiono una tecla y salta a la direccion de movimiento 
    li $t1, 'a'
    beq $t0, $t1, Mover_izquierda
    li $t1, 's'
    beq $t0, $t1, Mover_abajo
    li $t1, 'd'
    beq $t0, $t1, Mover_derecha

    # Cambiar color: lo mismo que arriba solo que con los colores :)
    li $t1, '1'
    beq $t0, $t1, Azul
    li $t1, '2'
    beq $t0, $t1, Rojo
    li $t1, '3'
    beq $t0, $t1, Verde
    li $t1, '4'
    beq $t0, $t1, Amarillo

    j Loop_prg

# Estas son las subrutinas para cambiar el color 
Azul:
    li $t2, 0x0000FF 
    sw $t2, color
    j Loop_prg

Rojo:
    li $t2, 0xFF0000
    sw $t2, color
    j Loop_prg

Verde:
    li $t2, 0x00FF00
    sw $t2, color
    j Loop_prg

Amarillo:
    li $t2, 0xFFFF00
    sw $t2, color
    j Loop_prg

# Movimientos del cursor
# Notita: Imagina que estas viendo un plano cartesiano con x -x y -y
# Movimiento hacia arriba
Mover_arriba:
    lw $t3, cursor_y # carga el valor del cursor_y en $t3
    addi $t3, $t3, -1 # y va restando -1 si el cursor va hacia arriba
    bgez $t3, Valida_Y_Arriba #comprobacion si es mayor o igual que 0 salta a validar 
    li $t3, 0 # si es menor que 0 lo establece en 0 para que no se salga de los limites superiores del display
Valida_Y_Arriba:
    sw $t3, cursor_y #lo que sucede es que guarda el valor de $t3 en el cursor_y 
    j Actualiza_cursor #y y aqui un salto para empezar a dibujar y actualizar las direcciones de movimiento

# Misma dinamica para los demas movimientos
# Movimiento hacia la izquierda
Mover_izquierda:
    lw $t3, cursor_x
    addi $t3, $t3, -1
    bgez $t3, Validar_X_Izquierda
    li $t3, 0
Validar_X_Izquierda:
    sw $t3, cursor_x
    j Actualiza_cursor

# Movimiento hacia abajo
Mover_abajo:
    lw $t3, cursor_y
    addi $t3, $t3, 1
    li $t4, 255
    ble $t3, $t4, Validar_Y_Abajo
    li $t3, 255
Validar_Y_Abajo:
    sw $t3, cursor_y
    j Actualiza_cursor

# Movimiento hacia la derecha
Mover_derecha:
    lw $t3, cursor_x
    addi $t3, $t3, 1
    li $t4, 511
    ble $t3, $t4, Validar_x_Derecha
    li $t3, 511
Validar_x_Derecha:
    sw $t3, cursor_x
    j Actualiza_cursor

# Actualizar cursor y dibujar
Actualiza_cursor:
    lw $t3, cursor_x
    lw $t4, cursor_y
    lw $t5, color

    # Calcular la dirección en el buffer
    li $t7, 512          # Ancho de la pantalla en píxeles
    mul $t8, $t4, $t7    # Y * Ancho calcula la fila de la pantalla
    add $t8, $t8, $t3    # X + (Y * Ancho) calcula el buffer
    sll $t8, $t8, 2      # Multiplicar por 4 para obtener el offset en bytes convierte la posicion de pixeles en bytes

    la $t9, BUFFER       # Dirección base del buffer
    add $t9, $t9, $t8    # Dirección final en el buffer

    sw $t5, 0($t9)       # Dibujar el pixel

    # Añadir un retraso para hacer el movimiento más lento
    li $t6, 9900       # Ajusta este valor para controlar la velocidad mas alto dibuja mas lento mas bajo dibuja mas rapido 
demora_loop:
    addi $t6, $t6, -1   # el valor que ajustas ira decrementando en 1
    bnez $t6, demora_loop #comparativa si no es 0 te lleva a demora_loop para crear el retraso

    j Loop_prg 

FinLoop_prg:

# Finalizar el programa
FinPrograma:
    li $v0, 10
    syscall
