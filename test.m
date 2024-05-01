clear all,
close all;
clc;

N = 1;          % Hamming weight of error in v(x)
q = 16;          % Alphabet size
m = log2(q);    %
d = 6;          % Minimum distance wh(c1-c2)
j0 = 1;

n = q-1;        % CW length
k = n-d+1;      % Message length
t = floor((d-1)/2); % max number of errors that can be corrected
 

% Generate random information vector
seedc = 42;
rng(seedc);
a = randi([0 q-1], 1, k); % a(x)=alpha^a(1)x^k+alpha^a(2)x^k-1+....+alpha^a(end)
% Create info poly
gf_a = gf(a,m);

% create gen poly
alpha = gf(2, m);
g = gf([1], m); %Initialise g(x)
for exp=1:2*t
    g = conv(g, gf([1 -(alpha^exp)], m)); % g(x)=(x-alpha^1)...(x-alpha^d-1)
end

a_prime = [a zeros(1,n-k)]; % shift a to the left
[quot,p] = deconv(a_prime, g);  % calculate the remainder
c = a_prime+p;  % c is the systematic codeword

% Create the error vector and add it to c

seede = 42;
rng(seede);
errorIndices = randperm(n, N); % vector of length N with random numbers between 1 and n
errorVector = zeros(1, n);
errorVector(errorIndices) = randi([1 q-1], length(errorIndices), 1);
e = gf(errorVector,m);
v = c+e;

Sj = gf(zeros(1,2*t),m);
% S_j=v(alpha^j)
for j = 1:2*t
    for exp = 1:n
% to evaluate v(alpha^j) all positions have to be summed together
% Every position is the product of the polynomials coefficient v.x(idx) and
% the position (j) to the power of n-idx
        Sj(j) = Sj(j)+gf(v.x(exp),m)*alpha^(j*(n-exp));
    end
end

% Build the S-matrix for every t,...,1
for ind = 1:-1:1
    S = gf(zeros(ind),m);
    S_vec = gf(zeros(ind,1),m);
    for l = 1:ind
        S_vec(l) = -Sj(ind+l);
        for k = 1:ind
            S(l,k) = Sj(l+k-1);
        end
    end
    try
        Lambda = S\S_vec;  % Tries to solve equation system
        % Checks if there is a valid solution
        if ~isempty(Lambda) && all(~isnan(Lambda.x))
            break;
        end
    catch ME
        % continous the loop
    end
end

% Lambda_roots = ?????????


%%
% Encode information
coded = step(enc, info);

% Introduce errors
rng(seede);
errorIndices = randperm(n, N);
errorVector = zeros(n, 1);
errorVector(errorIndices) = randi([1 q-1], length(errorIndices), 1);
noisyCoded = mod(coded + errorVector, q);

% Decode
decoded = step(dec, noisyCoded)