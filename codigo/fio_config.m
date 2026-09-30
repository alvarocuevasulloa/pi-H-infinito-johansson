function cfg = fio_config()
% FIO_CONFIG  Parametros unicos de la conexion MATLAB -> Factory I/O.
% Todos los scripts fio_*.m leen esta funcion. Si algo cambia, se cambia aqui.

%% Red (Factory I/O en el mismo PC que MATLAB)
cfg.ip     = '127.0.0.1';
cfg.puerto = 502;          % Puerto por defecto del driver Modbus TCP/IP Server

%% Escala del driver (campo "Scale" en Factory I/O)
% Los tags Float (valvulas y sensores de nivel, 0-10 V) viajan multiplicados por 100.
cfg.escala = 100;
% Displays en configuracion "Integer": NO se escalan (verificado 28-09-2026).
cfg.escala_display = 1;

%% Mapa de registros (direcciones de MATLAB = direccion Factory I/O + 1)
% Orden de planta: tanques 1..4 y luego el estanque de reserva (5).
% Holding registers (MATLAB escribe -> Factory I/O lee)
%   FIO 0-3  : Fill Valve de los tanques 1..4 de la planta
%   FIO 4-7  : Discharge Valve de los tanques 1..4
%   FIO 8-11 : Digital Display de los tanques 1..4 (nivel en mm)
%   FIO 12   : Fill Valve del estanque de reserva
%   FIO 13   : Discharge Valve del estanque de reserva
%   FIO 14   : Digital Display del estanque de reserva (nivel en mm)
cfg.hr.inicio  = 1;    % se escriben los 15 registros de una vez en cada ciclo
cfg.hr.fill    = 1;    % usados por fio_prueba_conexion.m
cfg.hr.desc    = 5;
cfg.hr.display = 9;
% Input registers (Factory I/O escribe -> MATLAB lee)
%   FIO 0-3  : Level Meter de los tanques 1..4
%   FIO 4    : Level Meter del estanque de reserva
cfg.ir.nivel   = 1;
cfg.n_tanques  = 5;
% Driver: Register Outputs = 15, Register Inputs = 5.

%% Escalamiento planta <-> escena
% 10 V del Level Meter de Factory I/O = altura util del tanque de la planta.
% Tanques de Pedroso & Batista (2022): 340 mm de alto.
% Estanque de reserva (plano bottom_tank.pdf): 366 x 186 x 88 mm exterior,
% pared de 8 mm -> interior 35,0 x 17,0 x 8,0 cm.
cfg.H_cm = [34 34 34 34 8];   % altura util de tanques 1..4 y reserva [cm]

%% Estanque de reserva (balance de masa)
% El modelo supone reserva suficiente; su nivel se calcula como el agua
% total menos la que esta en los cuatro tanques:
%   h_res = (V_total - sum(A_i*h_i)) / A_res
cfg.res.A       = 35.0*17.0;   % area interior [cm^2] = 595 cm^2
cfg.res.V_total = 4000;        % agua total del sistema [cm^3] (supuesto: 4,0 L)
% Con 4,0 L la reserva queda en ~4,4 cm de 8 cm en el equilibrio.

%% Lazo seguidor de la animacion (NO es el controlador del proceso)
% Solo hace que el tanque 3D copie el nivel calculado en MATLAB.
cfg.seg.Kp   = 4;     % [V valvula / V error]
cfg.seg.Ki   = 0.2;   % [V valvula / (V error * s)]
cfg.seg.u0   = 5;     % apertura base de ambas valvulas [V]
cfg.seg.Imax = 5;     % limite anti-windup del integrador [V]
cfg.seg.tol  = 0.03;  % error aceptado para terminar el prellenado [V]

%% Reproduccion
cfg.dt         = 0.1;  % periodo del ciclo Modbus, tiempo real [s]
cfg.velocidad  = 1;    % factor de aceleracion (x1 = tiempo real; ver fio_todos.m)
cfg.t_prellenado_max = 180;  % tiempo maximo para llegar al nivel inicial [s]
end
