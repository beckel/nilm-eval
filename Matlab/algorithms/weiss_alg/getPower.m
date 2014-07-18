% This file is part of the project NILM-Eval (https://github.com/beckel/nilm-eval).
% Licence: GPL 2.0 (http://www.gnu.org/licenses/gpl-2.0.html)
% Copyright: ETH Zurich, 2014
% Author: Romano Cicchetti

function [power] = getPower(dataset, house, days, interval, phase)

    % get real, apparent and reactive (distoritve and translative
    % component) power
        
    power = struct;
    % get current, voltage, real power and phase angle of phase
    current_str = strcat('currentl', num2str(phase));
    voltage_str = strcat('voltagel', num2str(phase));
    power_str = strcat('powerl', num2str(phase));
    phase_angle_str = strcat('phaseanglecurrentvoltagel', num2str(phase));
    current = read_smartmeter_data(dataset, num2str(house, '%02d'), days, interval, current_str);
    voltage = read_smartmeter_data(dataset, num2str(house, '%02d'), days, interval, voltage_str);
    power.real = read_smartmeter_data(dataset, num2str(house, '%02d'), days, interval, power_str);
    phase_angle = read_smartmeter_data(dataset, num2str(house, '%02d'), days, interval, phase_angle_str);

    % calculate apparent and reactive power of phase
    power.apparent = current .* voltage;
    power.normalized_apparent = power.apparent .* ((230./(voltage)).^2);
    invalid_idx = power.real.^2 > power.apparent.^2;
    power.reactive = zeros(size(power.real));
    power.reactive(invalid_idx) = 0;
    power.reactive(~invalid_idx) = sqrt((power.apparent(~invalid_idx).^2)-(power.real(~invalid_idx).^2));

    % calculate distortive and translative component of reactive power
    power.reactive_translative = power.real .* tand(phase_angle);
    invalid_idx = power.reactive_translative.^2 > power.reactive.^2;
    power.reactive_distortive = zeros(size(power.reactive));
    power.reactive_distortive(invalid_idx) = 0;
    power.reactive_distortive(~invalid_idx) = sqrt((power.reactive(~invalid_idx).^2)-(power.reactive_translative(~invalid_idx).^2));
end

