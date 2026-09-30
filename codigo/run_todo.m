%% run_todo.m
% Script maestro: ejecuta toda la cadena de diseño en el orden correcto.
% Cada paso depende del archivo .mat que produce el anterior.
%
% Cadena de dependencias:
%   parametros  -> (define parámetros físicos)
%   equilibrio  -> punto_operacion.mat  (equilibrio exacto por fsolve)
%   linealizacion -> modelo_lineal.mat  (A,B,C,D en el punto de operación)
%   validar_lineal -> validacion_lineal.png  (chequeo lineal vs no lineal)
%   pi_design   -> pi_controllers.mat   (controlador PI descentralizado)
%   diseno_hinf -> hinf_controller.mat  (controlador H-infinito, requiere
%                                        Robust Control Toolbox)
%
% Uso: colocar todos los .m en la misma carpeta y ejecutar  run_todo

clc; close all;
fprintf('==================================================\n');
fprintf('  CADENA DE DISEÑO — PROCESO DE CUATRO TANQUES\n');
fprintf('==================================================\n\n');

%% 0. Verificar que existen las toolboxes necesarias
fprintf('[0] Verificando toolboxes...\n');
tiene_symbolic = ~isempty(ver('symbolic'));
tiene_optim    = ~isempty(ver('optim'));
tiene_control  = ~isempty(ver('control'));
tiene_robust   = ~isempty(ver('robust'));

fprintf('    Symbolic Math Toolbox : %s\n', check(tiene_symbolic));
fprintf('    Optimization Toolbox  : %s\n', check(tiene_optim));
fprintf('    Control System Toolbox: %s\n', check(tiene_control));
fprintf('    Robust Control Toolbox: %s\n', check(tiene_robust));

if ~(tiene_symbolic && tiene_optim && tiene_control)
    error(['Faltan toolboxes necesarias para la linealización y el PI. ' ...
           'Revisa la lista de arriba.']);
end
if ~tiene_robust
    warning(['NO se detecta Robust Control Toolbox. La cadena correrá hasta ' ...
             'el PI, pero diseno_hinf.m (mixsyn) fallará. Instálala para el H-infinito.']);
end
fprintf('\n');

%% Limpiar resultados de corridas anteriores (otra geometria)
% Evita que un .mat viejo (por ejemplo, de la geometria de 14 x 14 cm)
% se use por error en esta corrida.
viejos = {'punto_operacion.mat','modelo_lineal.mat','pi_controllers.mat','hinf_controller.mat'};
for iv = 1:numel(viejos)
    if isfile(viejos{iv}), delete(viejos{iv}); end
end

%% 1. Equilibrio exacto (fsolve)
fprintf('[1] equilibrio.m — calculando punto de operación exacto...\n');
run('equilibrio.m');
assert(isfile('punto_operacion.mat'), 'No se generó punto_operacion.mat');
fprintf('    -> punto_operacion.mat OK\n\n');

%% 2. Linealización (Jacobianos en el punto de operación)
fprintf('[2] linealizacion.m — linealizando en el punto de operación...\n');
run('linealizacion.m');
assert(isfile('modelo_lineal.mat'), 'No se generó modelo_lineal.mat');
fprintf('    -> modelo_lineal.mat OK\n\n');

%% 3. Validación del modelo lineal vs no lineal
fprintf('[3] validar_lineal.m — comparando lineal vs no lineal...\n');
run('validar_lineal.m');
fprintf('    -> validacion_lineal.png OK\n\n');

%% 4. Diseño del PI descentralizado
fprintf('[4] pi_design.m — sintonizando PI descentralizado (IMC)...\n');
run('pi_design.m');
assert(isfile('pi_controllers.mat'), 'No se generó pi_controllers.mat');
fprintf('    -> pi_controllers.mat OK\n\n');

%% 5. Diseño del H-infinito (requiere Robust Control Toolbox)
% Se vuelve a chequear aquí: los scripts anteriores hacen 'clear' y borran
% las variables de este script, por lo que no se puede confiar en la
% detección hecha en el paso [0].
tiene_robust = ~isempty(ver('robust'));
if tiene_robust
    fprintf('[5] diseno_hinf.m — diseñando H-infinito (mixsyn)...\n');
    run('diseno_hinf.m');
    assert(isfile('hinf_controller.mat'), 'No se generó hinf_controller.mat');
    fprintf('    -> hinf_controller.mat OK\n\n');
else
    fprintf('[5] diseno_hinf.m — OMITIDO (falta Robust Control Toolbox)\n\n');
end

%% 6. Ensayos E1-E5 sobre el modelo no lineal (PI y H-infinito)
if isfile('hinf_controller.mat')
    fprintf('[6] comparacion_E1E5.m — ensayos E1-E5 y CSV...\n');
    run('comparacion_E1E5.m');
    fprintf('    -> CSV por ensayo + resumen_metricas_E1E5.csv OK\n\n');
else
    fprintf('[6] comparacion_E1E5.m — OMITIDO (falta hinf_controller.mat)\n\n');
end

%% 7. Anexo: comparacion de tres geometrias (solo PI, independiente)
fprintf('[7] comparacion_geometrias.m — Johansson / Meng / Pedroso...\n');
run('comparacion_geometrias.m');
fprintf('    -> comparacion_geometrias.csv / .mat / .png OK\n\n');

%% Resumen final
fprintf('==================================================\n');
fprintf('  CADENA COMPLETADA\n');
fprintf('==================================================\n');
fprintf('Archivos generados:\n');
listar('punto_operacion.mat');
listar('modelo_lineal.mat');
listar('pi_controllers.mat');
listar('hinf_controller.mat');
listar('resumen_metricas_E1E5.csv');
listar('comparacion_geometrias.csv');

%% --- funciones auxiliares ---
function s = check(ok)
    if ok, s = 'OK'; else, s = 'NO ENCONTRADA'; end
end

function listar(nombre)
    if isfile(nombre)
        fprintf('  [x] %s\n', nombre);
    else
        fprintf('  [ ] %s  (no generado)\n', nombre);
    end
end