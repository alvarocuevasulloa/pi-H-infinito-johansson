%% diseno_hinf.m
% Diseño del controlador robusto H-infinito para el proceso de cuatro tanques (P-)
% Método: sensibilidad mixta (mixed-sensitivity) con mixsyn
% Requiere: Robust Control Toolbox
%
% Criterios de diseño (ver Cap. 3, filosofía de control):
%  - Acción integral: error cero en estado estacionario ante referencia constante.
%  - Ancho de banda objetivo wb = 0.1 rad/s. Se fijo para la geometria
%    anterior; con la planta de Pedroso & Batista resulta conservador frente
%    al PI (lambda = tau/10, cerca de 0.25 rad/s). Se mantiene sin re-sintonizar
%    (ver Anexo A: re-sintonizar los pesos queda como trabajo futuro).
%  - Esfuerzo de control conservador: las bombas son DC pequeñas (caudal
%    limitado), por lo que Wu penaliza la acción de control a alta frecuencia
%    para mantener señales suaves y aumentar la robustez.

clear; clc; close all;
parametros;
load('modelo_lineal.mat','sys_c');

G = sys_c;   % planta nominal (2x2, entradas u1,u2 ; salidas y1,y2)

%% 1. Función de peso de desempeño Wp (actúa sobre la sensibilidad S)
% Forma estándar (Skogestad & Postlethwaite, 2005):
%   Wp(s) = (s/M + wb) / (s + wb*A)
% con:
%   M  = pico máximo permitido de |S| (margen de robustez). M=2 es estándar.
%   wb = ancho de banda deseado en lazo cerrado [rad/s].
%   A  = error máximo en estado estacionario. A -> 0 da acción integral
%        (seguimiento sin error a referencia constante).

M_p  = 2.0;       % pico de sensibilidad <= 2 (margen de módulo ~0.5)
wb   = 0.10;      % ancho de banda objetivo [rad/s] (conservador, ver cabecera)
A_p  = 1e-4;      % ~integrador: error de estado estacionario despreciable

wp_scalar = tf([1/M_p  wb], [1  wb*A_p]);

% Se aplica el mismo peso a los dos canales de salida (sistema simétrico)
Wp = blkdiag(wp_scalar, wp_scalar);

%% 2. Función de peso de esfuerzo de control Wu (actúa sobre K*S)
% Penaliza la acción de control, creciente con la frecuencia, para limitar
% el esfuerzo de las bombas y mantener señales suaves (diseño conservador).
%   Wu(s) = (s + wbu/Mu) / (eps*s + wbu)
% Interpretación: ganancia baja a baja frecuencia (deja actuar al control en
% la banda de trabajo) y ganancia alta a alta frecuencia (penaliza cambios
% bruscos que la bomba no puede seguir).

Mu   = 1e2;       % penalización de control a alta frecuencia
wbu  = 1.0;       % frecuencia a partir de la cual se penaliza el control
eps_u = 1e-3;     % límite de alta frecuencia del peso

wu_scalar = tf([1  wbu/Mu], [eps_u  wbu]);
Wu = blkdiag(wu_scalar, wu_scalar);

%% 3. Peso Wt (opcional, sobre T). No se usa aquí (se deja vacío).
Wt = [];

%% 4. Síntesis H-infinito por sensibilidad mixta
% mixsyn resuelve el problema de sensibilidad mixta:
%   min_K  || [ Wp*S ; Wu*K*S ; Wt*T ] ||_inf
% La síntesis interna se apoya en ecuaciones de Riccati (Zhou et al., 1996).
[K, CL, gamma] = mixsyn(G, Wp, Wu, Wt);

fprintf('=== Síntesis H-infinito (mixsyn) ===\n');
fprintf('Gamma alcanzado: %.4f\n', gamma);
if gamma < 1.1
    fprintf('  Diseño bueno: gamma cercano a 1, objetivos de peso cumplidos.\n');
elseif gamma < 2
    fprintf('  Diseño aceptable: gamma < 2, revisar pesos si se busca afinar.\n');
else
    fprintf('  ATENCIÓN: gamma alto (%.2f). Relajar Wp o Wu.\n', gamma);
end
fprintf('Orden del controlador K: %d estados\n', order(K));

%% 5. Verificación de estabilidad en lazo cerrado
L = G*K;                       % lazo abierto
S = feedback(eye(2), L);       % sensibilidad
T = eye(2) - S;                % sensibilidad complementaria

polos_cl = pole(feedback(G*K, eye(2)));
fprintf('\n=== Estabilidad en lazo cerrado ===\n');
if all(real(polos_cl) < 0)
    fprintf('  Lazo cerrado ESTABLE (todos los polos en semiplano izquierdo).\n');
else
    fprintf('  ATENCIÓN: hay polos inestables en lazo cerrado.\n');
end
fprintf('  Parte real máxima de los polos de LC: %.4f\n', max(real(polos_cl)));

%% 6. Picos de S y T (indicadores de robustez)
Ms = norm(S, inf);   % pico de sensibilidad
Mt = norm(T, inf);   % pico de sensibilidad complementaria
fprintf('\n=== Indicadores de robustez ===\n');
fprintf('  Pico de sensibilidad     Ms = ||S||_inf = %.3f (deseable < 2)\n', Ms);
fprintf('  Pico complementaria      Mt = ||T||_inf = %.3f (deseable < 1.5)\n', Mt);

%% 7. Ganancia DC de T (verifica seguimiento sin error)
Tdc = dcgain(T);
fprintf('\n=== Seguimiento en estado estacionario ===\n');
fprintf('  T(0) (debe ser ~identidad para error cero):\n');
disp(Tdc);

%% 8. Guardar el controlador para la validación
save('hinf_controller.mat', 'K', 'gamma', 'Wp', 'Wu', ...
    'M_p', 'wb', 'A_p', 'Mu', 'wbu', 'Ms', 'Mt');
fprintf('\nControlador H-infinito guardado en hinf_controller.mat\n');

%% 9. Gráficos de verificación (valores singulares de S y T)
figure('Name','H-infinito: sensibilidad S y T','Position',[100 100 900 500]);
sigma(S, 'b', T, 'r--', 1/wp_scalar, 'k:');
legend('S (sensibilidad)','T (complementaria)','1/Wp (cota)','Location','best');
grid on; title('Valores singulares en lazo cerrado');
exportgraphics(gcf, 'hinf_sigma.png', 'Resolution', 300);