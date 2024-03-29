% Steven Hernandez
% CMSC 678

clear all, close all, format compact

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% PART 1:
%     Basic Perceptron Learning
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%% 
% General Setup
%%%%%%%%%%%%%%%

% set seed
rng(1,'v4normal')

%%%%%%%%%%%%%%%%%%%%%
% Create Base Dataset
%%%%%%%%%%%%%%%%%%%%%

X = cat(1, normrnd(0,2,20,2), normrnd(5,2,10,2));
Y = cat(1, ones(20,1), -ones(10,1));

% Add bias
X = [X ones(size(Y))];

%%%%%%%%%%%%%%%%%%%%%%%%
% Add a negative outlier
%%%%%%%%%%%%%%%%%%%%%%%%

X_with_outlier = cat(1, [20, 20, 1.0], X);
Y_with_outlier = cat(1, -1.0, Y);

[l, dim]  = size(X);
[l_with_outlier, ~]  = size(X_with_outlier);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Train by default perceptron algorithm with eta=0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[epochs, W] = perceptron(X, Y, 0.1, [0 0 0]');

figure(1)
hold on
title("Perceptron Decision Boundaries")
graph(X_with_outlier, Y_with_outlier);
line1 = graph_line(W, '-');
hold off

"===="
"1.a and 1.b: What is the # of epochs and final weight when eta=0.1?"
epochs
W

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Train by perceptron algorithm for different learning rates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

learning_rates = [1e-4, 1e-3, 1e-2, 1e-1, 1e0, 1e1, 1e2, 1e3, 1e4];
learning_rate_epochs = [];
learning_rate_epochs_with_outlier = [];

for eta = learning_rates
    eta;
    
    %%%%%%%%%%%%%%%%%
    % without outlier
    %%%%%%%%%%%%%%%%%

    [epochs, ~] = perceptron(X, Y, eta, [1 1 1]');
    
    learning_rate_epochs = cat(1, learning_rate_epochs, epochs);

    %%%%%%%%%%%%%%
    % with outlier
    %%%%%%%%%%%%%%

    [epochs, ~] = perceptron(X_with_outlier, Y_with_outlier, eta, [1 1 1]');
    
    learning_rate_epochs_with_outlier = cat(1, learning_rate_epochs_with_outlier, epochs);
end

"===="
"2: What are the weights of perceptron learning with and without outlier (eta=1.0, W=[0 0 0]')?"
[~, W] = perceptron(X, Y, 1.0, [0 0 0]')
[~, W_with_outlier] = perceptron(X_with_outlier, Y_with_outlier, 1.0, [0 0 0]')

%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Graph Results of Training
%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1)
hold on
line2 = graph_line(W, 'b.');
line3 = graph_line(W_with_outlier, '-');
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Graph effect of Learning Rate on Epoch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(2)
hold on
title("Effect of Learning Rate on Epoch")
xlabel("Learning Rate")
set(gca, 'XScale', 'log')
ylabel("# of Epochs Taken")
scatter1 = scatter(learning_rates, learning_rate_epochs);
scatter2 = scatter(learning_rates, learning_rate_epochs_with_outlier, '.');
legend([scatter1 scatter2], "epochs taken without outlier", "epochs taken with outlier")
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
% PART 2
%     Learning with Pseudo-inverse
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

penalty = 1.0;

W = learn_psuedoinverse(X, Y, penalty, dim);

W_with_outliers = learn_psuedoinverse(X_with_outlier, Y_with_outlier, penalty, dim);

%%%%%%%%%%%%%%%
% Graph Figures
%%%%%%%%%%%%%%%

figure(1)
hold on
line4 = graph_line(W, 'y:');
line5 = graph_line(W_with_outliers, '-');
hold off

%%%%%%%%%%%%%%%%%%%%%%
%
%
% PART 3
%     Cross-validation
%
%
%%%%%%%%%%%%%%%%%%%%%%

penalties = [1e-6, 1e-5, 1e-4, 1e-3, 1e-2, 1e-1, 1e0, 1e1, 1e2, 1e3, 1e4];
errors = [];

for penalty = penalties
    numErr = 0;
    indices = crossvalind('Kfold',Y_with_outlier,10);
    for i = 1:10
        % Using the built in crossvalidation
        test = (indices == i);
        train = ~test;

        X_train = X_with_outlier(train, :);
        Y_train = Y_with_outlier(train, :);

        X_test = X_with_outlier(test, :);
        Y_test = Y_with_outlier(test, :);

        W = learn_psuedoinverse(X_train, Y_train, penalty, dim);
        
        numErr = numErr + length(find(Y_test - sign(X_test*W)));
    end
    
    errors = cat(1, errors, 100 * numErr / length(Y));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Graph effect of penalty on error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(3)
hold on
title("Effect of penalty on error percentage")
xlabel("Penalty")
set(gca, 'XScale', 'log')
ylabel("Error (%)")
plt = plot(penalties, errors);
hold off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The best penalty appears to be 1e1
% What is the final weight with lambda
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

"3. Weight with penalty(lambda_best)=1e2:"
W = learn_psuedoinverse(X, Y, 1e2, dim)
W_with_outlier = learn_psuedoinverse(X_with_outlier, Y_with_outlier, 1e2, dim)

figure(1)
hold on;
line6 = graph_line(W_with_outliers, '.');
legend([line1 line2 line3 line4 line5 line6], [ 
    "(perceptron) weights without outlier (eta = 0.1)" 
    "(perceptron) weights without outlier (eta = 1.0)"
    "(perceptron) weight learned with outlier (eta = 1.0)"
    "(psuedo-inverse) weights without outlier (lambda = 1.0)" 
    "(psuedo-inverse) weight learned with outlier (lambda = 1.0)"
    "(psuedo-inverse) Best separation Line (lambda=1e2)"
])
set(findobj(gca, 'Type', 'Line', 'Linestyle', 'y:'), 'LineWidth', 2)
hold off;

%%%%%%%%%%%%%%%%%%%%%%
%
%
% Learning Subroutines
%
%
%%%%%%%%%%%%%%%%%%%%%%

function [epoch, W] = perceptron(X, Y, eta, W)
    numErr = Inf;
    epoch = 1;

    % ensure training doesn't go on forever (more than 1000 epochs)
    while ((numErr > 0) && (epoch < 1000))
        epoch = epoch + 1;

        for i = 1:size(Y)
            W = W + (eta * (Y(i,:) - sign(X(i,:)*W)) * X(i,:)');
        end
        
        numErr = length(find(Y - sign(X*W)));
    end
end

function W = learn_psuedoinverse(X, Y, penalty, dim)
    % w = (X'X + ?I)^-1 * X'Y
    W = inv((X'*X) + (penalty * eye(size(dim)))) * X' * Y;
end

%%%%%%%%%%%%%%%%%%%%
% 
% 
% Plotting functions
% 
% 
%%%%%%%%%%%%%%%%%%%%

function plt = graph(X,Y)
    axis([-5 21 -5 21])
    xlabel('x');
    ylabel('y');
    plt = gscatter(X(:,1), X(:,2), Y, 'rb', 'o+');
end

function plt = graph_line(W, line_type)
    x_intercept = -(W(3)/W(1));
    y_intercept = -(W(3)/W(2));
    slope = -(W(3)/W(2))/(W(3)/W(1));

    x_matrix = -10:20;
    y_matrix = y_intercept + (slope * x_matrix);

    plt = plot(x_matrix, y_matrix, line_type);
end