%% fio_prueba_conexion.m
% Prueba paso a paso de la comunicacion MATLAB -> Factory I/O.
% Ejecutar SECCION POR SECCION (Ctrl+Enter), con la escena en modo Run (Play)
% y el driver Modbus TCP/IP Server conectado (icono verde).

cfg = fio_config();

%% 1. Verificar que existe la funcion modbus
if isempty(which('modbus'))
    error(['No se encontro la funcion modbus. Se requiere Industrial ' ...
           'Communication Toolbox (o Instrument Control Toolbox en versiones antiguas).']);
end
fprintf('OK: funcion modbus disponible.\n');

%% 2. Conectar con Factory I/O
m = modbus('tcpip', cfg.ip, cfg.puerto);
m.Timeout = 3;
fprintf('OK: conectado a %s:%d\n', cfg.ip, cfg.puerto);

%% 3. Displays: deben mostrar 101 102 103 104
write(m, 'holdingregs', cfg.hr.display, [101 102 103 104] * cfg.escala_display);
disp('Revisar en Factory I/O: Display 1..4 = 101 102 103 104.');
disp('Si muestran 1 1 1 1, poner cfg.escala_display = 100 en fio_config.m');

%% 4. Valvula de llenado del Tanque 1 al 50 % durante 5 s
write(m, 'holdingregs', cfg.hr.fill, [5 0 0 0] * cfg.escala);
disp('Tanque 1 llenandose (5 s)...');
pause(5);
write(m, 'holdingregs', cfg.hr.fill, [0 0 0 0]);
disp('Revisar: solo el Tanque 1 debe haber subido. Si subio otro, el orden de tags esta cruzado.');

%% 5. Leer los cuatro sensores de nivel
V = read(m, 'inputregs', cfg.ir.nivel, 4) / cfg.escala;
fprintf('Level Meter Factory I/O [V]: %s\n', mat2str(V, 3));
fprintf('Equivalente planta [cm]:     %s\n', mat2str(V/10.*cfg.H_cm(1:4), 3));

%% 6. Vaciar el Tanque 1 y cerrar todo
write(m, 'holdingregs', cfg.hr.desc, [10 0 0 0] * cfg.escala);
pause(5);
write(m, 'holdingregs', cfg.hr.fill, zeros(1, 8));   % cierra 8 valvulas
clear m
disp('Prueba terminada.');
