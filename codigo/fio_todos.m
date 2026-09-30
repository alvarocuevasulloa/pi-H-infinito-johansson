%% fio_todos.m
% Reproduce en Factory I/O los ensayos E1 a E5 del PI, uno tras otro,
% y muestra una tabla con el error de seguimiento de la animacion.
%
% Antes de correr: Factory I/O en Play, sin nada forzado.
% No hace falta resetear la escena entre ensayos: cada uno parte con un
% prellenado al nivel inicial (todos parten del equilibrio).

% Velocidad x1 (tiempo real): la planta de Pedroso & Batista es ~11 veces
% mas rapida que la de 14 x 14 cm, asi que x1 exige al tanque de
% Factory I/O lo mismo que x10 con la planta anterior.
% 600 s simulados -> 600 s reales por ensayo (~55 min los cinco).
velocidad = 1;

ensayos = { ...
    'E1_seguimiento_T1_PI.csv'
    'E2_seguimiento_T2_PI.csv'
    'E3_MIMO_simultaneo_PI.csv'
    'E4_rechazo_perturbacion_PI.csv'
    'E5_robustez_areas_PI.csv' };

n = numel(ensayos);
emax  = zeros(n, 5);
emed  = zeros(n, 5);
regs  = cell(n, 1);

for k = 1:n
    fprintf('\n===== %s (%d de %d) =====\n', ensayos{k}, k, n);
    regs{k} = fio_ensayo_csv(ensayos{k}, velocidad);
    e = abs(regs{k}.h_ref - regs{k}.h_fio);
    emax(k, :) = max(e, [], 1);
    emed(k, :) = mean(e, 1);
end

%% Tabla resumen
nombres = {'E1'; 'E2'; 'E3'; 'E4'; 'E5'};
Tmax = array2table(round(emax, 3), 'RowNames', nombres, ...
    'VariableNames', {'h1', 'h2', 'h3', 'h4', 'reserva'});
Tmed = array2table(round(emed, 3), 'RowNames', nombres, ...
    'VariableNames', {'h1', 'h2', 'h3', 'h4', 'reserva'});
fprintf('\nError MAXIMO de seguimiento de la animacion [cm]:\n'); disp(Tmax)
fprintf('Error MEDIO de seguimiento de la animacion [cm]:\n');  disp(Tmed)

save('fio_resultados.mat', 'regs', 'ensayos', 'emax', 'emed', 'velocidad');
fprintf('Guardado en fio_resultados.mat\n');
