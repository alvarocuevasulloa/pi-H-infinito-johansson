function p = geometria_planta(nombre)
% GEOMETRIA_PLANTA  Parametros fisicos de la planta de cuatro tanques.
%
%   p = geometria_planta('pedroso')    % planta base del trabajo (por defecto)
%   p = geometria_planta('meng196')    % tanques de 14 x 14 cm (version anterior)
%   p = geometria_planta('johansson')  % paper original de Johansson (2000)
%
% Es la UNICA fuente de parametros fisicos. parametros.m y
% comparacion_geometrias.m la leen; no repetir valores en otros scripts.
%
% Modelo (igual para las tres):
%   dh1/dt = -a1/A1*sqrt(2g h1) + a3/A1*sqrt(2g h3) + g1*k1/A1*u1
%   dh2/dt = -a2/A2*sqrt(2g h2) + a4/A2*sqrt(2g h4) + g2*k2/A2*u2
%   dh3/dt = -a3/A3*sqrt(2g h3) + (1-g2)*k2/A3*u2
%   dh4/dt = -a4/A4*sqrt(2g h4) + (1-g1)*k1/A4*u1
%
% Punto de operacion:
%   modo_op = 'u' : se fija u0 y se calcula h (Johansson, Meng).
%   modo_op = 'h' : se fijan h1 y h2 y se calculan h3, h4 y u0 (Pedroso).

if nargin < 1, nombre = 'pedroso'; end

p.nombre = nombre;
p.g      = 981;       % [cm/s^2]
p.kc     = 0.50;      % ganancia de medicion [V/cm] (senal normalizada del lazo)
p.u_min  = 0;         % [V]

switch lower(nombre)
    case 'pedroso'
        % Pedroso & Batista (2022), J. Process Control 118, Tablas 2 y 3.
        % Parametros identificados sobre la planta fisica. Tanques
        % cilindricos de acrilico de 340 mm de alto (planos tank_large y
        % tank_small del repositorio decenter2021/quadruple-tank-setup).
        p.fuente = 'Pedroso y Batista (2022)';
        p.A      = [29.79 29.79 20.74 20.49];     % seccion [cm^2]
        p.a      = [0.1241 0.1350 0.03327 0.03310]; % orificio [cm^2]
        p.gamma1 = 0.7569;  p.gamma2 = 0.7563;
        p.k1     = 3.137;   p.k2     = 3.314;       % [cm^3/(V s)]
        p.u_max  = 12;      % bombas VMA421, saturacion 0-12 V
        p.H_tanque = 34;    % altura util [cm]
        p.modo_op  = 'h';
        p.h12      = [14; 14];   % h1 = h2 = 14 cm (Seccion 4.3 del paper)

    case 'meng196'
        % Version anterior del trabajo: seccion de Meng et al. (2022),
        % orificios, valvulas y bombas de Johansson (2000).
        p.fuente = 'Meng et al. (2022) + Johansson (2000)';
        p.A      = [196 196 196 196];
        p.a      = [0.071 0.057 0.071 0.057];
        p.gamma1 = 0.70;    p.gamma2 = 0.60;
        p.k1     = 3.33;    p.k2     = 3.35;
        p.u_max  = 6;
        p.H_tanque = 30;
        p.modo_op  = 'u';
        p.u0       = [3; 3];

    case 'johansson'
        % Johansson (2000), punto de operacion P- (fase minima).
        p.fuente = 'Johansson (2000)';
        p.A      = [28 32 28 32];
        p.a      = [0.071 0.057 0.071 0.057];
        p.gamma1 = 0.70;    p.gamma2 = 0.60;
        p.k1     = 3.33;    p.k2     = 3.35;
        p.u_max  = 6;
        p.H_tanque = 20;
        p.modo_op  = 'u';
        p.u0       = [3; 3];

    otherwise
        error('Geometria desconocida: %s. Usar pedroso, meng196 o johansson.', nombre);
end

%% Equilibrio analitico (semilla para fsolve en equilibrio.m)
% El modelo tiene solucion cerrada en ambos modos.
g = p.g;  a = p.a;  g1 = p.gamma1;  g2 = p.gamma2;  k1 = p.k1;  k2 = p.k2;
switch p.modo_op
    case 'u'
        u = p.u0;
        h3 = ((1-g2)*k2*u(2)/a(3))^2 / (2*g);
        h4 = ((1-g1)*k1*u(1)/a(4))^2 / (2*g);
        h1 = ((a(3)*sqrt(2*g*h3) + g1*k1*u(1))/a(1))^2 / (2*g);
        h2 = ((a(4)*sqrt(2*g*h4) + g2*k2*u(2))/a(2))^2 / (2*g);
    case 'h'
        h1 = p.h12(1);  h2 = p.h12(2);
        q  = [a(1)*sqrt(2*g*h1); a(2)*sqrt(2*g*h2)];   % caudales de salida
        M  = [g1*k1, (1-g2)*k2;  (1-g1)*k1, g2*k2];
        u  = M \ q;
        h3 = ((1-g2)*k2*u(2)/a(3))^2 / (2*g);
        h4 = ((1-g1)*k1*u(1)/a(4))^2 / (2*g);
end
p.x0_semilla = [h1; h2; h3; h4];
p.u0_semilla = u(:);
end
