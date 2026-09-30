%% equilibrio.m
% Calcula el equilibrio exacto del modelo no lineal.
%   Planta base (Pedroso & Batista, 2022): se fijan h1 = h2 = 14 cm y se
%   resuelven h3, h4, u1 y u2.
%   Geometrias con modo 'u' (Johansson, Meng): se fija u0 y se resuelve h.

clear; clc;
parametros;  % carga parametros y semilla analitica

f = @(h,u) [
    -a1/A1*sqrt(2*g*h(1)) + a3/A1*sqrt(2*g*h(3)) + gamma1*k1/A1 * u(1);
    -a2/A2*sqrt(2*g*h(2)) + a4/A2*sqrt(2*g*h(4)) + gamma2*k2/A2 * u(2);
    -a3/A3*sqrt(2*g*h(3))                         + (1-gamma2)*k2/A3 * u(2);
    -a4/A4*sqrt(2*g*h(4))                         + (1-gamma1)*k1/A4 * u(1)
    ];

options = optimoptions('fsolve','Display','iter-detailed','TolFun',1e-12,'TolX',1e-12);

switch p.modo_op
    case 'h'
        % Incognitas z = [h3; h4; u1; u2], con h1 y h2 fijos
        h12 = p.h12;
        fun = @(z) f([h12; z(1:2)], z(3:4));
        z0  = [x0_nominal(3:4); u0_nominal];
        [z, fval, exitflag] = fsolve(fun, z0, options);
        x0_exacto = [h12; z(1:2)];
        u0 = z(3:4);
    case 'u'
        fun = @(x) f(x, u0_nominal);
        [x0_exacto, fval, exitflag] = fsolve(fun, x0_nominal, options);
        u0 = u0_nominal;
end

fprintf('\n========== EQUILIBRIO EXACTO ==========\n');
fprintf('Semilla analitica  : h = [%.4f  %.4f  %.4f  %.4f]\n', x0_nominal);
fprintf('Equilibrio (fsolve): h = [%.4f  %.4f  %.4f  %.4f] cm\n', x0_exacto);
fprintf('Entradas           : u0 = [%.4f  %.4f] V (limite %g V)\n', u0, u_max);
fprintf('Caudal de bombas   : q = [%.1f  %.1f] L/h\n', [k1 k2]'.*u0*3.6);
fprintf('Residual final     : max|f(x*)| = %.2e (debe ser ~0)\n', max(abs(fval)));
fprintf('Exitflag           : %d  (1 = convergencia OK)\n', exitflag);

x0 = x0_exacto;
save('punto_operacion.mat','x0','u0','kc','geometria','-v7.3');
fprintf('\nEquilibrio guardado en punto_operacion.mat\n');
