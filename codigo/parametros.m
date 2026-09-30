%% parametros.m
% Parametros fisicos de la planta de laboratorio de cuatro tanques.
%
% Planta base: Pedroso & Batista (2022). La planta se construira en el
% laboratorio replicando ese montaje, por lo que se adoptan sus parametros
% identificados (areas de seccion, orificios, valvulas de tres vias y
% bombas VMA421 de 12 V). El modelo no lineal es el de Johansson (2000).
%
% Los valores se leen desde geometria_planta.m (fuente unica).
% Punto de operacion: h1 = h2 = 14 cm, fase minima (g1+g2 > 1).

clear; clc;

geometria = 'pedroso';
p = geometria_planta(geometria);

% --- Areas de seccion transversal de los tanques [cm^2] ---
A1 = p.A(1);  A2 = p.A(2);  A3 = p.A(3);  A4 = p.A(4);

% --- Areas de los orificios de salida [cm^2] ---
a1 = p.a(1);  a2 = p.a(2);  a3 = p.a(3);  a4 = p.a(4);

% --- Ganancia de medicion [V/cm] y gravedad [cm/s^2] ---
kc = p.kc;
g  = p.g;

% --- Valvulas de tres vias ---
gamma1 = p.gamma1;
gamma2 = p.gamma2;

% --- Constantes de las bombas [cm^3/(V s)] y saturacion [V] ---
k1 = p.k1;
k2 = p.k2;
u_min = p.u_min;
u_max = p.u_max;

% --- Altura util de los tanques [cm] ---
H_tanque = p.H_tanque;

% --- Punto de operacion ---
% Semilla: solucion analitica. equilibrio.m la refina con fsolve y la
% guarda en punto_operacion.mat junto con el nombre de la geometria.
x0_nominal = p.x0_semilla;
u0_nominal = p.u0_semilla;

usa_exacto = false;
if exist('punto_operacion.mat','file')
    pt = load('punto_operacion.mat');
    if isfield(pt,'geometria') && strcmp(pt.geometria, geometria)
        x0 = pt.x0;  u0 = pt.u0;  usa_exacto = true;
    end
end
if usa_exacto
    fprintf('Punto de operacion: EXACTO (fsolve)\n');
else
    x0 = x0_nominal;  u0 = u0_nominal;
    fprintf('Punto de operacion: ANALITICO. Corre equilibrio.m para refinar.\n');
end

% --- Constantes de tiempo T_i = (A_i/a_i) * sqrt(2*h_i/g) [s] ---
T1 = (A1/a1) * sqrt(2*x0(1)/g);
T2 = (A2/a2) * sqrt(2*x0(2)/g);
T3 = (A3/a3) * sqrt(2*x0(3)/g);
T4 = (A4/a4) * sqrt(2*x0(4)/g);

fprintf('Geometria: %s\n', p.fuente);
fprintf('Punto de operacion: h = [%.3f %.3f %.3f %.3f] cm, u0 = [%.3f %.3f] V\n', x0, u0);
fprintf('Constantes de tiempo [s]: T1=%.2f  T2=%.2f  T3=%.2f  T4=%.2f\n', T1, T2, T3, T4);
fprintf('Condicion fase minima (1 < g1+g2 < 2): g1+g2 = %.4f\n', gamma1+gamma2);
