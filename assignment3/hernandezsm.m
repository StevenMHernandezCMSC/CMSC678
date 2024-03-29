% function [] = hernandez_Project3 % TODO add this back
close all, clear all, format compact
seed0=1;	randn('seed',seed0), rand('seed',seed0)

% load your data
load('cancer.mat');
[l, dim] = size(X);
% Y = Y - 1;
Y = (Y == 2) * 2 - 1;

% plot data inputs
figure(1)
plot(sort(X))
title("Plotted Cancer Inputs (Sorted, Unscaled)")

% plot outputs as circle to 
figure(2)
plot(sort(Y), 'o')
title("Plot of Cancer Result Outputs (Sorted)")

% scale the input
X = (X - mean(X)) ./ std(X);

figure(3)
plot(sort(X))
title("Plotted Cancer Inputs (Sorted, Scaled)")

% Add bias
X = [X ones(l,1)];
[l, dim] = size(X);

% create train and test set
random_ind = randsample(l,l);
split = round(l*0.75);
train_ind = random_ind(1:split);
test_ind = random_ind((split+1):l);
X_train = X(train_ind, :);
Y_train = Y(train_ind, :);
X_test = X(test_ind, :);
Y_test = Y(test_ind, :);

% find numb of train data and call in ntrain, same for ntest
ntrain = length(Y_train);
ntest = length(Y_test);

N0 = [5 10 15 25 50 75 100]
I0 = [100 250 500 1000 1500] % or if 1000 is not enough go for more

eta = 0.001

for n = 1:length(N0)
    num_n = N0(n)

    % define random initial HL weighs V, and random OL weights W
    V = rand(num_n, dim); % V_p(J-1,I)
    W = rand(1, num_n + 1); % W_p(K,J) % Notice, we want num_n neurons, thus num_n+1 gives us a bias term

    for i = 1:length(I0)  % i is an index of an epoch or a sweep through all data
        for epoch = 1:I0(i)
            err = 0;
            for j = 1:ntrain
                % input is X(j,:)
                input = X_train(j,:)';
                d = Y_train(j);

                % here comes your learning code which basically implements the algorithm as given in the table and example
                % you take your first data point and
                % here you calculate inputs to HL neurons, their outputs and derivatives of AF at each neuron
                U_hl = V * input;
                Y_hl = tanh(U_hl);

                % input(s) to OL neuron and its output
%                 O_ol = W * [Y_hl' 1]';
                O_ol = sign(W * [Y_hl' 1]');

                % error_at OL neuron for a given input data
%                 err = 0.5 * sum((d - O_ol).^2 + err);
%                 err = (0.5 * (d - O_ol)^2) + err;

                % EBP part comes below now
                % delta signal for OL neuron
                delta_o = (d - O_ol);

                % delta signals for HL neurons
                delta_y = (1-tanh(U_hl).^2) * sum(delta_o .* W(:,1:num_n));

                % update OL and HL weights
                W = W + (eta * delta_o .* d);
                V = V + (eta * delta_y * input');
            end
        end
        % Training is over
        % here comes calculation of the error on the test data
        % give them, find outputs see errors and save in error matrix E
        Y_hl = tanh(V * X_test');
        O_ol = W * [Y_hl' ones(size(Y_test))]';
        E(n,i) = length(find(Y_test - sign(O_ol'))) / length(Y_test)

%         %
%         % Show the error of predictions on the TRAINING set
%         % to better understand why learning ends
%         %
%         Y_hl = tanh(V * X_train');
%         O_ol = W * [Y_hl' ones(size(Y_train))]';
%         E_train(n,i) = length(find(Y_train - sign(O_ol'))) / length(Y_train)

        
        if n == 2 && i == 4 % Best when parameters when using `sign()`
            % Figure out the error PER CLASS for the best performing
            % attributes (hardcoded here in this if statement) across ALL
            % elements in the cancer dataset (training and testing).
            Y_hl = tanh(V * X');
            O_ol = W * [Y_hl' ones(size(Y))]';

            indPos = find(Y == 1);
            indNeg = find(Y == -1);
            errPos = length(find(Y(indPos) - sign(O_ol(indPos)'))) / length(indPos);
            errNeg = length(find(Y(indNeg) - sign(O_ol(indNeg)'))) / length(indNeg);
        end
    end
end

% Show err calculated for best case for EACH CLASS
errPos
errNeg

% find best numb of neurons and best numb of iterations.
% plotting etc
figure(4)
hold on
set(gca, 'XTick', 1:length(N0))
set(gca, 'YTick', 1:I0)
mesh(E)
title("Percent Error for Multilayer Perceptron for given Parameters (# of Epochs and # of Neurons)")
zlabel("Percent Error (%)")
ylabel("Number of Neurons in Hidden Layer")
xlabel("Number of Epochs")
yticklabels(N0)
xticklabels(I0)
view([-50 20]);
grid on
hold off


