# Planta de laboratorio de cuatro tanques: ingeniería y validación virtual del control PI

Repositorio del trabajo de titulación **"Ingeniería conceptual y básica de una planta de laboratorio de cuatro tanques adaptada del proceso de Johansson, con validación virtual del control PI descentralizado mediante MATLAB, Factory I/O y Python"**, para optar al título de Tecnólogo en Automatización Industrial, Universidad de Santiago de Chile (USACH).

**Autores:** Álvaro Andrés Cuevas Ulloa y Cristóbal Lizama Zúñiga.
**Profesor guía:** Gustavo Alcántara Aravena.

## Descripción

El trabajo desarrolla la ingeniería conceptual y básica de una planta de laboratorio de cuatro tanques para la docencia de control multivariable, y valida en un entorno virtual su filosofía de control: un PI descentralizado sintonizado por control por modelo interno (IMC).

Este repositorio contiene el código y los resultados de esa validación:

- modelo no lineal del proceso, punto de operación y linealización;
- sintonía del PI descentralizado y, como proyección futura, un controlador H-infinito;
- ensayos E1 a E5 sobre el modelo no lineal y cálculo de métricas;
- reproducción de los ensayos en una escena 3D de Factory I/O mediante Modbus TCP/IP;
- generación de las figuras en Python.

La geometría y los parámetros de la planta provienen de la implementación de código abierto de Pedroso y Batista (2022): [decenter2021/quadruple-tank-setup](https://github.com/decenter2021/quadruple-tank-setup).

## Contenido

```
codigo/       Scripts de MATLAB y Python (16 archivos)
resultados/   CSV de la corrida reportada en el documento (ensayos E1-E5 y resumen de métricas)
figuras/      Figuras de los ensayos, validación del modelo lineal, comparación de geometrías y escena de Factory I/O
```

| Archivo | Función |
|---|---|
| `run_todo.m` | Script maestro: ejecuta toda la cadena en orden |
| `geometria_planta.m` | Fuente única de parámetros de la planta |
| `parametros.m` | Carga los parámetros de la geometría adoptada |
| `equilibrio.m` | Punto de operación exacto (`fsolve`) |
| `linealizacion.m` | Modelo lineal, polos, ceros, controlabilidad, observabilidad y RGA |
| `validar_lineal.m` | Comparación entre el modelo lineal y el no lineal |
| `pi_design.m` | Sintonía IMC del PI descentralizado |
| `diseno_hinf.m` | Síntesis del controlador H-infinito (`mixsyn`) |
| `comparacion_E1E5.m` | Ensayos E1 a E5 sobre el modelo no lineal y exportación a CSV |
| `comparacion_geometrias.m` | Comparación de las tres geometrías evaluadas |
| `graficos_E1E5.py` | Figuras de los ensayos a partir de los CSV |
| `fio_config.m` | Configuración de la conexión Modbus con Factory I/O |
| `fio_prueba_conexion.m` | Prueba paso a paso de la comunicación |
| `fio_reproducir.m` | Reproducción de un ensayo en la escena |
| `fio_ensayo_csv.m` | Lectura de un CSV y llamada a la reproducción |
| `fio_todos.m` | Reproducción de los cinco ensayos y tabla de error |

## Requisitos

- **MATLAB R2026a** con Control System Toolbox, Robust Control Toolbox, Optimization Toolbox, Symbolic Math Toolbox e Industrial Communication Toolbox.
- **Python 3** con NumPy, Pandas y Matplotlib.
- **Factory I/O 2.5.8**, solo para la reproducción 3D.

## Cómo reproducir los resultados

Los scripts trabajan en una sola carpeta: los archivos `.mat`, los CSV y las figuras se generan en la carpeta desde donde se ejecutan.

1. En MATLAB, dentro de `codigo/`, ejecutar `run_todo`.
2. En la misma carpeta, ejecutar `python graficos_E1E5.py`.
3. Para Factory I/O: abrir la escena, activar el driver Modbus TCP/IP Server en `127.0.0.1:502`, ponerla en modo Run y ejecutar `fio_prueba_conexion` (sección por sección) y luego `fio_todos`.

La carpeta `resultados/` guarda la corrida del 30 de septiembre de 2026, que es la que se reporta en el documento.

## Referencia de la planta base

Pedroso, L., y Batista, P. (2022). Reproducible low-cost flexible quadruple-tank process experimental setup for control educators, practitioners, and researchers. *Journal of Process Control, 118*, 82-94. https://doi.org/10.1016/j.jprocont.2022.08.010

## Derechos

© 2026 Álvaro Andrés Cuevas Ulloa y Cristóbal Lizama Zúñiga. Todos los derechos reservados.
