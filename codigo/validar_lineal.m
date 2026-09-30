%% validar_lineal.m
% Compara la respuesta del modelo NO LINEAL vs LINEAL ante un escalón
% pequeño en u1 alrededor del punto de operación P-.
% Si coinciden cerca del punto, la linealización está bien hecha.

clear; clc; close all;

% Cargar parámetros y modelo lineal
parametros;
load('modelo_lineal.mat','sys_c','x0','u0');

%% 1. Simular modelo NO LINEAL con ode45
% Horizonte: ~5 veces la constante de tiempo mas lenta, redondeado a 100 s
% (planta base de Pedroso & Batista: T3 ~ 108 s -> 600 s)
t_final = 100*ceil(5*max([T1 T2 T3 T4])/100);   % [s]
du1 = 0.3;             % escalón pequeño en u1 [V]
du2 = 0;

% Entradas absolutas constantes (escalón aplicado en t=0)
u1_in = u0(1) + du1;
u2_in = u0(2) + du2;

% Ecuaciones no lineales (sin función anónima anidada)
nl_dynamics = @(t,x) [
    -a1/A1*sqrt(2*g*max(x(1),1e-6)) + a3/A1*sqrt(2*g*max(x(3),1e-6)) + gamma1*k1/A1 * u1_in;
    -a2/A2*sqrt(2*g*max(x(2),1e-6)) + a4/A2*sqrt(2*g*max(x(4),1e-6)) + gamma2*k2/A2 * u2_in;
    -a3/A3*sqrt(2*g*max(x(3),1e-6))                                  + (1-gamma2)*k2/A3 * u2_in;
    -a4/A4*sqrt(2*g*max(x(4),1e-6))                                  + (1-gamma1)*k1/A4 * u1_in
];

% Tolerancias ajustadas: con las de defecto (RelTol 1e-3) el error numerico
% del integrador se confunde con el error de linealizacion.
opts_nl = odeset('RelTol', 1e-8, 'AbsTol', 1e-10);
[t_nl, x_nl] = ode45(nl_dynamics, [0 t_final], x0, opts_nl);
y_nl = kc * x_nl(:,1:2);

%% 2. Simular modelo LINEAL (en variables incrementales)
% Δu(t) = [du1; du2] aplicado al sistema lineal sys_c
t_lin = (0:0.5:t_final)';
du = repmat([du1 du2], length(t_lin), 1);
[y_lin_inc, ~, ~] = lsim(sys_c, du, t_lin);

% Reconstruir las salidas absolutas: y_abs = y_op + Δy
y_op = kc * [x0(1); x0(2)];   % salidas en el punto de operación
y_lin = y_lin_inc + y_op';

%% 3. Graficar comparación
figure('Name','Validación modelo lineal vs no lineal','Position',[100 100 900 600]);

subplot(2,1,1);
plot(t_nl, y_nl(:,1), 'b-', 'LineWidth', 1.8); hold on;
plot(t_lin, y_lin(:,1), 'r--', 'LineWidth', 1.5);
yline(y_op(1), 'k:', 'Punto operación');
xlabel('Tiempo [s]'); ylabel('y_1 = k_c \cdot h_1  [V]');
title(sprintf('Respuesta a escalón \\Delta u_1 = %.2f V', du1));
legend('No lineal (ode45)','Lineal (lsim)','Location','best');
grid on;

subplot(2,1,2);
plot(t_nl, y_nl(:,2), 'b-', 'LineWidth', 1.8); hold on;
plot(t_lin, y_lin(:,2), 'r--', 'LineWidth', 1.5);
yline(y_op(2), 'k:', 'Punto operación');
xlabel('Tiempo [s]'); ylabel('y_2 = k_c \cdot h_2  [V]');
legend('No lineal (ode45)','Lineal (lsim)','Location','best');
grid on;

% Guardar figura
% Tema claro para el documento impreso (MATLAB R2025a+ usa tema oscuro por defecto)
fig = gcf;
try, theme(fig, 'light'); catch, end
set(fig, 'Color', 'w');
set(findall(fig, 'Type', 'axes'), 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'GridColor', [0.15 0.15 0.15]);
set(findall(fig, 'Type', 'legend'), 'TextColor', 'k', 'Color', 'w', 'EdgeColor', [0.3 0.3 0.3]);
set(findall(fig, 'Type', 'text'), 'Color', 'k');
exportgraphics(gcf, 'validacion_lineal.png', 'Resolution', 300);
exportgraphics(gcf, 'validacion_lineal.pdf', 'ContentType', 'vector');
%% 4. Métrica numérica de discrepancia
% Interpolamos lineal a los tiempos del no lineal y calculamos error relativo
y_lin_interp = interp1(t_lin, y_lin, t_nl);
err_rel = abs(y_nl - y_lin_interp) ./ abs(y_op');
err_pct_max = max(err_rel) * 100;

fprintf('Error relativo máximo respecto al punto de operación:\n');
fprintf('  y_1: %.3f %%\n', err_pct_max(1));
fprintf('  y_2: %.3f %%\n', err_pct_max(2));

if max(err_pct_max) < 10
    fprintf('✓ Linealización aceptable (error < 10%% para Δu pequeño)\n');
else
    fprintf('⚠ Error alto. Revisa signos o tamaño del escalón.\n');
end