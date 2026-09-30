"""
graficos_E1E5.py
Post-procesamiento de la validación virtual (rol post-hoc de Python).
Lee los 10 CSV exportados por MATLAB (comparacion_E1E5.m) y genera:
  - las ilustraciones del PI descentralizado del Capítulo 4
    (figuras/E1_PI.png ... figuras/E5_PI.png);
  - los gráficos comparativos PI vs H-infinito del Anexo A.

Python NO participa del lazo de control: solo lee resultados y grafica.

Entradas (en la misma carpeta):
    E1_seguimiento_T1_{PI,Hinf}.csv
    E2_seguimiento_T2_{PI,Hinf}.csv
    E3_MIMO_simultaneo_{PI,Hinf}.csv
    E4_rechazo_perturbacion_{PI,Hinf}.csv
    E5_robustez_areas_{PI,Hinf}.csv
    resumen_metricas_E1E5.csv
Cada CSV de ensayo: columnas t, r1, r2, y1, y2, u1, u2, h1, h2, h3, h4
(y, r, u en V; h en cm; y = kc*h con kc = 0,5 V/cm)

Salidas (PNG a 300 dpi):
    figuras/E1_PI.png .. E5_PI.png  Cap. 4: niveles h1, h2 [cm] + señales u1, u2
                                   con el límite de 12 V (solo PI)
    fig_E1..E5_respuesta.png   respuestas de nivel (y vs referencia)
    fig_E1..E5_control.png     señales de control (u1, u2)
    fig_IAE_comparacion.png    barras de IAE total por ensayo
    fig_IAE_cruzado.png        barras de IAE cruzado (E1, E2)
"""

import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt

KC    = 0.5    # ganancia de medición [V/cm]
U_MAX = 12.0   # saturación de las bombas VMA421 [V]

# ---------------------------------------------------------------
# Configuración de estilo (sobrio, para documento académico)
# ---------------------------------------------------------------
plt.rcParams.update({
    'font.size': 11,
    'axes.grid': True,
    'grid.alpha': 0.3,
    'figure.dpi': 100,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
})

COLOR_PI   = '#1f77b4'   # azul
COLOR_HINF = '#d62728'   # rojo
COLOR_REF  = '#555555'   # gris para la referencia

ensayos = {
    'E1_seguimiento_T1':      'E1: seguimiento individual T1',
    'E2_seguimiento_T2':      'E2: seguimiento individual T2',
    'E3_MIMO_simultaneo':     'E3: seguimiento simultáneo (MIMO)',
    'E4_rechazo_perturbacion':'E4: rechazo de perturbación',
    'E5_robustez_areas':      'E5: robustez (áreas de orificio +5%)',
}


def cargar(ensayo, ctrl):
    """Carga un CSV de ensayo/controlador."""
    return pd.read_csv(f'{ensayo}_{ctrl}.csv')


def grafico_respuesta(clave, titulo):
    """Respuestas de nivel y1, y2 vs referencia, PI y H-inf superpuestos."""
    pi = cargar(clave, 'PI')
    hi = cargar(clave, 'Hinf')

    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)

    # Canal 1
    ax[0].plot(pi['t'], pi['r1'], '--', color=COLOR_REF, lw=1.2, label='Referencia')
    ax[0].plot(pi['t'], pi['y1'], '-', color=COLOR_PI, lw=1.6, label='PI')
    ax[0].plot(hi['t'], hi['y1'], '-', color=COLOR_HINF, lw=1.6, label='H-infinito')
    ax[0].set_ylabel(r'$y_1 = k_c\,h_1$  [V]')
    ax[0].legend(loc='best', fontsize=9)

    # Canal 2
    ax[1].plot(pi['t'], pi['r2'], '--', color=COLOR_REF, lw=1.2, label='Referencia')
    ax[1].plot(pi['t'], pi['y2'], '-', color=COLOR_PI, lw=1.6, label='PI')
    ax[1].plot(hi['t'], hi['y2'], '-', color=COLOR_HINF, lw=1.6, label='H-infinito')
    ax[1].set_ylabel(r'$y_2 = k_c\,h_2$  [V]')
    ax[1].set_xlabel('Tiempo [s]')
    ax[1].legend(loc='best', fontsize=9)

    fig.suptitle(titulo, fontsize=12)
    fig.tight_layout()
    fig.savefig(f'fig_{clave}_respuesta.png')
    plt.close(fig)


def grafico_control(clave, titulo):
    """Señales de control u1, u2, PI y H-inf superpuestos."""
    pi = cargar(clave, 'PI')
    hi = cargar(clave, 'Hinf')

    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)

    ax[0].plot(pi['t'], pi['u1'], '-', color=COLOR_PI, lw=1.6, label='PI')
    ax[0].plot(hi['t'], hi['u1'], '-', color=COLOR_HINF, lw=1.6, label='H-infinito')
    ax[0].set_ylabel(r'$u_1$  [V]')
    ax[0].legend(loc='best', fontsize=9)

    ax[1].plot(pi['t'], pi['u2'], '-', color=COLOR_PI, lw=1.6, label='PI')
    ax[1].plot(hi['t'], hi['u2'], '-', color=COLOR_HINF, lw=1.6, label='H-infinito')
    ax[1].set_ylabel(r'$u_2$  [V]')
    ax[1].set_xlabel('Tiempo [s]')
    ax[1].legend(loc='best', fontsize=9)

    fig.suptitle(f'{titulo}. Señales de control', fontsize=12)
    fig.tight_layout()
    fig.savefig(f'fig_{clave}_control.png')
    plt.close(fig)


def grafico_PI(clave):
    """Ilustración del Cap. 4: solo PI. Panel superior: niveles h1, h2 y
    referencias [cm]. Panel inferior: señales de bomba u1, u2 y límite de 12 V.
    Sin título dentro de la imagen: el título va en el caption de LaTeX."""
    pi = cargar(clave, 'PI')
    fig, ax = plt.subplots(2, 1, figsize=(8, 6), sharex=True)

    ax[0].plot(pi['t'], pi['r1'] / KC, '--', color=COLOR_PI, lw=1.0, alpha=0.7, label=r'$r_1$')
    ax[0].plot(pi['t'], pi['h1'], '-', color=COLOR_PI, lw=1.6, label=r'$h_1$')
    ax[0].plot(pi['t'], pi['r2'] / KC, '--', color=COLOR_HINF, lw=1.0, alpha=0.7, label=r'$r_2$')
    ax[0].plot(pi['t'], pi['h2'], '-', color=COLOR_HINF, lw=1.6, label=r'$h_2$')
    ax[0].set_ylabel('Nivel [cm]')
    ax[0].legend(loc='best', fontsize=9, ncol=2)

    ax[1].plot(pi['t'], pi['u1'], '-', color=COLOR_PI, lw=1.6, label=r'$u_1$')
    ax[1].plot(pi['t'], pi['u2'], '-', color=COLOR_HINF, lw=1.6, label=r'$u_2$')
    ax[1].axhline(U_MAX, ls=':', color=COLOR_REF, lw=1.2, label='Límite 12 V')
    ax[1].set_ylim(0, U_MAX + 1)
    ax[1].set_ylabel('Señal de bomba [V]')
    ax[1].set_xlabel('Tiempo [s]')
    ax[1].set_xlim(pi['t'].iloc[0], pi['t'].iloc[-1])
    ax[1].legend(loc='lower right', fontsize=9, ncol=3)

    fig.tight_layout()
    os.makedirs('figuras', exist_ok=True)
    n = clave.split('_')[0]                  # 'E1'..'E5'
    fig.savefig(os.path.join('figuras', f'{n}_PI.png'))
    plt.close(fig)


def grafico_barras_IAE():
    """Barras comparativas de IAE total por ensayo."""
    m = pd.read_csv('resumen_metricas_E1E5.csv')
    orden = list(ensayos.keys())
    etiquetas = ['E1', 'E2', 'E3', 'E4', 'E5']

    iae_pi   = [m[(m.ensayo == e) & (m.ctrl == 'PI')]['IAE_total'].values[0]   for e in orden]
    iae_hinf = [m[(m.ensayo == e) & (m.ctrl == 'Hinf')]['IAE_total'].values[0] for e in orden]

    x = np.arange(len(orden)); w = 0.38
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.bar(x - w/2, iae_pi,   w, color=COLOR_PI,   label='PI')
    ax.bar(x + w/2, iae_hinf, w, color=COLOR_HINF, label='H-infinito')
    ax.set_xticks(x); ax.set_xticklabels(etiquetas)
    ax.set_ylabel('IAE total'); ax.set_title('Comparación de IAE total por ensayo')
    ax.legend()
    for i, (a, b) in enumerate(zip(iae_pi, iae_hinf)):
        ax.text(i - w/2, a, f'{a:.1f}', ha='center', va='bottom', fontsize=8)
        ax.text(i + w/2, b, f'{b:.1f}', ha='center', va='bottom', fontsize=8)
    fig.tight_layout()
    fig.savefig('fig_IAE_comparacion.png')
    plt.close(fig)


def grafico_IAE_cruzado():
    """Barras de IAE cruzado (acoplamiento) en E1 y E2."""
    m = pd.read_csv('resumen_metricas_E1E5.csv')
    ens = ['E1_seguimiento_T1', 'E2_seguimiento_T2']
    etiquetas = ['E1', 'E2']

    cruz_pi   = [m[(m.ensayo == e) & (m.ctrl == 'PI')]['IAE_cruzado'].values[0]   for e in ens]
    cruz_hinf = [m[(m.ensayo == e) & (m.ctrl == 'Hinf')]['IAE_cruzado'].values[0] for e in ens]

    x = np.arange(len(ens)); w = 0.38
    fig, ax = plt.subplots(figsize=(6, 4.5))
    ax.bar(x - w/2, cruz_pi,   w, color=COLOR_PI,   label='PI')
    ax.bar(x + w/2, cruz_hinf, w, color=COLOR_HINF, label='H-infinito')
    ax.set_xticks(x); ax.set_xticklabels(etiquetas)
    ax.set_ylabel('IAE cruzado (acoplamiento)')
    ax.set_title('Interacción entre canales (menor es mejor)')
    ax.legend()
    for i, (a, b) in enumerate(zip(cruz_pi, cruz_hinf)):
        ax.text(i - w/2, a, f'{a:.2f}', ha='center', va='bottom', fontsize=8)
        ax.text(i + w/2, b, f'{b:.2f}', ha='center', va='bottom', fontsize=8)
    fig.tight_layout()
    fig.savefig('fig_IAE_cruzado.png')
    plt.close(fig)


def main():
    for clave, titulo in ensayos.items():
        grafico_respuesta(clave, titulo)
        grafico_control(clave, titulo)
        grafico_PI(clave)
        print(f'  {clave}: respuesta + control + figura PI del Cap. 4 OK')
    grafico_barras_IAE()
    grafico_IAE_cruzado()
    print('  fig_IAE_comparacion.png OK')
    print('  fig_IAE_cruzado.png OK')
    print('\nTodos los gráficos generados.')


if __name__ == '__main__':
    main()