# =============================================================================
#
#   mortups.ps1  —  v1.0
#   Minecraft 1.12.2 Server Manager for Windows
#   Gestor de servidor Minecraft 1.12.2 para Windows
#
#   Created by / Creado por: mortamc
#
#   WHAT IT DOES / QUE HACE:
#     · Starts the server with configurable RAM
#       Inicia el servidor con la RAM configurada
#     · Creates automatic .7z backups on a timer
#       Crea backups .7z automáticos según un intervalo de tiempo
#     · Deletes backups older than a configurable number of days
#       Borra backups más viejos que la cantidad de días configurada
#     · Listens to in-game chat for commands (any player or ops-only, configurable)
#       Escucha el chat del juego para ejecutar comandos (todos o solo ops, configurable)
#     · Automatically restarts the server after a restore
#       Reinicia el servidor automáticamente después de una restauración
#
#   IN-GAME COMMANDS / COMANDOS EN EL JUEGO:
#     !backup [name]   — Creates a manual backup with an optional custom name
#                        Crea un backup manual con nombre personalizado opcional
#     !backups         — Lists available backups in chat
#                        Lista los backups disponibles en el chat
#     !restore <file>  — Restores the server from a backup file and restarts
#                        Restaura el servidor desde un backup y lo reinicia
#
#   REQUIREMENTS / REQUISITOS:
#     · Java in system PATH (or full path configured below)
#       Java en el PATH del sistema (o ruta completa configurada abajo)
#     · 7-Zip installed (https://7-zip.org)
#       7-Zip instalado
#     · RCON enabled in server.properties:
#       RCON habilitado en server.properties:
#         enable-rcon=true
#         rcon.port=25575
#         rcon.password=yourpassword
#
#   EDIT ONLY THE "CONFIGURATION" SECTION BELOW.
#   EDITA SOLO LA SECCIÓN "CONFIGURACIÓN" DE ABAJO.
#
# =============================================================================

# Suppress non-critical errors so the script doesn't stop on minor issues.
# Suprime errores no críticos para que el script no se detenga por problemas menores.
Set-StrictMode -Off
$ErrorActionPreference = "SilentlyContinue"


# =============================================================================
# ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗ ██╗   ██╗██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
#██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝ ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
#██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗██║   ██║██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║
#██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║██║   ██║██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
#╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝╚██████╔╝██║  ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
# ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
#   Edit only this section — Solo editá esta sección
# =============================================================================


# -----------------------------------------------------------------------------
#  SERVER / SERVIDOR
# -----------------------------------------------------------------------------

# Full path to the server folder (NOT the .jar file, just the folder).
# Ruta completa a la carpeta del servidor (NO el archivo .jar, solo la carpeta).
$ServerDir = ""

# Name of the server's .jar file.
# Nombre del archivo .jar del servidor.
$ServerJar = "server.jar"

# Path to the server's log file. Minecraft writes everything here in real time
# (chat messages, connections, errors). The manager reads this file to detect
# in-game commands. Do NOT change this unless your server uses a custom log path.
# Ruta al archivo de log del servidor. Minecraft escribe todo aquí en tiempo real
# (mensajes del chat, conexiones, errores). El manager lee este archivo para detectar
# comandos del juego. NO cambies esto a menos que tu servidor use una ruta de log personalizada.
$LogFile = "$ServerDir\logs\latest.log"

# Path to Java. If Java is in the system PATH, "java" is enough.
# Ruta a Java. Si Java está en el PATH del sistema, con "java" alcanza.
# Example / Ejemplo: "C:\Program Files\Eclipse Adoptium\jdk-8.0.392.8-hotspot\bin\java.exe"
$JavaExe = "java"

# Maximum RAM assigned to the server (in GB).
# RAM máxima asignada al servidor (en GB).
$MaxRamGB = 4

# Minimum RAM reserved on startup (in GB).
# Keeping it equal to MaxRamGB prevents Java from requesting more RAM mid-game (more stable).
# RAM mínima reservada al inicio (en GB).
# Mantenerla igual a MaxRamGB evita que Java pida más RAM durante el juego (más estable).
$MinRamGB = 4

# Seconds the manager waits after launching the server before starting to monitor it.
# Forge 1.12.2 with many mods can take 60–120 seconds to load. Adjust for your machine.
# Segundos que el manager espera después de lanzar el servidor antes de empezar a monitorearlo.
# Forge 1.12.2 con muchos mods puede tardar 60–120 segundos en cargar. Ajustá según tu PC.
$ServerStartupWaitSec = 40


# -----------------------------------------------------------------------------
#  BACKUPS
# -----------------------------------------------------------------------------

# Folder where backup files will be stored.
# You can use a different drive, e.g.: "D:\MinecraftBackups"
# Carpeta donde se almacenarán los archivos de backup.
# Podés usar otra unidad, ej: "D:\MinecraftBackups"
$BackupDir = "$ServerDir\backups"

# Minutes between each automatic backup.
# Minutos entre cada backup automático.
$BackupIntervalMin = 30

# How many days to keep backups before they are automatically deleted.
# Example: 3 = backups older than 3 days are deleted after each new backup.
# Cuántos días conservar los backups antes de que se borren automáticamente.
# Ejemplo: 3 = los backups de más de 3 días se borran después de cada backup nuevo.
$BackupRetentionDays = 3

# Create an automatic backup when the server STARTS (before the first 30-min timer).
# Crear un backup automático cuando el servidor ARRANCA (antes del primer timer de 30 min).
# $true = yes/sí  |  $false = no
$BackupOnServerStart = $false

# 7-Zip compression level (1 = fastest, least compressed / 9 = slowest, most compressed).
# Level 5 is a good balance for servers with many mods.
# Nivel de compresión de 7-Zip (1 = más rápido, menos comprimido / 9 = más lento, más comprimido).
# Nivel 5 es un buen equilibrio para servidores con muchos mods.
$CompressionLevel = 5

# Number of CPU threads 7-Zip will use for compression.
# More threads = faster compression, but higher CPU usage while the server is running.
# Número de hilos del CPU que usará 7-Zip para comprimir.
# Más hilos = compresión más rápida, pero mayor uso de CPU mientras el servidor corre.
$CompressionThreads = 2

# Folders and files to EXCLUDE from the backup (not needed for a restore).
# Use 7-Zip format: "-xr!foldername"
# Carpetas y archivos a EXCLUIR del backup (no son necesarios para restaurar).
# Usar formato 7-Zip: "-xr!nombrecarpeta"
$BackupExclusions = @(
    "-xr!backups",        # The backup folder itself — avoids infinite recursion
                          # La propia carpeta de backups — evita recursión infinita
    "-xr!logs",           # Server logs — regenerated automatically
                          # Logs del servidor — se regeneran solos
    "-xr!crash-reports",  # Crash reports — not needed for restore
                          # Reportes de crash — no son necesarios para restaurar
    "-xr!*.lck"           # Java temporary lock files
                          # Archivos de bloqueo temporales de Java
)

# Seconds the manager waits after "save-all" before compressing.
# Large servers with many loaded chunks may need more time (8–10 seconds).
# Segundos que el manager espera después del "save-all" antes de comprimir.
# Servidores grandes con muchos chunks cargados pueden necesitar más tiempo (8–10 segundos).
$SaveAllWaitSec = 5


# -----------------------------------------------------------------------------
#  RCON
#  RCON is the protocol the script uses to send commands to the server (save, say, stop, etc.)
#  RCON es el protocolo que usa el script para enviar comandos al servidor (save, say, stop, etc.)
#  It must be enabled in server.properties:
#  Debe estar habilitado en server.properties:
#    enable-rcon=true
#    rcon.port=25575
#    rcon.password=yourpassword
# -----------------------------------------------------------------------------

# Server IP for RCON. 127.0.0.1 = this same machine.
# IP del servidor para RCON. 127.0.0.1 = esta misma PC.
$RconHost = "127.0.0.1"

# RCON port (must match rcon.port in server.properties).
# Puerto RCON (debe coincidir con rcon.port en server.properties).
$RconPort = 25575

# RCON password (must match rcon.password in server.properties).
# Contraseña RCON (debe coincidir con rcon.password en server.properties).
$RconPass = "yourpassword"


# -----------------------------------------------------------------------------
#  COMMAND PERMISSIONS / PERMISOS DE COMANDOS
# -----------------------------------------------------------------------------

# Who can use in-game commands? / ¿Quién puede usar los comandos en el juego?
# Options / Opciones:
#   "everyone"  — Any connected player / Cualquier jugador conectado
#   "ops"       — Only players listed in ops.json / Solo jugadores en ops.json
#   "whitelist" — Only players listed in $AllowedPlayers below / Solo los jugadores en $AllowedPlayers abajo
$CommandPermission = "everyone"

# Players allowed to use commands when $CommandPermission = "whitelist".
# Names are case-insensitive.
# Jugadores con permiso cuando $CommandPermission = "whitelist".
# Los nombres no distinguen mayúsculas/minúsculas.
$AllowedPlayers = @("mortamc", "otroplayer")

# Enable or disable each command individually.
# Habilitar o deshabilitar cada comando individualmente.
# $true = enabled/habilitado  |  $false = disabled/deshabilitado

# !backup [name] — Creates a manual backup / Crea un backup manual
$EnableBackupCommand  = $true

# !backups — Lists available backups / Lista los backups disponibles
$EnableBackupsCommand = $true

# !restore <file> — Restores a backup and restarts the server
#                   WARNING: This STOPS and RESTARTS the server.
#                   Disable it if you don't want players to trigger restores.
# !restore <archivo> — Restaura un backup y reinicia el servidor
#                      ATENCIÓN: Esto PARA y REINICIA el servidor.
#                      Deshabilitalo si no querés que los jugadores puedan hacer restores.
$EnableRestoreCommand = $true

# Maximum number of backups shown when a player types !backups.
# Keeps the chat from being flooded on servers with many backups.
# Cantidad máxima de backups mostrados cuando alguien escribe !backups.
# Evita inundar el chat en servidores con muchos backups.
$MaxBackupsShownInChat = 6

# Seconds of countdown shown in-game before a restore begins.
# Gives players time to finish what they're doing.
# Segundos de cuenta regresiva mostrados en el juego antes de que comience un restore.
# Le da tiempo a los jugadores para terminar lo que están haciendo.
$RestoreCountdownSec = 15


# -----------------------------------------------------------------------------
#  7-ZIP
# -----------------------------------------------------------------------------

# Paths where 7-Zip is searched automatically (64-bit and 32-bit installations).
# Add your custom path here if you installed it elsewhere.
# Rutas donde se busca 7-Zip automáticamente (instalaciones de 64 y 32 bits).
# Agregá tu ruta personalizada si lo instalaste en otro lugar.
$SevenZipSearchPaths = @(
    "C:\Program Files\7-Zip\7z.exe",
    "C:\Program Files (x86)\7-Zip\7z.exe"
)


# =============================================================================
#  END OF CONFIGURATION — Do not edit below this line unless you know what you're doing.
#  FIN DE CONFIGURACIÓN — No edites debajo de esta línea a menos que sepas lo que hacés.
# =============================================================================


# Locate 7-Zip by checking all configured paths.
# Localiza 7-Zip revisando todas las rutas configuradas.
$SevenZipExe = $SevenZipSearchPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

# Build Java arguments using the configured RAM values.
# Construye los argumentos de Java usando los valores de RAM configurados.
$JavaArgs = @("-Xmx${MaxRamGB}G", "-Xms${MinRamGB}G", "-jar", $ServerJar, "nogui")

# The § character (section sign) is used for Minecraft color codes in chat messages.
# It's defined this way instead of typed directly because PowerShell may mis-encode it
# when sending over TCP/RCON depending on the console's code page.
# [char]0x00A7 always produces the correct byte regardless of the console encoding.
#
# El carácter § (signo de sección) se usa para los códigos de color de Minecraft en el chat.
# Se define así en vez de escribirlo directamente porque PowerShell puede codificarlo mal
# al enviarlo por TCP/RCON dependiendo de la página de código de la consola.
# [char]0x00A7 siempre produce el byte correcto independientemente del encoding de la consola.
$S = [char]0x00A7


# =============================================================================
#  FUNCTION: Write-Log
#  Prints a timestamped, colored, tagged message to the console.
#  Imprime un mensaje con hora, color y etiqueta en la consola.
#
#  Parameters / Parámetros:
#    $Msg   — The message to display / El mensaje a mostrar
#    $Color — Console color (Green, Red, Cyan, Yellow, DarkGray, Magenta...)
#             Color de consola
#    $Tag   — Label shown in brackets: [INFO], [BACKUP], [RESTORE], etc.
#             Etiqueta mostrada entre corchetes
# =============================================================================
function Write-Log {
    param(
        [string]$Msg,
        [string]$Color = "White",
        [string]$Tag   = "INFO"
    )
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts][$Tag] $Msg"
}


# =============================================================================
#  FUNCTION: New-RconPacket
#  Builds a binary packet following the Source RCON Protocol specification.
#  Construye un paquete binario según la especificación del protocolo Source RCON.
#
#  How RCON works / Cómo funciona RCON:
#    1. Open a TCP connection to the server.
#       Abrir una conexión TCP al servidor.
#    2. Send a Type-3 packet (login) containing the password.
#       Enviar un paquete Tipo 3 (login) con la contraseña.
#    3. If authentication succeeds, send Type-2 packets (commands).
#       Si la autenticación es correcta, enviar paquetes Tipo 2 (comandos).
#
#  Packet structure / Estructura del paquete:
#    [4 bytes: length] [4 bytes: request ID] [4 bytes: type] [N bytes: body] [2 null bytes]
#    [4 bytes: largo]  [4 bytes: ID request] [4 bytes: tipo] [N bytes: cuerpo] [2 bytes nulos]
#
#  Parameters / Parámetros:
#    $ReqId — Arbitrary packet identifier / Identificador arbitrario del paquete
#    $Type  — 3 = login/auth, 2 = command / 3 = login/auth, 2 = comando
#    $Body  — Password or command string / Contraseña o comando
# =============================================================================
function New-RconPacket {
    param([int]$ReqId, [int]$Type, [string]$Body)

    $bodyBytes  = [System.Text.Encoding]::UTF8.GetBytes($Body)
    # Packet payload = 4 (ID) + 4 (type) + body length + 2 null terminators
    # Payload del paquete = 4 (ID) + 4 (tipo) + largo del cuerpo + 2 terminadores nulos
    $packetSize = 4 + 4 + $bodyBytes.Length + 2
    # Total buffer = 4 bytes for the length field + packet payload
    # Buffer total = 4 bytes del campo de largo + payload del paquete
    $buf        = New-Object byte[] (4 + $packetSize)

    # All integers are little-endian (least significant byte first).
    # Todos los enteros son little-endian (byte menos significativo primero).
    [BitConverter]::GetBytes([int32]$packetSize).CopyTo($buf, 0)   # Length field / Campo de largo
    [BitConverter]::GetBytes([int32]$ReqId).CopyTo($buf, 4)        # Request ID
    [BitConverter]::GetBytes([int32]$Type).CopyTo($buf, 8)         # Packet type / Tipo de paquete
    if ($bodyBytes.Length -gt 0) { $bodyBytes.CopyTo($buf, 12) }   # Body / Cuerpo
    # Final 2 bytes remain 0 automatically (null terminators).
    # Los últimos 2 bytes quedan en 0 automáticamente (terminadores nulos).
    return $buf
}


# =============================================================================
#  FUNCTION: Invoke-Rcon
#  Sends a command to the Minecraft server via RCON and returns the response.
#  Returns $null silently if the server is unreachable (e.g., still starting up).
#
#  Envía un comando al servidor Minecraft via RCON y devuelve la respuesta.
#  Devuelve $null en silencio si el servidor no está disponible (ej: aún iniciando).
#
#  Parameters / Parámetros:
#    $Command — The Minecraft command to run (e.g. "say Hello!", "save-all", "stop")
#               El comando de Minecraft a ejecutar (ej: "say Hola!", "save-all", "stop")
# =============================================================================
function Invoke-Rcon {
    param([string]$Command)
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ReceiveTimeout = 3000   # 3-second timeout for receiving data / 3 segundos de timeout para recibir
        $tcp.SendTimeout    = 3000   # 3-second timeout for sending data   / 3 segundos de timeout para enviar
        $tcp.Connect($RconHost, $RconPort)
        $stream = $tcp.GetStream()

        # Step 1: Authenticate (Type 3 packet with password)
        # Paso 1: Autenticación (paquete Tipo 3 con contraseña)
        $authPkt = New-RconPacket -ReqId 1 -Type 3 -Body $RconPass
        $stream.Write($authPkt, 0, $authPkt.Length)
        $buf = New-Object byte[] 4096
        $stream.Read($buf, 0, 4096) | Out-Null   # Discard auth response / Descarta respuesta de auth

        # Step 2: Send the command (Type 2 packet)
        # Paso 2: Enviar el comando (paquete Tipo 2)
        $cmdPkt = New-RconPacket -ReqId 2 -Type 2 -Body $Command
        $stream.Write($cmdPkt, 0, $cmdPkt.Length)
        Start-Sleep -Milliseconds 200   # Give the server time to process / Da tiempo al servidor de procesar

        # Read response. Useful payload starts at byte 12 (after the 12-byte header).
        # Leer respuesta. El payload útil empieza en el byte 12 (tras el header de 12 bytes).
        $n    = $stream.Read($buf, 0, 4096)
        $resp = ""
        if ($n -gt 12) {
            $resp = [System.Text.Encoding]::UTF8.GetString($buf, 12, [Math]::Max(0, $n - 14))
        }

        $tcp.Close()
        return $resp.Trim()
    } catch {
        # Fail silently — the server may be starting up or shutting down.
        # Falla en silencio — el servidor puede estar iniciando o apagándose.
        return $null
    }
}


# =============================================================================
#  FUNCTION: Test-PlayerAllowed
#  Checks whether a player has permission to use commands,
#  based on the $CommandPermission configuration variable.
#
#  Verifica si un jugador tiene permiso para usar comandos,
#  según la variable de configuración $CommandPermission.
#
#  Parameters / Parámetros:
#    $PlayerName — The player's username / El nombre de usuario del jugador
#
#  Returns / Devuelve:
#    $true  — Player is allowed  / El jugador tiene permiso
#    $false — Player is not allowed / El jugador no tiene permiso
# =============================================================================
function Test-PlayerAllowed {
    param([string]$PlayerName)

    switch ($CommandPermission.ToLower()) {

        "everyone" {
            # All players are allowed.
            # Todos los jugadores están permitidos.
            return $true
        }

        "ops" {
            # Only players listed in ops.json (set as OP by a server admin).
            # Solo jugadores listados en ops.json (puestos como OP por un admin).
            $opsFile = "$ServerDir\ops.json"
            if (-not (Test-Path $opsFile)) {
                Write-Log "ops.json not found. Denying permission to $PlayerName." "Yellow" "PERM"
                return $false
            }
            try {
                $ops = Get-Content $opsFile -Raw | ConvertFrom-Json
                # Case-insensitive name comparison / Comparación de nombre sin distinguir mayúsculas
                return ($ops | Where-Object { $_.name -ieq $PlayerName }).Count -gt 0
            } catch {
                Write-Log "Failed to read ops.json." "Red" "PERM"
                return $false
            }
        }

        "whitelist" {
            # Only players explicitly listed in $AllowedPlayers.
            # Solo jugadores listados explícitamente en $AllowedPlayers.
            # -icontains = case-insensitive contains / -icontains = contains sin distinguir mayúsculas
            return $AllowedPlayers -icontains $PlayerName
        }

        default {
            Write-Log "Unknown CommandPermission value: '$CommandPermission'. Defaulting to 'everyone'." "Yellow" "PERM"
            return $true
        }
    }
}


# =============================================================================
#  FUNCTION: New-Backup
#  Creates a compressed .7z backup of the entire server folder.
#  Crea un backup comprimido .7z de toda la carpeta del servidor.
#
#  The save-off / compress / save-on sequence ensures the world files are
#  not modified by the server while 7-Zip is reading them, preventing corruption.
#
#  La secuencia save-off / comprimir / save-on garantiza que los archivos del mundo
#  no sean modificados por el servidor mientras 7-Zip los lee, evitando corrupción.
#
#  Parameters / Parámetros:
#    $Type       — "auto", "manual", "startup", or "pre-restore"
#                  "auto", "manual", "inicio", o "pre-restore"
#    $CustomName — Optional custom label included in the filename
#                  Etiqueta personalizada opcional incluida en el nombre de archivo
# =============================================================================
function New-Backup {
    param(
        [string]$Type       = "auto",
        [string]$CustomName = ""
    )

    # Create backup directory if it doesn't exist yet.
    # Crea la carpeta de backups si todavía no existe.
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    # Timestamp without seconds: 2026-03-14_06-17
    # Marca de tiempo sin segundos: 2026-03-14_06-17
    $stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"

    # Build the filename.
    # Without custom name: backup_auto_2026-03-14_06-17.7z
    # With custom name:    backup_manual_my-event_2026-03-14_06-17.7z
    # Construir el nombre de archivo.
    # Sin nombre custom:   backup_auto_2026-03-14_06-17.7z
    # Con nombre custom:   backup_manual_mi-evento_2026-03-14_06-17.7z
    if ($CustomName -ne "") {
        # Sanitize the custom name: replace characters invalid in Windows filenames with underscores.
        # Sanitizar el nombre custom: reemplazar caracteres inválidos en nombres de archivo de Windows con guiones bajos.
        $safeName = ($CustomName.Trim()) -replace '[\\/:*?"<>|]', '_'
        $fileName = "backup_${Type}_${safeName}_${stamp}.7z"
    } else {
        $fileName = "backup_${Type}_${stamp}.7z"
    }

    $destPath = "$BackupDir\$fileName"

    Write-Log "Starting backup ($Type): $fileName" "Cyan" "BACKUP"

    # Notify players in-game. Build the chat label based on whether a custom name was given.
    # Notifica a los jugadores en el juego. Construye la etiqueta del chat según si hay nombre custom.
    $chatLabel = if ($CustomName -ne "") { "${S}b$CustomName ${S}7(${Type})" } else { "${S}b${Type}" }
    Invoke-Rcon "say ${S}e[${S}6Backup${S}e] ${S}7Starting backup: $chatLabel${S}7..." | Out-Null

    # Save all chunks to disk now. This flushes any pending chunk data.
    # Guarda todos los chunks al disco ahora. Esto escribe cualquier dato pendiente.
    Invoke-Rcon "save-all" | Out-Null

    # Disable auto-save so world files stay static while 7-Zip is reading them.
    # Desactiva el autoguardado para que los archivos del mundo queden quietos mientras 7-Zip los lee.
    Invoke-Rcon "save-off" | Out-Null

    # Wait for the disk to finish writing.
    # Espera a que el disco termine de escribir.
    Start-Sleep -Seconds $SaveAllWaitSec

    # Run 7-Zip with all configured parameters.
    # Ejecuta 7-Zip con todos los parámetros configurados.
    #   a        — Add to archive (create) / Agregar al archivo (crear)
    #   -t7z     — Use .7z format / Usar formato .7z
    #   -mx=N    — Compression level / Nivel de compresión
    #   -mmt=N   — Number of CPU threads / Número de hilos del CPU
    #   $destPath — Output archive path / Ruta del archivo de salida
    #   "$ServerDir\*" — Everything inside the server folder / Todo dentro de la carpeta del servidor
    $zipArgs = @("a", "-t7z", "-mx=$CompressionLevel", "-mmt=$CompressionThreads",
                 $destPath, "$ServerDir\*") + $BackupExclusions
    & $SevenZipExe @zipArgs 2>&1 | Out-Null

    # Re-enable auto-save.
    # Reactiva el autoguardado.
    Invoke-Rcon "save-on" | Out-Null

    # Verify that the archive was actually created.
    # Verifica que el archivo fue creado correctamente.
    if (Test-Path $destPath) {
        $sizeMB = [Math]::Round((Get-Item $destPath).Length / 1MB, 2)
        Write-Log "Backup complete: $fileName ($sizeMB MB)" "Green" "BACKUP"
        Invoke-Rcon "say ${S}a[${S}2Backup${S}a] ${S}fDone! ${S}e$fileName ${S}7(${sizeMB} MB)" | Out-Null
    } else {
        # 7-Zip failed to create the archive. This usually means a path or permissions issue.
        # 7-Zip falló al crear el archivo. Esto generalmente indica un problema de ruta o permisos.
        Write-Log "ERROR: Backup failed. Check 7-Zip output." "Red" "BACKUP"
        Invoke-Rcon "say ${S}c[${S}4Backup${S}c] ${S}fBackup failed! Check the server console." | Out-Null
    }

    # Clean up old backups after every backup operation.
    # Limpia los backups viejos después de cada operación de backup.
    Remove-OldBackups

    return $fileName
}


# =============================================================================
#  FUNCTION: Remove-OldBackups
#  Deletes .7z backup files older than $BackupRetentionDays days.
#  Automatically called after every backup.
#
#  Elimina archivos de backup .7z más viejos que $BackupRetentionDays días.
#  Se llama automáticamente después de cada backup.
# =============================================================================
function Remove-OldBackups {
    # Calculate the cutoff date. Files older than this will be removed.
    # Calcula la fecha límite. Los archivos anteriores a esta fecha se borrarán.
    $cutoff = (Get-Date).AddDays(-$BackupRetentionDays)

    $old = Get-ChildItem "$BackupDir\*.7z" -ErrorAction SilentlyContinue |
           Where-Object { $_.LastWriteTime -lt $cutoff }

    foreach ($f in $old) {
        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
        Write-Log "Deleted old backup (>$BackupRetentionDays days): $($f.Name)" "DarkGray" "BACKUP"
    }
}


# =============================================================================
#  FUNCTION: Get-BackupList
#  Returns all available .7z backups sorted newest-first.
#  Devuelve todos los backups .7z disponibles ordenados del más nuevo al más viejo.
# =============================================================================
function Get-BackupList {
    return Get-ChildItem "$BackupDir\*.7z" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending
}


# =============================================================================
#  FUNCTION: Invoke-Restore
#  Restores the server from a .7z backup file.
#  Restaura el servidor desde un archivo de backup .7z.
#
#  Process / Proceso:
#    1. Validate the backup file exists / Valida que el archivo de backup existe
#    2. Countdown in-game chat          / Cuenta regresiva en el chat del juego
#    3. Save a pre-restore snapshot     / Guarda un snapshot pre-restauración
#    4. Stop the server cleanly via RCON/ Para el servidor limpiamente via RCON
#    5. Delete current world folders   / Borra las carpetas del mundo actual
#    6. Extract the backup             / Extrae el backup
#    7. The outer loop restarts the server automatically
#       El bucle externo reinicia el servidor automáticamente
#
#  Parameters / Parámetros:
#    $BackupName — Filename of the .7z to restore / Nombre del archivo .7z a restaurar
#    $Process    — The Java process object (needed to wait for it to stop)
#                  El objeto del proceso Java (necesario para esperar a que se cierre)
#
#  Returns / Devuelve:
#    $true  — Restore succeeded, server was stopped / Restauración exitosa, servidor detenido
#    $false — Backup file not found / Archivo de backup no encontrado
# =============================================================================
function Invoke-Restore {
    param(
        [string]$BackupName,
        [System.Diagnostics.Process]$Process
    )

    $backupPath = "$BackupDir\$BackupName"

    # Validate that the requested backup file actually exists.
    # Valida que el archivo de backup solicitado realmente existe.
    if (-not (Test-Path $backupPath)) {
        Write-Log "Backup not found: $BackupName" "Red" "RESTORE"
        Invoke-Rcon "say ${S}c[${S}4Restore${S}c] ${S}fFile not found: ${S}e$BackupName" | Out-Null
        Invoke-Rcon "say ${S}c[Restore] ${S}fUse ${S}e!backups ${S}fto see available backups." | Out-Null
        return $false
    }

    Write-Log "Restore initiated: $BackupName — starting countdown..." "Yellow" "RESTORE"

    # Countdown in-game chat, giving players time to save their progress.
    # Cuenta regresiva en el chat del juego, dando tiempo a los jugadores para guardar su progreso.
    $countdownSteps = @($RestoreCountdownSec)
    # Build meaningful countdown steps (every 5 seconds, then every second for the last 5).
    # Construye pasos de cuenta regresiva significativos.
    if ($RestoreCountdownSec -ge 30) { $countdownSteps += 20 }
    if ($RestoreCountdownSec -ge 20) { $countdownSteps += 10 }
    if ($RestoreCountdownSec -ge 10) { $countdownSteps += 5  }
    $countdownSteps += @(4, 3, 2, 1)
    $countdownSteps = $countdownSteps | Sort-Object -Descending -Unique

    $prevStep = $RestoreCountdownSec + 1
    foreach ($step in $countdownSteps) {
        Invoke-Rcon "say ${S}c[${S}4Restore${S}c] ${S}fServer restarting in ${S}e${step}s ${S}fto restore: ${S}b$BackupName" | Out-Null
        $waitSec = $prevStep - $step
        if ($waitSec -gt 0) { Start-Sleep -Seconds $waitSec }
        $prevStep = $step
    }
    Start-Sleep -Seconds 1   # Final pause before stopping / Pausa final antes de detener

    Invoke-Rcon "say ${S}c[Restore] ${S}fSaving and shutting down..." | Out-Null
    Invoke-Rcon "save-all" | Out-Null
    Start-Sleep -Seconds 3

    # Pre-restore snapshot: saves the CURRENT world BEFORE deleting anything.
    # This is a safety net — if the restore goes wrong, this snapshot can recover the previous state.
    # Snapshot pre-restauración: guarda el mundo ACTUAL ANTES de borrar nada.
    # Es una red de seguridad — si algo sale mal en el restore, este snapshot puede recuperar el estado previo.
    $snapName = "backup_pre-restore_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').7z"
    Write-Log "Saving pre-restore snapshot: $snapName" "Cyan" "RESTORE"
    & $SevenZipExe a -t7z -mx=1 -mmt=$CompressionThreads `
        "$BackupDir\$snapName" `
        "$ServerDir\world" `
        "$ServerDir\world_nether" `
        "$ServerDir\world_the_end" 2>&1 | Out-Null
    # -mx=1 = minimum compression for speed (priority here is getting the snapshot done fast)
    # -mx=1 = compresión mínima por velocidad (la prioridad es hacer el snapshot rápido)

    # Send the stop command via RCON.
    # Envía el comando stop via RCON.
    Invoke-Rcon "stop" | Out-Null

    # Wait up to 45 seconds for the Java process to exit cleanly.
    # Forge 1.12.2 may take time to save and unload chunks before exiting.
    # Espera hasta 45 segundos a que el proceso Java salga limpiamente.
    # Forge 1.12.2 puede tardar en guardar y descargar chunks antes de salir.
    Write-Log "Waiting for server process to exit..." "DarkGray" "RESTORE"
    $waited = 0
    while (-not $Process.HasExited -and $waited -lt 45) {
        Start-Sleep -Seconds 1
        $waited++
    }

    # Force-kill if it's still running after the timeout.
    # Fuerza el cierre si sigue corriendo después del timeout.
    if (-not $Process.HasExited) {
        Write-Log "Process did not exit in time. Force-killing..." "Yellow" "RESTORE"
        $Process.Kill()
        Start-Sleep -Seconds 3
    }

    # Delete current world folders.
    # In Minecraft 1.12.2 the world data is stored in these three folders.
    # Borrar las carpetas del mundo actual.
    # En Minecraft 1.12.2 los datos del mundo se almacenan en estas tres carpetas.
    foreach ($folder in @("world", "world_nether", "world_the_end")) {
        $folderPath = "$ServerDir\$folder"
        if (Test-Path $folderPath) {
            Write-Log "Deleting current world folder: $folder" "DarkGray" "RESTORE"
            Remove-Item $folderPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Extract the backup archive into the server folder.
    # -o sets the output directory.
    # -y answers "yes" to all prompts (overwrite, etc.)
    # Extrae el archivo de backup en la carpeta del servidor.
    # -o establece el directorio de salida.
    # -y responde "sí" a todas las preguntas (sobreescribir, etc.)
    Write-Log "Extracting backup: $BackupName ..." "Yellow" "RESTORE"
    & $SevenZipExe x "$backupPath" -o"$ServerDir" -y 2>&1 | Out-Null

    Write-Log "Restore complete. Server will restart automatically." "Green" "RESTORE"
    return $true
}


# =============================================================================
#  FUNCTION: Read-NewLogLines
#  Reads NEW lines from the server's latest.log and detects chat commands.
#  Lee las líneas NUEVAS del latest.log del servidor y detecta comandos del chat.
#
#  Why read the log instead of using RCON to receive chat?
#  ¿Por qué leer el log en vez de usar RCON para recibir el chat?
#
#    RCON is one-directional: it only allows SENDING commands to the server.
#    There is no official API to receive in-game chat events.
#    The only reliable way to "listen" to the chat is to tail the latest.log
#    file that Minecraft writes continuously.
#
#    RCON es unidireccional: solo permite ENVIAR comandos al servidor.
#    No existe una API oficial para recibir eventos del chat del juego.
#    La única forma confiable de "escuchar" el chat es leer el archivo latest.log
#    que Minecraft escribe continuamente.
#
#  IMPORTANT — Regex ordering:
#  IMPORTANTE — Orden de la regex:
#    "!backups" MUST appear before "!backup" in the alternation.
#    If "!backup" were first, "!backups" would match as "!backup" (with an
#    ignored trailing 's'), causing the list command to trigger a backup instead.
#
#    "!backups" DEBE aparecer antes que "!backup" en la alternancia.
#    Si "!backup" estuviera primero, "!backups" matchearía como "!backup" (con
#    una 's' ignorada al final), causando que el comando de lista dispare un backup.
#
#  Chat line format in latest.log / Formato de línea de chat en latest.log:
#    [14:30:00] [Server thread/INFO]: <PlayerName> !command argument
#
#  Parameters / Parámetros:
#    $Position — Byte offset to start reading from (avoids re-reading old lines)
#                Offset de bytes desde donde empezar a leer (evita releer líneas viejas)
#
#  Returns / Devuelve:
#    An object with:
#    Un objeto con:
#      .Events      — Array of detected command events / Array de eventos de comandos detectados
#      .NewPosition — Updated byte position for next call / Posición actualizada para la próxima llamada
# =============================================================================

# Regex pattern for detecting commands in chat lines.
# Order: !backups first, then !backup (with optional argument), then !restore (requires argument).
# Regex para detectar comandos en líneas del chat.
# Orden: !backups primero, luego !backup (con argumento opcional), luego !restore (requiere argumento).
$ChatRegex = [regex]'\[Server thread\/INFO\].*?<(\w+)>\s+(!backups|!backup(?:\s+[^!]\S*(?:\s+\S+)*)?|!restore(?:\s+\S+)?|!save)'

function Read-NewLogLines {
    param([long]$Position)

    $result = @{ Events = @(); NewPosition = $Position }

    # Return empty if the log file doesn't exist yet (server still starting up).
    # Devuelve vacío si el archivo de log aún no existe (servidor todavía iniciando).
    if (-not (Test-Path $LogFile)) { return $result }

    try {
        # Open the file in shared read mode.
        # "ReadWrite" as the third parameter allows us to open the file even while
        # the Minecraft server process has it open for writing.
        # Abre el archivo en modo de lectura compartida.
        # "ReadWrite" como tercer parámetro permite abrir el archivo aunque el proceso
        # de Minecraft lo tenga abierto para escritura.
        $fs = [System.IO.File]::Open($LogFile, 'Open', 'Read', 'ReadWrite')

        # If the file is smaller than our saved position, the log was rotated
        # (server restarted and created a new log). Reset to the beginning.
        # Si el archivo es más chico que nuestra posición guardada, el log fue rotado
        # (el servidor reinició y creó un nuevo log). Resetea al inicio.
        if ($fs.Length -lt $Position) { $Position = 0 }

        # Seek to where we left off last time to read only new lines.
        # Salta al punto donde nos quedamos la última vez para leer solo líneas nuevas.
        $fs.Seek($Position, [System.IO.SeekOrigin]::Begin) | Out-Null
        $reader = New-Object System.IO.StreamReader($fs)

        while ($null -ne ($line = $reader.ReadLine())) {
            $match = $ChatRegex.Match($line)
            if ($match.Success) {
                # Split into command and optional argument (max 2 parts).
                # Divide en comando y argumento opcional (máximo 2 partes).
                $parts = $match.Groups[2].Value.Trim() -split '\s+', 2
                $result.Events += @{
                    Player    = $match.Groups[1].Value
                    Command   = $parts[0].ToLower()
                    Argument  = if ($parts.Length -gt 1) { $parts[1].Trim() } else { $null }
                }
            }
        }

        # Save the current position so the next call only reads new content.
        # Guarda la posición actual para que la próxima llamada solo lea contenido nuevo.
        $result.NewPosition = $fs.Position
        $reader.Close()
        $fs.Close()

    } catch {
        # Silently ignore read errors (e.g., file temporarily locked).
        # Ignora silenciosamente los errores de lectura (ej: archivo temporalmente bloqueado).
    }

    return $result
}


# =============================================================================
#  PRE-FLIGHT CHECKS
#  Validates all requirements before starting the server.
#  Valida todos los requisitos antes de iniciar el servidor.
# =============================================================================

Clear-Host

# Build the header box with guaranteed fixed-width lines using PadRight().
# Every content line is built as: "  |" + content.PadRight(50) + "|"
# The border is:                  "  +" + ("-" * 50)           + "+"
# This ensures the right-side "|" and "+" always align perfectly,
# regardless of how long the variable values are.
#
# Construye el box del header con líneas de ancho fijo garantizado usando PadRight().
# Cada línea de contenido es: "  |" + contenido.PadRight(50) + "|"
# El borde es:                "  +" + ("-" * 50)              + "+"
# Esto garantiza que el "|" y "+" del lado derecho siempre alineen perfectamente,
# sin importar el largo de los valores de las variables.

$boxWidth  = 50
$border    = "  +" + ("-" * $boxWidth) + "+"

function Format-BoxLine {
    param([string]$Text)
    # Pad or trim to exactly $boxWidth characters so the right border always aligns.
    # Rellena o recorta a exactamente $boxWidth caracteres para que el borde derecho siempre alinee.
    $inner = $Text.PadRight($boxWidth)
    if ($inner.Length -gt $boxWidth) { $inner = $inner.Substring(0, $boxWidth) }
    return "  |" + $inner + "|"
}

$titleLine  = Format-BoxLine "          mortups  v1.0  by mortamc        "
$blankLine  = Format-BoxLine ""
$ramLine    = Format-BoxLine "  RAM    : ${MinRamGB} GB min  /  ${MaxRamGB} GB max"
$backupLine = Format-BoxLine "  Backup : every ${BackupIntervalMin} min  |  keep ${BackupRetentionDays} days"
$permsLine  = Format-BoxLine "  Perms  : $CommandPermission"
$cmdsLine   = Format-BoxLine "  Commands: !save  !backup  !backups  !restore"

Write-Host ""
Write-Host $border
Write-Host $titleLine
Write-Host $border
Write-Host $ramLine
Write-Host $backupLine
Write-Host $permsLine
Write-Host $cmdsLine
Write-Host $border
Write-Host ""

# Check 1: server.jar exists / Verifica que existe el server.jar
if (-not (Test-Path "$ServerDir\$ServerJar")) {
    Write-Log "server.jar not found at: $ServerDir\$ServerJar" "Red" "ERROR"
    Write-Log "Check the ServerDir and ServerJar variables in the configuration." "Yellow" "ERROR"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Check 2: 7-Zip is installed / Verifica que 7-Zip está instalado
if (-not $SevenZipExe) {
    Write-Log "7-Zip not found. Install it from https://7-zip.org" "Red" "ERROR"
    Write-Log "Then add its path to SevenZipSearchPaths in the configuration." "Yellow" "ERROR"
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Log "7-Zip found at : $SevenZipExe" "DarkGray" "INFO"
Write-Log "Backup folder  : $BackupDir"   "DarkGray" "INFO"
Write-Log "Permissions    : $CommandPermission" "DarkGray" "INFO"
Write-Log "Log file       : $LogFile"     "DarkGray" "INFO"

# Create backup folder if it doesn't exist.
# Crea la carpeta de backups si no existe.
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
    Write-Log "Backup folder created." "DarkGray" "INFO"
}

# Change to the server directory so Java can find all relative paths (world, mods, etc.)
# Cambia al directorio del servidor para que Java encuentre todas las rutas relativas (mundo, mods, etc.)
Set-Location $ServerDir


# =============================================================================
#  MAIN LOOP
#  Bucle principal
#
#  Outer loop ($keepRunning):
#    Starts the server. If it stopped due to a restore, restarts it automatically.
#    If it stopped normally (via "stop" command), exits the script.
#
#  Bucle externo ($keepRunning):
#    Inicia el servidor. Si se detuvo por un restore, lo reinicia automáticamente.
#    Si se detuvo normalmente (via comando "stop"), termina el script.
#
#  Inner loop (while -not $proc.HasExited):
#    Runs every 10 seconds while the server is active.
#    Triggers automatic backups when the interval elapses.
#    Reads the log file to detect and handle in-game chat commands.
#
#  Bucle interno (while -not $proc.HasExited):
#    Corre cada 10 segundos mientras el servidor está activo.
#    Dispara backups automáticos cuando el intervalo transcurre.
#    Lee el archivo de log para detectar y manejar comandos del chat del juego.
# =============================================================================

# Controls whether the outer loop continues running.
# Controla si el bucle externo continúa corriendo.
$keepRunning = $true

# Tracks whether the server was stopped intentionally for a restore
# (so the outer loop knows to restart it instead of exiting).
# Indica si el servidor fue detenido intencionalmente para un restore
# (para que el bucle externo sepa que debe reiniciarlo en vez de salir).
$restartAfterRestore = $false

while ($keepRunning) {

    Write-Log "Starting Minecraft server with ${MaxRamGB} GB RAM..." "Green" "SERVER"
    Write-Log "Command: $JavaExe $($JavaArgs -join ' ')" "DarkGray" "SERVER"

    # Launch the Java process.
    # -PassThru  : returns the Process object so we can monitor it
    # -NoNewWindow: output goes to the current console window
    # Lanza el proceso Java.
    # -PassThru  : devuelve el objeto Process para poder monitorearlo
    # -NoNewWindow: la salida va a la ventana de consola actual
    $proc = Start-Process `
        -FilePath      $JavaExe `
        -ArgumentList  $JavaArgs `
        -WorkingDirectory $ServerDir `
        -PassThru `
        -NoNewWindow

    # Verify the process launched successfully.
    # Verifica que el proceso arrancó correctamente.
    if ($null -eq $proc -or $proc.HasExited) {
        Write-Log "Failed to start the server process." "Red" "ERROR"
        Write-Log "Make sure Java is installed and in the system PATH." "Yellow" "ERROR"
        Write-Log "Download Java 8 from: https://adoptium.net" "Yellow" "ERROR"
        $keepRunning = $false
        continue
    }

    Write-Log "Server process started (PID: $($proc.Id)). Waiting $ServerStartupWaitSec seconds for startup..." "Green" "SERVER"
    Start-Sleep -Seconds $ServerStartupWaitSec

    # Optional startup backup (only on real starts, not after a restore restart).
    # Backup inicial opcional (solo en arranques reales, no tras un reinicio por restore).
    if ($BackupOnServerStart -and -not $restartAfterRestore) {
        Write-Log "Creating startup backup..." "Cyan" "BACKUP"
        New-Backup -Type "startup"
    }

    # Schedule the first automatic backup.
    # Programa el primer backup automático.
    $nextBackup = (Get-Date).AddMinutes($BackupIntervalMin)
    Write-Log "Next automatic backup at: $($nextBackup.ToString('HH:mm'))" "Cyan" "SERVER"

    # Mark the current end of the log file so we only process NEW lines from here on.
    # Marca el final actual del archivo de log para procesar solo líneas NUEVAS desde este punto.
    $logPos = 0
    if (Test-Path $LogFile) { $logPos = (Get-Item $LogFile).Length }

    $restartAfterRestore = $false

    # ── INNER LOOP — runs while the server process is alive ────────────────
    # ── BUCLE INTERNO — corre mientras el proceso del servidor está vivo ────
    while (-not $proc.HasExited) {

        # Poll every 10 seconds. This is enough resolution for our purposes
        # and avoids unnecessary CPU usage.
        # Verifica cada 10 segundos. Es suficiente resolución para nuestros fines
        # y evita uso innecesario del CPU.
        Start-Sleep -Seconds 10

        # ── Automatic backup timer ─────────────────────────────────────────
        # ── Timer de backup automático ─────────────────────────────────────
        if ((Get-Date) -ge $nextBackup) {
            New-Backup -Type "auto"
            $nextBackup = (Get-Date).AddMinutes($BackupIntervalMin)
            Write-Log "Next automatic backup at: $($nextBackup.ToString('HH:mm'))" "DarkGray" "SERVER"
        }

        # ── Read new chat lines and process commands ───────────────────────
        # ── Lee nuevas líneas del chat y procesa comandos ──────────────────
        $logRead = Read-NewLogLines -Position $logPos
        $logPos  = $logRead.NewPosition   # Update position for next iteration / Actualiza posición para la próxima iteración

        foreach ($event in $logRead.Events) {

            $player  = $event.Player
            $command = $event.Command
            $arg     = $event.Argument

            Write-Log "Command from '$player': $command $arg" "Magenta" "CMD"

            # ── Permission check ───────────────────────────────────────────
            # ── Verificación de permisos ───────────────────────────────────
            if (-not (Test-PlayerAllowed $player)) {
                Write-Log "$player is not allowed (mode: $CommandPermission)." "DarkGray" "PERM"
                Invoke-Rcon "say ${S}c[Manager] ${S}f$player${S}c: You don't have permission to use this command." | Out-Null
                continue
            }

            switch ($command) {

                # ── !save ──────────────────────────────────────────
                # Forces the server to save all chunks to disk immediately.
                # Fuerza al servidor a guardar todos los chunks al disco ahora mismo.
                "!save" {
                    Write-Log "$player requested a manual save." "CMD"
                    Invoke-Rcon "say ${S}e[Save] ${S}fSaving world..." | Out-Null
                    Invoke-Rcon "save-all" | Out-Null
                    Invoke-Rcon "say ${S}a[Save] ${S}fWorld saved successfully." | Out-Null
                }

                # ── !backup [name] ─────────────────────────────────────────
                # Creates a manual backup. Optionally accepts a custom name.
                # Crea un backup manual. Opcionalmente acepta un nombre personalizado.
                "!backup" {
                    if (-not $EnableBackupCommand) {
                        Invoke-Rcon "say ${S}c[Manager] ${S}fThe !backup command is disabled." | Out-Null
                    } else {
                        $customName = if ($arg) { $arg } else { "" }
                        if ($customName -ne "") {
                            Write-Log "$player requested a manual backup with name: '$customName'" "Cyan" "CMD"
                        } else {
                            Write-Log "$player requested a manual backup." "Cyan" "CMD"
                        }
                        New-Backup -Type "manual" -CustomName $customName
                    }
                }

                # ── !backups ───────────────────────────────────────────────
                # Lists available backups in the in-game chat.
                # Lista los backups disponibles en el chat del juego.
                "!backups" {
                    if (-not $EnableBackupsCommand) {
                        Invoke-Rcon "say ${S}c[Manager] ${S}fThe !backups command is disabled." | Out-Null
                    } else {
                        $list = Get-BackupList
                        if ($list.Count -eq 0) {
                            Invoke-Rcon "say ${S}e[Backups] ${S}fNo backups available yet." | Out-Null
                        } else {
                            Invoke-Rcon "say ${S}e[${S}6Backups${S}e] ${S}fAvailable backups (newest first):" | Out-Null
                            $list | Select-Object -First $MaxBackupsShownInChat | ForEach-Object {
                                $hoursAgo = [Math]::Round(((Get-Date) - $_.LastWriteTime).TotalHours, 1)
                                $mb       = [Math]::Round($_.Length / 1MB, 1)
                                # Color-code the age: green if recent, yellow if older, red if near expiry.
                                # Colorea la antigüedad: verde si es reciente, amarillo si es más viejo, rojo si está cerca de expirar.
                                $ageColor = if ($hoursAgo -lt 2) { "${S}a" } elseif ($hoursAgo -lt 48) { "${S}e" } else { "${S}c" }
                                Invoke-Rcon "say ${S}7 - ${S}f$($_.Name) ${ageColor}(${hoursAgo}h ago${S}7, ${mb} MB)" | Out-Null
                            }
                            if ($list.Count -gt $MaxBackupsShownInChat) {
                                $more = $list.Count - $MaxBackupsShownInChat
                                Invoke-Rcon "say ${S}7   ... and $more more in the /backups folder." | Out-Null
                            }
                            Invoke-Rcon "say ${S}e[Backups] ${S}fTo restore: ${S}b!restore ${S}f<exact_filename.7z>" | Out-Null
                        }
                    }
                }

                # ── !restore <filename> ────────────────────────────────────
                # Restores the server from a backup and restarts it.
                # Restaura el servidor desde un backup y lo reinicia.
                "!restore" {
                    if (-not $EnableRestoreCommand) {
                        Invoke-Rcon "say ${S}c[Manager] ${S}fThe !restore command is disabled." | Out-Null
                    } elseif (-not $arg -or $arg.Trim() -eq "") {
                        # No filename provided — show usage hint.
                        # No se proporcionó nombre de archivo — muestra ayuda de uso.
                        Invoke-Rcon "say ${S}c[Restore] ${S}fUsage: ${S}e!restore filename.7z" | Out-Null
                        Invoke-Rcon "say ${S}c[Restore] ${S}fExample: ${S}e!restore backup_auto_2026-03-14_06-17.7z" | Out-Null
                        Invoke-Rcon "say ${S}c[Restore] ${S}fType ${S}e!backups ${S}fto see available files." | Out-Null
                    } else {
                        Write-Log "$player requested restore: $arg" "Yellow" "CMD"
                        $ok = Invoke-Restore -BackupName $arg -Process $proc
                        if ($ok) {
                            # Flag the outer loop to restart the server after this iteration ends.
                            # Indica al bucle externo que reinicie el servidor cuando esta iteración termine.
                            $restartAfterRestore = $true
                            # Invoke-Restore already stopped the server.
                            # $proc.HasExited will be $true on the next while check, exiting the inner loop.
                            # Invoke-Restore ya detuvo el servidor.
                            # $proc.HasExited será $true en la próxima verificación del while, saliendo del bucle interno.
                        }
                    }
                }

            } # end switch / fin switch
        } # end foreach event / fin foreach evento
    } # end inner loop / fin bucle interno

    # ── Post-exit decision ──────────────────────────────────────────────────
    # ── Decisión post-cierre ────────────────────────────────────────────────
    if ($restartAfterRestore) {
        # Server was stopped for a restore. Restart it with the restored world.
        # El servidor fue detenido para un restore. Reiniciarlo con el mundo restaurado.
        Write-Log "Restarting server after restore in 5 seconds..." "Yellow" "SERVER"
        Start-Sleep -Seconds 5
        # $keepRunning is still $true — the outer while restarts the server.
        # $keepRunning sigue en $true — el while externo reinicia el servidor.
    } else {
        # Server exited normally (someone typed "stop", etc.). Finish the manager.
        # El servidor salió normalmente (alguien escribió "stop", etc.). Terminar el manager.
        Write-Log "Server closed normally. Manager shutting down." "Yellow" "SERVER"
        $keepRunning = $false
    }

} # end outer loop / fin bucle externo


# =============================================================================
#  END / FIN
# =============================================================================
Write-Host ""
Write-Host "  Manager stopped." -ForegroundColor DarkGray
