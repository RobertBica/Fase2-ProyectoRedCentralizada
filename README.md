Hospital La Plana — Fase 2: Controlador de Dominio

Proyecto de Red Centralizada — Administración de Active Directory con PowerShell
Módulo: Sistemas Informáticos | Dominio: hospitallaplana.mylocal

Descripción
Este repositorio contiene los scripts de PowerShell y los ficheros CSV necesarios para desplegar de forma desatendida la estructura de objetos del dominio del Hospital La Plana en un servidor Windows Server con Active Directory.
La estructura incluye la creación automática de:

Unidades Organizativas (OUs)
Grupos de seguridad
Cuentas de equipo
Cuentas de usuario con horarios de sesión y restricción de equipo

Estructura del repositorio
Fase2-ProyectoRedCentralizada/
│
├── menuGestionObjetos.ps1     # Script principal con menú interactivo
│
├── csv/
│   ├── unidades_org.csv       # Definición de las OUs del dominio
│   ├── grupos.csv             # Grupos de seguridad por departamento
│   ├── equipos.csv            # Equipos Windows 11 del hospital
│   └── usuarios.csv           # Usuarios con credenciales y horarios
│
└── README.md


Modelo lógico del subsistema
Hospital La Plana (hospitallaplana.mylocal)
│
├── Dep-Prensa
│   ├── Equipos-Prensa        (5 equipos)
│   └── Usuarios-Prensa       (5 usuarios | 07:00–15:00)
│
├── Dep-Enfermeria
│   ├── Equipos-Enfermeria    (10 equipos)
│   └── Usuarios-Enfermeria   (10 usuarios | 07:00–15:00 / 15:00–23:00)
│
├── Dep-Informatica
│   ├── Equipos-Informatica   (10 equipos)
│   └── Usuarios-Informatica  (10 usuarios | 07:00–15:00 / 15:00–23:00)
│
└── Dep-Formacion
    ├── Equipos-Formacion     (5 equipos)
    └── Usuarios-Formacion    (5 usuarios | 09:00–14:00 / 16:00–19:00)


Autor: Robert Bica Moya
Ciclo Formativo DAW — Sistemas Informáticos
