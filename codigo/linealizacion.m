%% linealizacion.m
% Linealización simbólica del modelo no lineal de Johansson en P-
% Genera el sistema en espacio de estados (A,B,C,D) en variables incrementales
% Requisito: haber corrido antes parametros.m

% Cargar parámetros si no están en el workspace
if ~exist('A1','var'); parametros; end

%% 1. Definir variables simbólicas
syms h1 h2 h3 h4 u1 u2 real

% Estados y entradas
x_sym = [h1; h2; h3; h4];
u_sym = [u1; u2];

%% 2. Ecuaciones no lineales (Johansson, 2000)
% dh1/dt = -a1/A1*sqrt(2*g*h1) + a3/A1*sqrt(2*g*h3) + gamma1*k1/A1 * u1
% dh2/dt = -a2/A2*sqrt(2*g*h2) + a4/A2*sqrt(2*g*h4) + gamma2*k2/A2 * u2
% dh3/dt = -a3/A3*sqrt(2*g*h3) + (1-gamma2)*k2/A3 * u2
% dh4/dt = -a4/A4*sqrt(2*g*h4) + (1-gamma1)*k1/A4 * u1

f1 = -a1/A1*sqrt(2*g*h1) + a3/A1*sqrt(2*g*h3) + gamma1*k1/A1 * u1;
f2 = -a2/A2*sqrt(2*g*h2) + a4/A2*sqrt(2*g*h4) + gamma2*k2/A2 * u2;
f3 = -a3/A3*sqrt(2*g*h3) + (1-gamma2)*k2/A3 * u2;
f4 = -a4/A4*sqrt(2*g*h4) + (1-gamma1)*k1/A4 * u1;

f_sym = [f1; f2; f3; f4];

%% 3. Jacobianos (derivadas parciales)
A_sym = jacobian(f_sym, x_sym);   % df/dx -> matriz A
B_sym = jacobian(f_sym, u_sym);   % df/du -> matriz B

%% 4. Evaluar en el punto de operación P-
A = double(subs(A_sym, [x_sym; u_sym], [x0; u0]));
B = double(subs(B_sym, [x_sym; u_sym], [x0; u0]));

% Salidas: y1 = kc*h1, y2 = kc*h2  (solo medimos los tanques inferiores)
C = [kc 0  0 0;
    0  kc 0 0];
D = zeros(2,2);

%% 5. Crear sistema en espacio de estados continuo
sys_c = ss(A, B, C, D);
sys_c.StateName  = {'h1','h2','h3','h4'};
sys_c.InputName  = {'u1','u2'};
sys_c.OutputName = {'y1','y2'};

%% 6. Verificaciones críticas
disp('========== MATRIZ A ==========');  disp(A);
disp('========== MATRIZ B ==========');  disp(B);

% Polos: deberían ser aprox -1/T_i para la geometría vigente (los T_i los
% calcula parametros.m con las áreas de sección actuales). Se comparan
% contra -1/T_i abajo.
polos = eig(A);
fprintf('\nPolos del sistema:\n');
disp(polos);
fprintf('Polos esperados (-1/T_i): %.4f  %.4f  %.4f  %.4f\n', ...
    -1/T1, -1/T2, -1/T3, -1/T4);

% Ceros de transmisión: en P- ambos deben estar en el semiplano IZQUIERDO
ceros = tzero(sys_c);
fprintf('\nCeros de transmisión:\n');
disp(ceros);
if all(real(ceros) < 0)
    fprintf('✓ Todos los ceros en semiplano izquierdo → FASE MÍNIMA confirmada.\n');
else
    fprintf('✗ ATENCIÓN: hay ceros en semiplano derecho.\n');
end

% Controlabilidad y observabilidad
fprintf('\nRango de matriz de controlabilidad: %d (esperado: 4)\n', rank(ctrb(A,B)));
fprintf('Rango de matriz de observabilidad:  %d (esperado: 4)\n', rank(obsv(A,C)));

%% 7. Guardar el sistema para usarlo después
save('modelo_lineal.mat', 'sys_c', 'A', 'B', 'C', 'D', 'x0', 'u0');
fprintf('\nSistema guardado en modelo_lineal.mat\n');