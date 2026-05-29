# Evaluación comparativa de un controlador PI descentralizado y un MPC en el proceso de cuatro tanques de Johansson

**Trabajo de Titulación** para optar al título de Tecnólogo en Automatización Industrial.

**Universidad de Santiago de Chile (USACH)** — Facultad Tecnológica — Departamento de Tecnologías Industriales.

## Autores

- Álvaro Andrés Cuevas Ulloa
- Cristóbal Lizama Zúñiga

**Profesor guía:** Gustavo Alcántara Aravena.

## Descripción

Este repositorio contiene el código fuente, los modelos de simulación y los archivos de configuración desarrollados en el marco del trabajo de titulación. El estudio evalúa el desempeño de dos estrategias de control multivariable, un controlador PI descentralizado y un controlador predictivo basado en modelo (MPC), aplicadas al proceso de cuatro tanques de Johansson en su configuración de fase mínima. La evaluación se realiza dentro de un entorno virtual integrado que combina MATLAB/Simulink, Factory IO y Python.

## Estructura del repositorio

```
├── matlab/
│   ├── modelo/                Modelo no lineal del proceso y linealización
│   ├── pi_descentralizado/    Sintonía IMC y simulación del PI descentralizado
│   ├── mpc/                   Configuración y simulación del MPC
│   └── ensayos/               Scripts de ejecución de los ensayos E1 a E5
├── python/
│   ├── configuracion/         Generación de archivos de configuración de ensayos
│   └── postproceso/           Análisis de datos CSV exportados y generación de gráficos
├── simulink/                  Modelos de Simulink (.slx)
├── factoryio/                 Escena del proceso en Factory IO
├── datos/                     Datos CSV exportados por MATLAB en cada ensayo
├── documento/                 Archivos LaTeX del trabajo de titulación
└── anexos/                    Material complementario
```

## Herramientas utilizadas

| Herramienta | Versión | Rol en el proyecto |
|---|---|---|
| MATLAB | R2024b | Modelado, linealización y ejecución de controladores |
| Simulink | R2024b | Simulación del modelo no lineal y los lazos de control |
| MPC Toolbox | R2024b | Configuración del controlador MPC |
| Factory IO | — | Visualización 3D del proceso vía Modbus TCP/IP |
| Python | 3.x | Automatización de ensayos y post-procesamiento de datos |
| LaTeX (pdflatex + biber) | — | Redacción del documento |

## Ensayos

El trabajo define cinco ensayos comparativos ejecutados bajo idénticas condiciones para ambos controladores:

| Ensayo | Descripción |
|---|---|
| E1 | Seguimiento de referencia individual en tanque 1 |
| E2 | Seguimiento de referencia individual en tanque 2 |
| E3 | Seguimiento de referencia simultáneo (MIMO) |
| E4 | Rechazo de perturbación de carga |
| E5 | Operación con restricciones de actuador activas |

## Estado del repositorio

> **Este repositorio es privado y se encuentra en desarrollo activo.**
> Será publicado tras la defensa del trabajo de titulación.

## Licencia

Pendiente de definir tras la defensa.
