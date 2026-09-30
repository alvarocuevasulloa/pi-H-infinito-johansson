%% comparacion_E1E5.m
% Compara el PI descentralizado y el H-infinito sobre el modelo NO LINEAL
% de la planta de laboratorio de cuatro tanques (modelo de Johansson con
% los parámetros identificados de Pedroso & Batista, 2022), en cinco
% escenarios de validación (E1-E5).
% Exporta un CSV por ensayo y controlador (para post-proceso en Python y
% para la visualización en Factory I/O) y una tabla resumen de métricas.
% El CSV incluye los cuatro niveles h1..h4 [cm].
%
% Requiere en la carpeta:
%   parametros.m
%   modelo_lineal.mat  (x0, u0)
%   pi_controllers.mat (Kp_1,Ki_1,Kp_2,Ki_2)
%   hinf_controller.mat (K)  <- controlador H-infinito de mixsyn
%
% Escenarios:
%   E1: seguimiento individual, escalón +1.5 cm en referencia de h1
%   E2: seguimiento individual, escalón +1.5 cm en referencia de h2
%   E3: seguimiento simultáneo (MIMO), +1.5 cm en h1 y h2 a la vez
%   E4: rechazo de perturbación de carga (-10% caudal salida de T1), ref fijas
%   E5: robustez: E3 con las áreas de orificio a_i perturbadas +5%

clear; clc; close all;
parametros;
load('modelo_lineal.mat','x0','u0');
load('pi_controllers.mat','Kp_1','Ki_1','Kp_2','Ki_2');
load('hinf_controller.mat','K');

% Pasar el H-infinito a espacio de estados (para integrarlo con la planta)
Kss = ss(K);
Ak = Kss.A;  Bk = Kss.B;  Ck = Kss.C;  Dk = Kss.D;
nk = size(Ak,1);   % nº de estados del controlador H-infinito

% Salidas en el punto de operación (para trabajar en variables absolutas)
y_op = kc * [x0(1); x0(2)];

% Parámetros de simulación
% t_final cubre ~5 veces la constante de tiempo más lenta (redondeado a
% 100 s). Con los parámetros de Pedroso & Batista la más lenta es
% T3 ~ 108 s, por lo que t_final = 600 s.
% Los instantes de escalón (t = 20 s) y de perturbación (t = 100 s) no se
% escalan: la simulación parte en el equilibrio exacto, así que no hay
% transitorio inicial que esperar.
t_final = 100*ceil(5*max([T1 T2 T3 T4])/100);   % [s]
dt      = 0.1;                  % paso de muestreo para métricas [s]
tvec    = (0:dt:t_final)';
N       = numel(tvec);

% Límites del actuador (bombas VMA421): u_min y u_max vienen de
% parametros.m (0 a 12 V).

%% ====================== DEFINICIÓN DE ESCENARIOS ======================
% Cada escenario define: referencias r1(t), r2(t) [en V], perturbación, y
% posible variación de parámetros. Salidas y refs en VOLTIOS (y = kc*h).

esc = struct();

% Escalón de referencia estándar: +1.5 cm = +0.75 V
dref = kc * 1.5;

% E1: solo h1 sube
esc(1).nombre = 'E1_seguimiento_T1';
esc(1).r = @(t) [y_op(1) + dref*(t>=20);  y_op(2)];
esc(1).perturb = @(t) [0;0;0;0];
esc(1).area_factor = 1.0;

% E2: solo h2 sube
esc(2).nombre = 'E2_seguimiento_T2';
esc(2).r = @(t) [y_op(1);  y_op(2) + dref*(t>=20)];
esc(2).perturb = @(t) [0;0;0;0];
esc(2).area_factor = 1.0;

% E3: ambos suben (MIMO, se observa el acoplamiento)
esc(3).nombre = 'E3_MIMO_simultaneo';
esc(3).r = @(t) [y_op(1) + dref*(t>=20);  y_op(2) + dref*(t>=20)];
esc(3).perturb = @(t) [0;0;0;0];
esc(3).area_factor = 1.0;

% E4: referencias fijas, perturbación de carga en T1 a t=100 s
% (-10% del caudal de salida nominal de T1, como extracción constante)
q_out1_nom = a1*sqrt(2*g*x0(1));           % caudal de salida nominal de T1 [cm3/s]
d_carga    = 0.10 * q_out1_nom;            % magnitud de la fuga [cm3/s]
esc(4).nombre = 'E4_rechazo_perturbacion';
esc(4).r = @(t) [y_op(1);  y_op(2)];
esc(4).perturb = @(t) [-d_carga*(t>=100)/A1; 0; 0; 0];   % afecta dh1/dt
esc(4).area_factor = 1.0;

% E5: robustez. Igual a E3 pero con áreas de orificio +5% (incertidumbre de
% modelo realista: las áreas de orificio reales difieren de las nominales por
% manufactura y desgaste). +5% mantiene el corrimiento del equilibrio
% comparable al escalón de referencia, de modo que la prueba aísla la robustez
% y no impone una perturbación que descuadre el punto de operación.
esc(5).nombre = 'E5_robustez_areas';
esc(5).r = @(t) [y_op(1) + dref*(t>=20);  y_op(2) + dref*(t>=20)];
esc(5).perturb = @(t) [0;0;0;0];
esc(5).area_factor = 1.05;                 % +5% en a1..a4

%% ====================== BUCLE DE SIMULACIÓN ======================
controladores = {'PI','Hinf'};
resumen = struct([]);   % acumula métricas como array de structs
idx = 0;

for e = 1:numel(esc)
    for c = 1:numel(controladores)
        ctrl = controladores{c};

        % Simular lazo cerrado sobre la planta no lineal
        [t, y, u, r, h] = simular(ctrl, esc(e), x0, u0, y_op, t_final, ...
            Kp_1,Ki_1,Kp_2,Ki_2, Ak,Bk,Ck,Dk,nk, ...
            u_min,u_max, A1,A2,A3,A4, a1,a2,a3,a4, g, ...
            gamma1,gamma2, k1,k2, kc);

        % Remuestrear a la grilla uniforme para métricas y CSV
        yi = interp1(t, y, tvec);
        ui = interp1(t, u, tvec);
        ri = interp1(t, r, tvec);
        hi = interp1(t, h, tvec);

        % Guardar CSV (tiempo, ref1, ref2, y1, y2, u1, u2, h1..h4)
        % y, r y u en V; h en cm.
        fname = sprintf('%s_%s.csv', esc(e).nombre, ctrl);
        Tcsv = array2table([tvec, ri, yi, ui, hi], ...
            'VariableNames', {'t','r1','r2','y1','y2','u1','u2','h1','h2','h3','h4'});
        writetable(Tcsv, fname);

        % Métricas (se acumulan en un array de structs con orden de campos fijo)
        m = metricas(tvec, ri, yi);
        idx = idx + 1;
        resumen(idx).ensayo      = string(esc(e).nombre);
        resumen(idx).ctrl        = string(ctrl);
        resumen(idx).IAE_total   = m.IAE_total;
        resumen(idx).ISE_total   = m.ISE_total;
        resumen(idx).IAE1        = m.IAE1;
        resumen(idx).IAE2        = m.IAE2;
        resumen(idx).IAE_cruzado = m.IAE_cruzado;
        resumen(idx).Mp          = m.Mp;
        resumen(idx).ts          = m.ts;
        resumen(idx).ess         = m.ess;

        fprintf('%s | %-24s | IAE=%.3f  IAE_cruz=%.3f\n', ...
            ctrl, esc(e).nombre, m.IAE_total, m.IAE_cruzado);
    end
end

resumen = struct2table(resumen);   % una sola conversión al final

writetable(resumen, 'resumen_metricas_E1E5.csv');
fprintf('\nCSVs por ensayo + resumen_metricas_E1E5.csv generados.\n');

%% ====================== FUNCIONES ======================

function [t, y, u, r, h] = simular(ctrl, sc, x0, u0, y_op, t_final, ...
        Kp_1,Ki_1,Kp_2,Ki_2, Ak,Bk,Ck,Dk,nk, ...
        u_min,u_max, A1,A2,A3,A4, a1,a2,a3,a4, g, gamma1,gamma2, k1,k2, kc)

    % Áreas de orificio efectivas (E5 las perturba)
    af = sc.area_factor;
    a1e=a1*af; a2e=a2*af; a3e=a3*af; a4e=a4*af;

    % Estado aumentado: [planta(4); integradores/estados-controlador]
    if strcmp(ctrl,'PI')
        z0 = [x0; 0; 0];            % 2 integradores del PI
    else
        z0 = [x0; zeros(nk,1)];     % nk estados del H-infinito
    end

    odefun = @(t,z) dinamica(t,z,ctrl,sc,y_op,u0, ...
        Kp_1,Ki_1,Kp_2,Ki_2, Ak,Bk,Ck,Dk,nk, ...
        u_min,u_max, A1,A2,A3,A4, a1e,a2e,a3e,a4e, g, ...
        gamma1,gamma2, k1,k2, kc);

    opts = odeset('RelTol',1e-6,'AbsTol',1e-8,'MaxStep',0.5);
    [t, Z] = ode45(odefun, [0 t_final], z0, opts);

    h = Z(:,1:4);
    y = kc * h(:,1:2);
    % Reconstruir r evaluando la referencia en cada instante (esc.r está
    % definida para t escalar; evaluarla vectorizada da dimensiones
    % inconsistentes, por eso se hace punto por punto).
    r = zeros(numel(t),2);
    for i=1:numel(t)
        ri_ = sc.r(t(i));
        r(i,:) = ri_(:)';
    end
    % Reconstruir u aplicada (recalcular la ley de control en cada t)
    u = zeros(numel(t),2);
    for i=1:numel(t)
        u(i,:) = ley_control(t(i), Z(i,:)', ctrl, sc, y_op, u0, ...
            Kp_1,Ki_1,Kp_2,Ki_2, Ck,Dk,nk, u_min,u_max, kc)';
    end
end

function dz = dinamica(t,z,ctrl,sc,y_op,u0, ...
        Kp_1,Ki_1,Kp_2,Ki_2, Ak,Bk,Ck,Dk,nk, ...
        u_min,u_max, A1,A2,A3,A4, a1,a2,a3,a4, g, gamma1,gamma2, k1,k2, kc)

    h = z(1:4);
    h1=max(h(1),0); h2=max(h(2),0); h3=max(h(3),0); h4=max(h(4),0);

    % Ley de control -> u aplicada (saturada)
    u = ley_control(t, z, ctrl, sc, y_op, u0, ...
        Kp_1,Ki_1,Kp_2,Ki_2, Ck,Dk,nk, u_min,u_max, kc);

    % Perturbación de carga (afecta derivadas de nivel)
    p = sc.perturb(t);

    % Dinámica de la planta no lineal
    dh = zeros(4,1);
    dh(1) = -a1/A1*sqrt(2*g*h1) + a3/A1*sqrt(2*g*h3) + gamma1*k1/A1*u(1) + p(1);
    dh(2) = -a2/A2*sqrt(2*g*h2) + a4/A2*sqrt(2*g*h4) + gamma2*k2/A2*u(2) + p(2);
    dh(3) = -a3/A3*sqrt(2*g*h3)                       + (1-gamma2)*k2/A3*u(2) + p(3);
    dh(4) = -a4/A4*sqrt(2*g*h4)                       + (1-gamma1)*k1/A4*u(1) + p(4);

    % Dinámica del controlador
    y = kc*[h1; h2];
    r = sc.r(t);
    err = r - y;                     % error en voltios
    if strcmp(ctrl,'PI')
        de = err;                    % dot(integral) = error
        dz = [dh; de];
    else
        xk = z(5:4+nk);
        dxk = Ak*xk + Bk*err;        % estados del H-infinito
        dz = [dh; dxk];
    end
end

function u = ley_control(t, z, ctrl, sc, y_op, u0, ...
        Kp_1,Ki_1,Kp_2,Ki_2, Ck,Dk,nk, u_min,u_max, kc)
    h = z(1:4);
    y = kc*[max(h(1),0); max(h(2),0)];
    r = sc.r(t);
    err = r - y;
    if strcmp(ctrl,'PI')
        integ = z(5:6);
        du1 = Kp_1*err(1) + Ki_1*integ(1);
        du2 = Kp_2*err(2) + Ki_2*integ(2);
        u = u0 + [du1; du2];         % incremento sobre el nominal
    else
        xk = z(5:4+nk);
        du = Ck*xk + Dk*err;         % salida del H-infinito (incremento)
        u = u0 + du;
    end
    u = min(max(u, u_min), u_max);   % saturación del actuador
end

function m = metricas(t, r, y)
    e = r - y;                       % Nx2
    dt = mean(diff(t));
    % IAE por canal e IAE total
    IAE1 = trapz(t, abs(e(:,1)));
    IAE2 = trapz(t, abs(e(:,2)));
    ISE1 = trapz(t, e(:,1).^2);
    ISE2 = trapz(t, e(:,2).^2);
    m.IAE_total = IAE1 + IAE2;
    m.ISE_total = ISE1 + ISE2;
    m.IAE1 = IAE1;  m.IAE2 = IAE2;
    % IAE cruzado: cuánto se movió el canal que NO recibió el escalón.
    % Se aproxima por la desviación del canal cuya referencia se mantuvo fija.
    fija1 = all(abs(r(:,1)-r(1,1))<1e-9);
    fija2 = all(abs(r(:,2)-r(1,2))<1e-9);
    if fija1 && ~fija2
        m.IAE_cruzado = trapz(t, abs(y(:,1)-r(:,1)));
    elseif fija2 && ~fija1
        m.IAE_cruzado = trapz(t, abs(y(:,2)-r(:,2)));
    else
        m.IAE_cruzado = 0;           % ambos se mueven (E3/E5) o ninguno
    end
    % Sobreimpulso y ts sobre el canal dominante (el de mayor cambio de ref)
    d1 = abs(r(end,1)-r(1,1));  d2 = abs(r(end,2)-r(1,2));
    if d1>=d2, ch=1; else, ch=2; end
    m.Mp = sobreimpulso(y(:,ch), r(:,ch));
    m.ts = t_establecimiento(t, y(:,ch), r(:,ch));
    m.ess = abs(r(end,ch)-y(end,ch));
end

function Mp = sobreimpulso(y, r)
    rf = r(end); r0 = y(1); paso = rf - r0;
    if abs(paso)<1e-9, Mp=0; return; end
    if paso>0, pico = max(y); Mp = max(0,(pico-rf)/paso)*100;
    else,      pico = min(y); Mp = max(0,(rf-pico)/abs(paso))*100; end
end

function ts = t_establecimiento(t, y, r)
    rf = r(end); r0 = y(1); banda = 0.02*abs(rf-r0);
    if banda<1e-9, ts=0; return; end
    fuera = abs(y-rf) > banda;
    idx = find(fuera, 1, 'last');
    if isempty(idx), ts=0; else, ts=t(min(idx+1,numel(t))); end
end