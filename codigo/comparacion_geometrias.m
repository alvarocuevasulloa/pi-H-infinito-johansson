%% comparacion_geometrias.m
% Anexo: comportamiento del mismo modelo de cuatro tanques con tres juegos
% de parametros fisicos, controlado con el mismo metodo de sintonia PI.
%
%   johansson : Johansson (2000), punto P- con u0 = (3, 3) V
%   meng196   : tanques de 14 x 14 cm (Meng et al., 2022) + Johansson
%   pedroso   : Pedroso & Batista (2022), h1 = h2 = 14 cm (planta base)
%
% Para cada geometria: equilibrio, linealizacion, constantes de tiempo,
% ceros de transmision, RGA, sintonia PI (IMC, lambda = tau/10, igual que
% pi_design.m) y ensayos E1-E5 sobre el modelo no lineal (igual que
% comparacion_E1E5.m).
%
% Es independiente: NO modifica punto_operacion.mat, modelo_lineal.mat,
% pi_controllers.mat ni los CSV de la planta base.
% Salidas: comparacion_geometrias.csv, comparacion_geometrias.mat,
%          comparacion_geometrias.png
% Requiere Control System Toolbox.

clear; clc; close all;

geos = {'johansson', 'meng196', 'pedroso'};
ng = numel(geos);
nombres_esc = {'E1','E2','E3','E4','E5'};

filas = {};
res = struct([]);

for ig = 1:ng
    p = geometria_planta(geos{ig});
    A = p.A;  a = p.a;  g = p.g;  kc = p.kc;
    g1 = p.gamma1;  g2 = p.gamma2;  k1 = p.k1;  k2 = p.k2;

    %% 1. Equilibrio (solucion analitica exacta de geometria_planta)
    x0 = p.x0_semilla;  u0 = p.u0_semilla;

    %% 2. Linealizacion (Jacobianos analiticos)
    dd = @(i) -a(i)/A(i)*sqrt(g/(2*x0(i)));
    Am = [dd(1) 0 a(3)/A(1)*sqrt(g/(2*x0(3))) 0;
          0 dd(2) 0 a(4)/A(2)*sqrt(g/(2*x0(4)));
          0 0 dd(3) 0;
          0 0 0 dd(4)];
    Bm = [g1*k1/A(1) 0; 0 g2*k2/A(2); 0 (1-g2)*k2/A(3); (1-g1)*k1/A(4) 0];
    Cm = [kc 0 0 0; 0 kc 0 0];
    sys = ss(Am, Bm, Cm, zeros(2));

    T  = A./a .* sqrt(2*x0'/g);
    z  = tzero(sys);
    G0 = dcgain(sys);
    lam11 = G0(1,1)*G0(2,2) / (G0(1,1)*G0(2,2) - G0(1,2)*G0(2,1));

    %% 3. PI descentralizado (mismo metodo que pi_design.m)
    Gtf = tf(sys);
    [K11, tau11, th11] = fopdt_fit(Gtf(1,1));
    [K22, tau22, th22] = fopdt_fit(Gtf(2,2));
    Kp1 = (1/K11)*tau11/(tau11/10 + th11);  Ti1 = tau11;  Ki1 = Kp1/Ti1;
    Kp2 = (1/K22)*tau22/(tau22/10 + th22);  Ti2 = tau22;  Ki2 = Kp2/Ti2;

    %% 4. Ensayos E1-E5 (modelo no lineal)
    t_final = 100*ceil(5*max(T)/100);
    tvec = (0:0.1:t_final)';
    yop  = kc*x0(1:2);
    dref = kc*1.5;
    dcar = 0.10*a(1)*sqrt(2*g*x0(1));
    for e = 1:5
        [tt, Z, rr, uu] = simular_pi(e, p, x0, u0, yop, dref, dcar, ...
                                     [Kp1 Kp2], [Ki1 Ki2], t_final);
        h  = interp1(tt, Z(:,1:4), tvec);
        y  = kc*h(:,1:2);
        r  = interp1(tt, rr, tvec);
        u  = interp1(tt, uu, tvec);
        er = r - y;
        m.IAE = trapz(tvec, abs(er(:,1))) + trapz(tvec, abs(er(:,2)));
        d1 = abs(r(end,1)-r(1,1));  d2 = abs(r(end,2)-r(1,2));
        if d1 >= d2, ch = 1; else, ch = 2; end
        m.Mp = sobreimpulso(y(:,ch), r(:,ch));
        m.ts = t_establecimiento(tvec, y(:,ch), r(:,ch));
        m.umax = max(u(:));
        m.qmax = max([k1*max(u(:,1)) k2*max(u(:,2))])*3.6;   % [L/h]
        m.hmax = max(h(:));
        m.t = tvec;  m.h = h;  m.u = u;
        if e == 1, e_sim = m; else, e_sim(e) = m; end %#ok<AGROW>
        clear m
    end

    %% 5. Guardar resultados de la geometria
    res(ig).nombre = geos{ig};
    res(ig).fuente = p.fuente;
    res(ig).x0 = x0;  res(ig).u0 = u0;  res(ig).T = T;
    res(ig).ceros = sort(real(z));  res(ig).lambda11 = lam11;
    res(ig).PI = [Kp1 Ti1; Kp2 Ti2];
    res(ig).t_final = t_final;
    res(ig).E = e_sim;
    res(ig).u_max = p.u_max;

    fila = {geos{ig}, x0(1), x0(2), x0(3), x0(4), u0(1), u0(2), ...
            T(1), T(2), T(3), T(4), max(real(z)), min(real(z)), lam11, ...
            Kp1, Ti1, Kp2, Ti2};
    for e = 1:5
        fila = [fila, {e_sim(e).IAE, e_sim(e).Mp, e_sim(e).ts}]; %#ok<AGROW>
    end
    fila = [fila, {max([e_sim.umax]), max([e_sim.umax])/p.u_max*100, ...
                   max([e_sim.qmax]), max([e_sim.hmax])}]; %#ok<AGROW>
    filas = [filas; fila]; %#ok<AGROW>

    fprintf('\n===== %s (%s) =====\n', geos{ig}, p.fuente);
    fprintf('h0 = [%.3f %.3f %.3f %.3f] cm | u0 = [%.3f %.3f] V\n', x0, u0);
    fprintf('T  = [%.2f %.2f %.2f %.2f] s\n', T);
    fprintf('Ceros = [%.5f %.5f] | lambda11 = %.3f\n', sort(real(z)), lam11);
    fprintf('PI1: Kp=%.3f Ti=%.2f s | PI2: Kp=%.3f Ti=%.2f s\n', Kp1, Ti1, Kp2, Ti2);
    for e = 1:5
        fprintf('  %s: IAE=%8.3f  Mp=%5.2f%%  ts=%7.1f s\n', nombres_esc{e}, ...
                e_sim(e).IAE, e_sim(e).Mp, e_sim(e).ts);
    end
    fprintf('u max = %.3f V (%.1f%% de %g V) | q max = %.1f L/h | h max = %.2f cm\n', ...
            max([e_sim.umax]), max([e_sim.umax])/p.u_max*100, p.u_max, ...
            max([e_sim.qmax]), max([e_sim.hmax]));
end

%% Tabla resumen
vars = {'geometria','h1','h2','h3','h4','u1','u2','T1','T2','T3','T4', ...
        'cero_lento','cero_rapido','lambda11','Kp1','Ti1','Kp2','Ti2'};
for e = 1:5
    vars = [vars, {[nombres_esc{e} '_IAE'], [nombres_esc{e} '_Mp'], [nombres_esc{e} '_ts']}]; %#ok<AGROW>
end
vars = [vars, {'u_max_V','u_max_pct','q_max_Lh','h_max_cm'}];
Tabla = cell2table(filas, 'VariableNames', vars);
writetable(Tabla, 'comparacion_geometrias.csv');
save('comparacion_geometrias.mat', 'res', 'Tabla');
fprintf('\nGuardado: comparacion_geometrias.csv y comparacion_geometrias.mat\n');

%% Figura: ensayo E3 (MIMO) en las tres geometrias, desviacion de h1 y h2
figure('Name','Comparacion de geometrias (E3)','Position',[100 100 1200 380]);
for ig = 1:ng
    subplot(1, ng, ig);
    E3 = res(ig).E(3);
    plot(E3.t, E3.h(:,1) - res(ig).x0(1), 'b-', 'LineWidth', 1.4); hold on;
    plot(E3.t, E3.h(:,2) - res(ig).x0(2), 'r--', 'LineWidth', 1.4);
    yline(1.5, 'k:');
    grid on; xlim([0 res(ig).t_final]);
    xlabel('Tiempo [s]'); ylabel('\Delta h [cm]');
    title(res(ig).fuente, 'FontWeight', 'normal');
    legend('\Delta h_1', '\Delta h_2', 'Location', 'southeast');
end
% Tema claro para el documento impreso (MATLAB R2025a+ usa tema oscuro por defecto)
fig = gcf;
try, theme(fig, 'light'); catch, end
set(fig, 'Color', 'w');
set(findall(fig, 'Type', 'axes'), 'Color', 'w', 'XColor', 'k', 'YColor', 'k', ...
    'GridColor', [0.15 0.15 0.15]);
set(findall(fig, 'Type', 'legend'), 'TextColor', 'k', 'Color', 'w', 'EdgeColor', [0.3 0.3 0.3]);
set(findall(fig, 'Type', 'text'), 'Color', 'k');
exportgraphics(gcf, 'comparacion_geometrias.png', 'Resolution', 300);
fprintf('Figura guardada: comparacion_geometrias.png\n');

%% ====================== FUNCIONES ======================

function [t, Z, r, u] = simular_pi(esc, p, x0, u0, yop, dref, dcar, Kp, Ki, t_final)
    a = p.a;
    if esc == 5, a = a*1.05; end              % E5: orificios +5%
    opts = odeset('RelTol',1e-6,'AbsTol',1e-8,'MaxStep',0.5);
    [t, Z] = ode45(@(t,z) dinamica_pi(t, z, esc, p, a, u0, yop, dref, dcar, Kp, Ki), ...
                   [0 t_final], [x0; 0; 0], opts);
    r = zeros(numel(t), 2);  u = zeros(numel(t), 2);
    for i = 1:numel(t)
        r(i,:) = referencia(esc, t(i), yop, dref)';
        u(i,:) = ley_pi(t(i), Z(i,:)', esc, p, u0, yop, dref, Kp, Ki)';
    end
end

function dz = dinamica_pi(t, z, esc, p, a, u0, yop, dref, dcar, Kp, Ki)
    A = p.A;  g = p.g;  kc = p.kc;
    g1 = p.gamma1;  g2 = p.gamma2;  k1 = p.k1;  k2 = p.k2;
    h = max(z(1:4), 0);
    u = ley_pi(t, z, esc, p, u0, yop, dref, Kp, Ki);
    s = sqrt(2*g*h);
    dh = [(-a(1)*s(1) + a(3)*s(3) + g1*k1*u(1))/A(1);
          (-a(2)*s(2) + a(4)*s(4) + g2*k2*u(2))/A(2);
          (-a(3)*s(3) + (1-g2)*k2*u(2))/A(3);
          (-a(4)*s(4) + (1-g1)*k1*u(1))/A(4)];
    if esc == 4 && t >= 100
        dh(1) = dh(1) - dcar/A(1);           % E4: fuga del 10% en T1
    end
    dz = [dh; referencia(esc, t, yop, dref) - kc*h(1:2)];
end

function u = ley_pi(t, z, esc, p, u0, yop, dref, Kp, Ki)
    err = referencia(esc, t, yop, dref) - p.kc*max(z(1:2), 0);
    u = u0 + [Kp(1)*err(1) + Ki(1)*z(5);
              Kp(2)*err(2) + Ki(2)*z(6)];
    u = min(max(u, p.u_min), p.u_max);       % saturacion de las bombas
end

function r = referencia(esc, t, yop, dref)
    s = double(t >= 20);
    switch esc
        case 1, r = yop + [dref*s; 0];
        case 2, r = yop + [0; dref*s];
        case {3, 5}, r = yop + [dref*s; dref*s];
        otherwise, r = yop;
    end
end

function [K, tau, theta] = fopdt_fit(G)
    K = dcgain(G);
    [y, t] = step(G);
    y_norm = y / K;
    t1 = interp1(y_norm, t, 0.353, 'linear');
    t2 = interp1(y_norm, t, 0.853, 'linear');
    tau = 0.67 * (t2 - t1);
    theta = 1.3*t1 - 0.29*t2;
    if theta < 0, theta = 0.01; end
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
