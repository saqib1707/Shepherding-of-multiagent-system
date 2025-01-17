clear; clc;

% ---------------------hyperparameters------------------------
hp.number_interval = 40;
hp.time_interval = 1.0;
hp.number_evader = 2;
hp.number_pursuer = 1;
hp.vemax_repulsion = 0.2;
hp.vemax_attraction = 0;
hp.vpmax = 0.2;
hp.vpmin = 0.05;
hp.K = 1.0;
hp.epsilon = 0.05;

hp.solver = 'fmincon';
hp.algorithm = 'sqp';
hp.max_func_evals = 2e5;
hp.max_iter = 1e4;
hp.tolfun = 1e-3;
hp.tolcon = 1e-3;
hp.tolx = 1e-10;
hp.num_trial_points = 200;
hp.num_stage_one_points = 200;

% file = load('../../results_plots/final_attempt_result/hparams/-1_-1_2_2.mat');
% hp.number_interval = file.hp.number_interval;

% hp.initial_evader_position = rand(2*hp.number_evader,1)*2-1;
% hp.initial_evader_position = file.initial_evader_position;
hp.initial_evader_position = [0.5;0;-0.5;0];

hp.var = 2*hp.number_pursuer;
hp.num_opt_var = hp.var*hp.number_interval;

hp.lower_bound(1:hp.num_opt_var,1) = -3.0;
hp.upper_bound(1:hp.num_opt_var,1) = 3.0;

hp.Aineq = [];
hp.bineq = [];
hp.Aeq = [];
hp.beq = [];

% hp.initial_pursuer_position = file.initial_pursuer_position;
hp.initial_pursuer_position = [-1;-1];

% destination_list = [[1;1],[1;0.5],[1;0],[1;-0.5],[1;-1],[0.5;-1],[0;-1],[-0.5;-1],[-1;-1],[-1;-0.5],...
%     [-1;0],[-1;0.5],[-1;1],[-0.5;1],[0;1],[0.5;1]];

destination_list = [[1;1]];

% destination_list = [[2;0],[1;-2],[0;-2],[-1;-2],[-2;-2],[-2;-1],[-2;0],[-2;1],[-2;2],[-1;2],[0;2],[1;2]];

for index = 1:size(destination_list,2)
    tic;
%     hp.starting_point = file.hp.opt_x;
    hp.starting_point = rand(hp.num_opt_var,1)*4-2;
    hp.destination = destination_list(:,index);

    options = optimoptions(@fmincon, 'Algorithm', hp.algorithm, 'MaxFunEvals', hp.max_func_evals, ...
    'MaxIter', hp.max_iter, 'TolFun', hp.tolfun, 'TolCon', hp.tolcon, 'TolX', hp.tolx, 'Display', 'off', ... 
    'GradObj', 'off', 'DerivativeCheck', 'on', 'FinDiffType', 'central', 'FunValCheck', 'on', 'Diagnostics', 'off',...
    'UseParallel', true);

    % options = psoptimset('MaxFunEvals', hp.max_func_evals, 'MaxIter', hp.max_iter, 'TolFun', hp.tolfun, ...
    % 'TolCon', hp.tolcon, 'TolX', hp.tolx, 'Display', 'iter', 'PlotFcns', @psplotbestf);

    obj_func = @(x)objective_function(x, hp.number_interval, hp.var, hp.initial_pursuer_position);

    nonlinearcons = @(x)non_linear_constraints(x, hp.var, hp.number_interval, hp.number_evader, hp.time_interval, ...
        hp.initial_evader_position, hp.initial_pursuer_position, hp.vemax_repulsion, hp.vemax_attraction, ...
        hp.vpmax, hp.vpmin, hp.epsilon, hp.K, hp.destination);

    % [hp.opt_x, hp.fval, hp.exitflag, hp.output] = fmincon(obj_func, hp.starting_point, hp.A, hp.b, ...
    % hp.Aeq, hp.beq, hp.lower_bound, hp.upper_bound, nonlinearcons, options);
    % [hp.opt_x] = patternsearch(obj_func, hp.starting_point, hp.A, hp.b, hp.Aeq, hp.beq, hp.lower_bound, ...
    % hp.upper_bound, nonlinearcons, options);

    problem = createOptimProblem(hp.solver, 'objective', obj_func, 'x0', hp.starting_point, 'Aeq', hp.Aeq, 'beq', ...
        hp.beq, 'Aineq', hp.Aineq, 'bineq', hp.bineq, 'lb', hp.lower_bound, 'ub', hp.upper_bound, 'nonlcon', ...
        nonlinearcons, 'options', options);

    gs = GlobalSearch('NumTrialPoints', hp.num_trial_points, 'NumStageOnePoints', hp.num_stage_one_points, 'Display', 'iter');
    [hp.opt_x, hp.fval, hp.exitflag, hp.outputs] = run(gs, problem);

    pursuer_optimized_trajectory = horzcat(hp.initial_pursuer_position, reshape(hp.opt_x, hp.var, hp.number_interval));
    evader_optimized_trajectory = compute_evader_position(pursuer_optimized_trajectory, hp.number_evader, hp.initial_evader_position, ...
        hp.number_interval, hp.time_interval, hp.vemax_repulsion, hp.vemax_attraction, hp.K);

    % computing pursuer velocity
    pursuer_velocity = zeros(hp.number_interval-1,1);
    for t = 1:hp.number_interval-1
        pursuer_velocity(t,1) = norm(pursuer_optimized_trajectory(:,t+1) - pursuer_optimized_trajectory(:,t));
    end

    h0 = figure;
    plot(pursuer_optimized_trajectory(1,:), pursuer_optimized_trajectory(2,:), '.-', 'color', 'blue', 'LineWidth', 1);hold on;
%     for i = 1:hp.number_evader
%         plot(evader_optimized_trajectory(2*i-1,1), evader_optimized_trajectory(2*i,1), '.-', 'color', 'green');hold on;
%         plot(evader_optimized_trajectory(2*i-1,2:hp.number_interval), evader_optimized_trajectory(2*i,2:hp.number_interval), '.-', 'color', 'yellow');hold on;
%         plot(evader_optimized_trajectory(2*i-1,hp.number_interval+1), evader_optimized_trajectory(2*i,hp.number_interval+1), '.-', 'color', 'red');hold on;
%     end
    for t = 1:hp.number_interval+1 
       plot([evader_optimized_trajectory(1,t), evader_optimized_trajectory(3,t)], [evader_optimized_trajectory(2,t), evader_optimized_trajectory(4,t)], ...
           'color', 'red', 'LineWidth', 1);
    end
    draw_circle(hp.destination(1,1), hp.destination(2,1), hp.epsilon);
    grid on;
    xlabel('X');
    ylabel('Y');
    title('shepherding-optimization-result');
    hold off;

%     if or((hp.exitflag == 1), (hp.exitflag == 2))
        filename = strcat(num2str(hp.initial_pursuer_position(1,1)), '_', num2str(hp.initial_pursuer_position(2,1)), '_', ...
            num2str(hp.destination(1,1)), '_', num2str(hp.destination(2,1)));

        savefilename_fig = strcat('../../results_plots/final_attempt_result/fig_format/', filename, '.fig');
        savefilename_png = strcat('../../results_plots/final_attempt_result/png_format/', filename, '.png');
        savefig(h0, savefilename_fig);
        saveas(h0, savefilename_png);

        savefilename_hparams = strcat('../../results_plots/final_attempt_result/hparams/', filename, '.mat');
        save(savefilename_hparams, 'hp');
%     end
    close;

    elapsed_time = toc;
    disp(strcat('Elapsed Time:', num2str(elapsed_time)));
end