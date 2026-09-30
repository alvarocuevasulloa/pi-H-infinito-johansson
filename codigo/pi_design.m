%% pi_design.m
% Diseño del controlador PI descentralizado para el proceso de cuatro tanques (P-)
% Método: aproximación a FOPDT + sintonía IMC con margen de fase objetivo

clear; clc; close all;
parametros;
load('modelo_lineal.mat','sys_c');

%% 1. Extraer funciones de transferencia individuales del MIMO
G = tf(sys_c);
g11 = G(1,1);   % y1 / u1
g22 = G(2,2);   % y2 / u2

fprintf('=== Funciones de transferencia de los lazos principales ===\n');
fprintf('\ng11(s) = y1/u1:\n'); g11
fprintf('\ng22(s) = y2/u2:\n'); g22

%% 2. Aproximar a modelos FOPDT
[K_11, tau_11, theta_11] = fopdt_fit(g11);
[K_22, tau_22, theta_22] = fopdt_fit(g22);

fprintf('\n=== Modelos FOPDT aproximados ===\n');
fprintf('Lazo 1: K=%.3f  tau=%.2f s  theta=%.2f s\n', K_11, tau_11, theta_11);
fprintf('Lazo 2: K=%.3f  tau=%.2f s  theta=%.2f s\n', K_22, tau_22, theta_22);

%% 3. Sintonía IMC con lambda explícito (agresivo)
% Para FOPDT sin retardo, lambda controla directamente la velocidad
% de respuesta en lazo cerrado. Regla industrial agresiva: lambda = tau/10
% (lazo cerrado ~10x más rápido que la planta abierta)

lambda_1 = tau_11 / 10;
lambda_2 = tau_22 / 10;

Kp_1 = (1/K_11) * tau_11 / (lambda_1 + theta_11);
Ti_1 = tau_11;
Ki_1 = Kp_1 / Ti_1;

Kp_2 = (1/K_22) * tau_22 / (lambda_2 + theta_22);
Ti_2 = tau_22;
Ki_2 = Kp_2 / Ti_2;

% Verificar márgenes resultantes (informativo)
L_1 = tf([Kp_1 Ki_1],[1 0]) * g11;
L_2 = tf([Kp_2 Ki_2],[1 0]) * g22;
[~, Pm_1] = margin(L_1);
[~, Pm_2] = margin(L_2);

% Tiempo de subida deseado en lazo cerrado (aprox)
ts_1 = 4 * lambda_1;   % regla práctica para FOPDT
ts_2 = 4 * lambda_2;

fprintf('\n=== Controladores PI sintonizados (IMC, lambda=tau/10) ===\n');
fprintf('PI1: Kp=%.3f  Ti=%.2f s  Ki=%.5f  (lambda=%.2f s, PM=%.1f°, ts≈%.1f s)\n', ...
    Kp_1, Ti_1, Ki_1, lambda_1, Pm_1, ts_1);
fprintf('PI2: Kp=%.3f  Ti=%.2f s  Ki=%.5f  (lambda=%.2f s, PM=%.1f°, ts≈%.1f s)\n', ...
    Kp_2, Ti_2, Ki_2, lambda_2, Pm_2, ts_2);

%% 4. Guardar parámetros del PI
save('pi_controllers.mat', 'Kp_1','Ti_1','Ki_1','Kp_2','Ti_2','Ki_2', ...
    'K_11','tau_11','theta_11','K_22','tau_22','theta_22', ...
    'lambda_1','lambda_2','Pm_1','Pm_2');
fprintf('\nParámetros guardados en pi_controllers.mat\n');

%% --- Función auxiliar para ajustar FOPDT ---
function [K, tau, theta] = fopdt_fit(G)
K = dcgain(G);
[y, t] = step(G);
yf = K;
y_norm = y / yf;
t1 = interp1(y_norm, t, 0.353, 'linear');
t2 = interp1(y_norm, t, 0.853, 'linear');
tau = 0.67 * (t2 - t1);
theta = 1.3*t1 - 0.29*t2;
if theta < 0
    theta = 0.01;
end
end
