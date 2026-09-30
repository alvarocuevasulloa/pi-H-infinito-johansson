function reg = fio_ensayo_csv(archivo, velocidad)
% FIO_ENSAYO_CSV  Lee un ensayo exportado por comparacion_E1E5.m y lo
% muestra en Factory I/O.
%
%   reg = fio_ensayo_csv('E1_seguimiento_T1_PI.csv')
%   reg = fio_ensayo_csv('E1_seguimiento_T1_PI.csv', 10)
%
%   El CSV trae t, r1, r2, y1, y2, u1, u2 y los cuatro niveles h1..h4 [cm],
%   calculados por el modelo no lineal. Se usan directamente: no hay
%   reconstruccion, por lo que sirve para todos los ensayos, E5 incluido.

if nargin < 2, velocidad = []; end

T = readtable(archivo);
t = T.t(:);

if ~all(ismember({'h1','h2','h3','h4'}, T.Properties.VariableNames))
    error(['El CSV no trae h1..h4. Vuelve a correr comparacion_E1E5.m ' ...
           'con la version nueva para regenerar los CSV.']);
end
H = [T.h1(:) T.h2(:) T.h3(:) T.h4(:)];

fprintf('Rango de niveles [cm]:\n');
fprintf('  h1 %.2f a %.2f | h2 %.2f a %.2f | h3 %.2f a %.2f | h4 %.2f a %.2f\n', ...
        [min(H); max(H)]);

if isempty(velocidad)
    reg = fio_reproducir(t, H);
else
    reg = fio_reproducir(t, H, velocidad);
end
end
