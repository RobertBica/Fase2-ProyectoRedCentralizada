# ============================================================
#  menuGestionObjetos.ps1
#  Hospital La Plana — Fase 2 Proyecto Red Centralizada
#  Dominio: hospitallaplana.mylocal
# ============================================================

# Variable global del dominio
$domain = "dc=hospitallaplana,dc=mylocal"

# ============================================================
# Comprobacion del modulo Active Directory
# ============================================================
if (!(Get-Module -Name ActiveDirectory))
{
    Import-Module ActiveDirectory
}

# ============================================================
# FUNCION: Mostrar Menu
# ============================================================
function Show-Menu
{
    param (
        [string]$Titulo = 'Hospital La Plana — Gestion de Objetos AD'
    )
    Clear-Host
    Write-Host "================ $Titulo ================" -ForegroundColor Blue
    Write-Host ""
    Write-Host "  1: Crear estructura del subsistema (UOs, Grupos, Equipos y Usuarios)"
    Write-Host "  2: Consultar todos los objetos del dominio"
    Write-Host "  3: Eliminar toda la estructura del subsistema"
    Write-Host "  Q: Salir"
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Blue
}

# ============================================================
# FUNCION: Crear Unidades Organizativas
# ============================================================
function alta_UOs
{
    $ficheroCsvUO = Read-Host "Introduce la ruta del fichero csv de UOs (ej: C:\Fase2\unidades_org.csv)"
    $fichero = Import-Csv -Path $ficheroCsvUO -Delimiter ":"

    Write-Host ""
    Write-Host "--- Creando Unidades Organizativas ---" -ForegroundColor Cyan

    foreach ($line in $fichero)
    {
        try
        {
            New-ADOrganizationalUnit `
                -Name $line.Name `
                -Description $line.Description `
                -Path $line.Path `
                -ProtectedFromAccidentalDeletion $false
            Write-Host "  [+] OU creada: $($line.Name)" -ForegroundColor Green
        }
        catch
        {
            Write-Host "  [~] Ya existe o error en '$($line.Name)': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "Se han procesado las UOs en el dominio $domain" -ForegroundColor Green
}

# ============================================================
# FUNCION: Crear Grupos
# ============================================================
function alta_grupos
{
    $gruposCsv = Read-Host "Introduce la ruta del fichero csv de Grupos (ej: C:\Fase2\grupos.csv)"
    $fichero = Import-Csv -Path $gruposCsv -Delimiter ":"

    Write-Host ""
    Write-Host "--- Creando Grupos ---" -ForegroundColor Cyan

    foreach ($linea in $fichero)
    {
        try
        {
            New-ADGroup `
                -Name $linea.Name `
                -Description $linea.Description `
                -GroupCategory $linea.Category `
                -GroupScope $linea.Scope `
                -Path $linea.Path
            Write-Host "  [+] Grupo creado: $($linea.Name)" -ForegroundColor Green
        }
        catch
        {
            Write-Host "  [~] Ya existe o error en '$($linea.Name)': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "Se han procesado los grupos en el dominio $domain" -ForegroundColor Green
}

# ============================================================
# FUNCION: Crear Equipos
# ============================================================
function alta_equipos
{
    $equiposCsv = Read-Host "Introduce la ruta del fichero csv de Equipos (ej: C:\Fase2\equipos.csv)"
    $fichero = Import-Csv -Path $equiposCsv -Delimiter ":"

    Write-Host ""
    Write-Host "--- Creando Equipos ---" -ForegroundColor Cyan

    foreach ($line in $fichero)
    {
        try
        {
            New-ADComputer `
                -Enabled $true `
                -Name $line.Computer `
                -Path $line.Path `
                -SamAccountName $line.Computer
            Write-Host "  [+] Equipo creado: $($line.Computer)" -ForegroundColor Green
        }
        catch
        {
            Write-Host "  [~] Ya existe o error en '$($line.Computer)': $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
    Write-Host "Se han procesado los equipos en el dominio $domain" -ForegroundColor Green
}

# ============================================================
# FUNCION: Crear Usuarios
# ============================================================
function alta_usuarios
{
    $fileUsersCsv = Read-Host "Introduce la ruta del fichero csv de Usuarios (ej: C:\Fase2\usuarios.csv)"
    $fichero = Import-Csv -Path $fileUsersCsv -Delimiter "*"

    Write-Host ""
    Write-Host "--- Creando Usuarios ---" -ForegroundColor Cyan

    foreach ($linea in $fichero)
    {
        try
        {
            $passAccount = ConvertTo-SecureString $linea.Password -AsPlainText -Force
            $Surnames    = $linea.Surname1 + ' ' + $linea.Surname2
            $nameLarge   = $linea.Name + ' ' + $linea.Surname1 + ' ' + $linea.Surname2
            $email       = $linea.Email

            [boolean]$Habilitado = $true
            if ($linea.Enabled -Match 'false') { $Habilitado = $false }

            # Fecha de expiracion de la cuenta
            $timeExp = (Get-Date).AddDays([int]$linea.ExpirationAccount)

            # Crear el usuario
            New-ADUser `
                -SamAccountName       $linea.Account `
                -UserPrincipalName    "$($linea.Account)@hospitallaplana.mylocal" `
                -Name                 $linea.Account `
                -Surname              $Surnames `
                -DisplayName          $nameLarge `
                -GivenName            $linea.Name `
                -Description          "Cuenta de $nameLarge - DNI: $($linea.DNI)" `
                -EmailAddress         $email `
                -AccountPassword      $passAccount `
                -Enabled              $Habilitado `
                -CannotChangePassword $false `
                -ChangePasswordAtLogon $true `
                -PasswordNotRequired  $false `
                -Path                 $linea.Path `
                -AccountExpirationDate $timeExp `
                -Department           $linea.Departament

            # Establecer horario de inicio de sesion
            $horassesion = $linea.NetTime -replace(" ", "")
            net user $linea.Account /times:$horassesion /domain

            # Asignar equipo de inicio de sesion
            Set-ADUser -Identity $linea.Account -LogonWorkstations $linea.Computer

            # Asignar usuario al grupo
            $cnGrpAccount = "CN=" + $linea.Group + "," + $linea.Path
            Add-ADGroupMember -Identity $linea.Group -Members $linea.Account

            Write-Host "  [+] Usuario creado: $($linea.Account) → $($linea.Departament)" -ForegroundColor Green
        }
        catch
        {
            Write-Host "  [!] Error en '$($linea.Account)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "Se han procesado los usuarios en el dominio $domain" -ForegroundColor Green
}

# ============================================================
# FUNCION: Crear toda la estructura de una vez
# ============================================================
function alta_EstructuraCompleta
{
    Write-Host ""
    Write-Host "=== DESPLEGANDO ESTRUCTURA COMPLETA DEL HOSPITAL LA PLANA ===" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "[1/4] UNIDADES ORGANIZATIVAS" -ForegroundColor Cyan
    alta_UOs

    Write-Host ""
    Write-Host "[2/4] GRUPOS" -ForegroundColor Cyan
    alta_grupos

    Write-Host ""
    Write-Host "[3/4] EQUIPOS" -ForegroundColor Cyan
    alta_equipos

    Write-Host ""
    Write-Host "[4/4] USUARIOS" -ForegroundColor Cyan
    alta_usuarios

    Write-Host ""
    Write-Host "=== ESTRUCTURA DESPLEGADA CORRECTAMENTE ===" -ForegroundColor Magenta
}

# ============================================================
# FUNCION: Consultar todos los objetos del dominio
# ============================================================
function consultar_Objetos
{
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " UNIDADES ORGANIZATIVAS" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Get-ADOrganizationalUnit -Filter * | Select-Object Name, DistinguishedName | Format-Table -AutoSize

    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " GRUPOS" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Get-ADGroup -Filter * | Select-Object Name, GroupScope, GroupCategory | Format-Table -AutoSize

    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " EQUIPOS" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Get-ADComputer -Filter * | Select-Object Name, Enabled, DistinguishedName | Format-Table -AutoSize

    Write-Host "========================================" -ForegroundColor Magenta
    Write-Host " USUARIOS" -ForegroundColor Magenta
    Write-Host "========================================" -ForegroundColor Magenta
    Get-ADUser -Filter * -Properties Department, EmailAddress, Description | `
        Select-Object Name, SamAccountName, Department, EmailAddress, Enabled | `
        Format-Table -AutoSize
}

# ============================================================
# FUNCION: Eliminar toda la estructura del dominio
# ============================================================
function eliminar_Estructura
{
    Write-Host ""
    Write-Host "⚠️  ATENCION: Esta accion eliminara TODOS los objetos creados." -ForegroundColor Red
    Write-Host "     Usuarios, Grupos, Equipos y Unidades Organizativas." -ForegroundColor Red
    Write-Host ""
    $confirmacion = Read-Host "¿Estas seguro? Escribe 'SI' para confirmar"

    if ($confirmacion -ne "SI")
    {
        Write-Host "Operacion cancelada." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "--- Eliminando Usuarios ---" -ForegroundColor Cyan
    $usuarios = Get-ADUser -Filter * -SearchBase "dc=hospitallaplana,dc=mylocal" |
        Where-Object { $_.DistinguishedName -notlike "*CN=Administrator*" -and
                       $_.DistinguishedName -notlike "*CN=Guest*" -and
                       $_.DistinguishedName -notlike "*CN=krbtgt*" }
    foreach ($u in $usuarios)
    {
        try
        {
            Remove-ADUser -Identity $u -Confirm:$false
            Write-Host "  [-] Usuario eliminado: $($u.SamAccountName)" -ForegroundColor Green
        }
        catch { Write-Host "  [!] Error eliminando usuario $($u.SamAccountName): $($_.Exception.Message)" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "--- Eliminando Equipos ---" -ForegroundColor Cyan
    $equipos = Get-ADComputer -Filter * -SearchBase "dc=hospitallaplana,dc=mylocal" |
        Where-Object { $_.Name -notlike "*SERVER*" -and $_.Name -notlike "*DC*" }
    foreach ($eq in $equipos)
    {
        try
        {
            Remove-ADComputer -Identity $eq -Confirm:$false
            Write-Host "  [-] Equipo eliminado: $($eq.Name)" -ForegroundColor Green
        }
        catch { Write-Host "  [!] Error eliminando equipo $($eq.Name): $($_.Exception.Message)" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "--- Eliminando Grupos ---" -ForegroundColor Cyan
    $grupos = Get-ADGroup -Filter * -SearchBase "dc=hospitallaplana,dc=mylocal" |
        Where-Object { $_.Name -like "HLP-GG-*" }
    foreach ($g in $grupos)
    {
        try
        {
            Remove-ADGroup -Identity $g -Confirm:$false
            Write-Host "  [-] Grupo eliminado: $($g.Name)" -ForegroundColor Green
        }
        catch { Write-Host "  [!] Error eliminando grupo $($g.Name): $($_.Exception.Message)" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "--- Eliminando Unidades Organizativas ---" -ForegroundColor Cyan
    
    $ouHijas = @(
        "OU=Equipos-Prensa,OU=Dep-Prensa,dc=hospitallaplana,dc=mylocal",
        "OU=Usuarios-Prensa,OU=Dep-Prensa,dc=hospitallaplana,dc=mylocal",
        "OU=Equipos-Enfermeria,OU=Dep-Enfermeria,dc=hospitallaplana,dc=mylocal",
        "OU=Usuarios-Enfermeria,OU=Dep-Enfermeria,dc=hospitallaplana,dc=mylocal",
        "OU=Equipos-Informatica,OU=Dep-Informatica,dc=hospitallaplana,dc=mylocal",
        "OU=Usuarios-Informatica,OU=Dep-Informatica,dc=hospitallaplana,dc=mylocal",
        "OU=Equipos-Formacion,OU=Dep-Formacion,dc=hospitallaplana,dc=mylocal",
        "OU=Usuarios-Formacion,OU=Dep-Formacion,dc=hospitallaplana,dc=mylocal"
    )
    $ouPadre = @(
        "OU=Dep-Prensa,dc=hospitallaplana,dc=mylocal",
        "OU=Dep-Enfermeria,dc=hospitallaplana,dc=mylocal",
        "OU=Dep-Informatica,dc=hospitallaplana,dc=mylocal",
        "OU=Dep-Formacion,dc=hospitallaplana,dc=mylocal"
    )
    foreach ($ou in ($ouHijas + $ouPadre))
    {
        try
        {
            Set-ADOrganizationalUnit -Identity $ou -ProtectedFromAccidentalDeletion $false
            Remove-ADOrganizationalUnit -Identity $ou -Confirm:$false
            Write-Host "  [-] OU eliminada: $ou" -ForegroundColor Green
        }
        catch { Write-Host "  [!] Error eliminando OU: $($_.Exception.Message)" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "=== Estructura eliminada correctamente ===" -ForegroundColor Magenta
}


do
{
    Show-Menu
    $input = Read-Host "Por favor, pulse una opcion"

    switch ($input)
    {
        '1' {
            Clear-Host
            alta_EstructuraCompleta
        }
        '2' {
            Clear-Host
            consultar_Objetos
        }
        '3' {
            Clear-Host
            eliminar_Estructura
        }
        'q' {
            Write-Host ""
            Write-Host "Saliendo de la aplicacion. Hasta luego." -ForegroundColor Gray
            Write-Host ""
            return
        }
        default {
            Write-Host "Opcion no valida. Por favor, pulse 1, 2 o Q." -ForegroundColor Red
        }
    }
    pause
}
until ($input -eq 'q')
