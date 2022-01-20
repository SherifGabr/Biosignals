FS = 2000;

% Load the signals from data.mat into the struct 'data'
% << insert loading code here >>
load('data.mat', 'data');

% Number of segments
N = numel(data);  

% Calculate average force of each segment (1xN vector)
AF = cellfun(@mean, {data.force}); 

% Calculate EMG dynamic range in each segment (1xN vector)
DR = cellfun(@max, {data.EMG}) - cellfun(@min, {data.EMG}) ;

% Calculate EMG mean squared value in each segment (1xN vector)
MS =  cellfun(@(x)sum(x.^2)/length(x) , {data.EMG})

% Calculate EMG zero crossing rate in each segment (1xN vector)
ZCR = cellfun(@(x) sum(abs(diff(sign(x)))*0.5)/(length(x)/FS), {data.EMG})

% Calculate EMG turns rate in each segment (1xN vector)

TCR =zeros(1,N);

for i=1:N
    EMG=data(i).EMG;
    turn=zeros(length(EMG),1);
    %turning points ind
    TP=zeros(size(EMG));
    TP(2:end-1)=diff(sign(diff(EMG)));
    ind=find(TP);
    TC=zeros(length(ind),1);
    
    for j=2:(length(ind))
        TC(j)=TP(ind(j));
        if (TC(j)*TC(j-1)<=0)&& (abs(EMG(ind(j))-EMG(ind(j-1)))>=0.1)
            turn(j-1)=1;
        end
    end
    time_seg_i=data(i).t;
    time_duration_i=time_seg_i(end)-time_seg_i(1);
    TCR(i)=(sum(turn))/time_duration_i;

end

% Calculate the linear model coefficients for each parameter
% The models are in the form: parameter(force) = constant + slope * force,
% and the coefficients are stored in a 1x2 vectors: p_<param> = [slope constant]
% For example, p_DR(1) is the slope and p_DR(2) is the constant of the linear model mapping the average force into the dynamic range
% You can use the 'polyfit' (or the 'regress') command(s) to find the model coefficients

p_DR = polyfit(AF, DR, 1)
p_MS = polyfit(AF, MS, 1)
p_ZCR = polyfit(AF, ZCR, 1)
p_TCR = polyfit(AF, TCR, 1)

% Calculate correlation coefficients between the average forces and each of the parameters using 'corr'
c_DR = corr(transpose(AF), transpose(DR))
c_MS = corr(transpose(AF), transpose(MS))
c_ZCR = corr(transpose(AF), transpose(ZCR))
c_TCR = corr(transpose(AF), transpose(TCR))