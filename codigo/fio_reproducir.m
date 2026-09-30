function reg = fio_reproducir(t, H, velocidad)
% FIO_REPRODUCIR  Visualiza en Factory I/O los niveles de un ensayo ya simulado.
%
%   reg = fio_reproducir(t, H)
%   reg = fio_reproducir(t, H, velocidad)
%
%   t         : tiempo de simulacion [s], vector N x 1
%   H         : niveles del modelo [cm], matriz N x 4 (columnas h1 h2 h3 h4)
%   velocidad : factor de aceleracion (por defecto el de fio_config)
%
%   Flujo de datos: MATLAB escribe los niveles simulados en los displays y
%   mueve las valvulas de la escena para que cada tanque 3D copie su nivel.
%   La lectura del Level Meter solo alimenta esa animacion. Nada de esto
%   interviene en el controlador PI, que ya se ejecuto en la simulacion.
%   El estanque de reserva (quinta columna) se calcula por balance de masa.
%
%   reg : registro con t_sim, h_ref y h_fio [cm] (5 columnas: tanques
%         1..4 y reserva) para evaluar el seguimiento.

cfg = fio_config();
if nargin < 3, velocidad = cfg.velocidad; end

% Limpiar tiempos repetidos (el integrador los genera en los escalones)
t = t(:);
[t, iu] = unique(t, 'last');
H = H(iu, :);
if size(H, 2) ~= 4
    error('H debe tener 4 columnas: h1 h2 h3 h4 en cm.');
end

% Nivel del estanque de reserva por balance de masa
p = geometria_planta('pedroso');
h_res = (cfg.res.V_total - H*p.A(:)) / cfg.res.A;
if any(h_res < 0) || any(h_res > cfg.H_cm(5))
    warning('Nivel de reserva fuera de 0-%.0f cm: revisar cfg.res.V_total.', cfg.H_cm(5));
end
H = [H h_res];
nt = cfg.n_tanques;

m = modbus('tcpip', cfg.ip, cfg.puerto);
m.Timeout = 3;
limpiar = onCleanup(@() cerrar_valvulas(m, cfg)); %#ok<NASGU>

I = zeros(1, nt);   % integradores del seguidor

%% Fase 1: prellenado hasta el nivel inicial del ensayo
fprintf('Prellenando tanques al nivel inicial...\n');
t0 = tic;
while true
    [err, I] = ciclo(m, cfg, H(1, :), I, cfg.dt);
    if max(abs(err)) < cfg.seg.tol
        break
    end
    if toc(t0) > cfg.t_prellenado_max
        warning('Prellenado incompleto: error maximo %.3f V. Se continua.', max(abs(err)));
        break
    end
    pause(cfg.dt);
end

%% Fase 2: reproduccion
fprintf('Reproduciendo %.0f s simulados a x%g (%.0f s reales)...\n', ...
        t(end), velocidad, t(end)/velocidad);
nmax  = ceil(t(end) / velocidad / cfg.dt) + 10;
reg.t_sim = nan(nmax, 1);
reg.h_ref = nan(nmax, nt);
reg.h_fio = nan(nmax, nt);
k = 0;
t0 = tic;
t_ant = 0;
while true
    t_real = toc(t0);
    ts = t_real * velocidad;
    if ts > t(end), break; end
    href = interp1(t, H, ts);
    [~, I, Vfio] = ciclo(m, cfg, href, I, max(t_real - t_ant, cfg.dt));
    t_ant = t_real;
    k = k + 1;
    reg.t_sim(k)    = ts;
    reg.h_ref(k, :) = href;
    reg.h_fio(k, :) = Vfio / 10 .* cfg.H_cm;
    pause(cfg.dt);
end
reg.t_sim = reg.t_sim(1:k);
reg.h_ref = reg.h_ref(1:k, :);
reg.h_fio = reg.h_fio(1:k, :);

e_max = max(abs(reg.h_ref - reg.h_fio), [], 1);
fprintf('Error maximo de seguimiento de la animacion [cm] (T1 T2 T3 T4 reserva): %s\n', ...
        mat2str(e_max, 3));
end

%% ------------------------------------------------------------------------
function [err, I, Vfio] = ciclo(m, cfg, href, I, dt)
% Un ciclo: leer niveles 3D, calcular valvulas, escribir valvulas + displays.
nt   = cfg.n_tanques;
Vref = href ./ cfg.H_cm * 10;
Vfio = read(m, 'inputregs', cfg.ir.nivel, nt) / cfg.escala;
err  = Vref - Vfio;

I = I + cfg.seg.Ki * err * dt;
I = min(max(I, -cfg.seg.Imax), cfg.seg.Imax);      % anti-windup
u = cfg.seg.Kp * err + I;

fill = min(max(cfg.seg.u0 + u, 0), 10);
desc = min(max(cfg.seg.u0 - u, 0), 10);
disp_mm = round(href * 10) * cfg.escala_display;  % display en mm

% Orden de registros: fill(1:4) desc(1:4) disp(1:4) fill5 desc5 disp5
regs = [round([fill(1:4) desc(1:4)] * cfg.escala), disp_mm(1:4), ...
        round([fill(5) desc(5)] * cfg.escala), disp_mm(5)];
write(m, 'holdingregs', cfg.hr.inicio, regs);
end

function cerrar_valvulas(m, cfg)
try
    write(m, 'holdingregs', cfg.hr.inicio, zeros(1, 8));      % valvulas tanques 1..4
    write(m, 'holdingregs', cfg.hr.inicio + 12, zeros(1, 2)); % valvulas reserva
catch
end
end
