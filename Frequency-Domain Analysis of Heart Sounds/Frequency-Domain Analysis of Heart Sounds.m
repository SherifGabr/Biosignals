% Load the data from the file 'data6.mat'
% << INSERT YOUR CODE HERE >>
load('data6.mat')
% The ECG sampling rate is 1000 Hz
FS = 1000;

% QRS detector operates on 200 Hz signals
FS_QRS = 200;

% The number of subjects
N = numel(data);

% Windowing length
window = 50;

% Number of overlapped samples 
nbroverlap = 45;

% Specify nfft parameter as empty. 
nfft = [];

% Minimum spectrogram threshold
th = -30; 

% Using the pre-extracted cardiac cycles (struct 'cycles'), compute the spectrogram for each subject
% Store the results in a similar 1xN struct array called 'SPCs' with the fields s, f, t, and p corresponding to the outputs of the function 'spectrogram'
% E.g. SPCs(3).p is the power spectral density spectrogram (a matrix) of the subject 3.
SPCs = struct('s',{},'f',{},'t',{}, 'p',{})

for i = 1:N
    [SPCs(i).s, SPCs(i).f, SPCs(i).t, SPCs(i).p] = spectrogram(cycles(i).PCG, hamming(window), nbroverlap, nfft, 'yaxis' , FS, 'MinThreshold', th)
end

% Using the full data (struct 'data'), find the QRS complexes using the function 'QRSDetection'
% Store only the QRS onset indice vectors of each subject in the elements of the 1xN cell array 'onsets'
% Note: QRS detection works at a lower data rate of 200 Hz instead of 1000 Hz, so you must resample the data first
%       Also you must map the detected onsets back to the original sampling rate by multiplying with the correct factor

resampled_data = struct('t',{},'ECG',{},'PCG',{}, 'subject', {})

for i = 1:N
    resampled_data(i).t = resample(data(i).t, FS_QRS, FS)
    resampled_data(i).ECG = resample(data(i).ECG, FS_QRS, FS)
    resampled_data(i).PCG = resample(data(i).PCG, FS_QRS, FS)
    resampled_data(i).subject = data(i).subject
end

onsets = cellfun(@(x) QRSDetection(x), {resampled_data.ECG}, 'UniformOutput', false)
onsets = cellfun(@(x) x*(FS/FS_QRS), onsets,'un',0)

% The systolic part of the PCG signal is expected to span this many samples starting from the QRS onset in each beat
segment_length = 300;

% Using the previously computed onsets, for each subject 
% pick all their PCG segments corresponding to the systolic parts in a 1xN cell array 'systoles'
% So, each cell corresponds to a subject, and contains a m-by-segment_length sized matrix of their m PCG segments

systoles = cell(1, 5)

for i = 1:N %Loop from 1 to 5, the same number of subjects
    
    onset_idx = onsets{i} %Setting onset_idx equal to the current onset cell
    segments = zeros(length(onset_idx), segment_length) %Segments init
    for j = 1: length(onset_idx)  
       segments(j, [1:segment_length]) = data(i).PCG(onset_idx(j) : onset_idx(j) + 299)
    end
    systoles{i} = segments
end
    
% For each subject, compute the power spectral density (PSD) of all the PCG segments separately
% Use the 'pwelch' function with the default arguments but specifying the sampling rate
% Store the results in a 1xN struct array 'PSDs' with the fields Pxx and F corresponding to the outputs of the pwelch function
% In addition, add the field Pxx_mean which is the average of all the PSD of that subject averaged across the beats
% Thus, PSDs(i).Pxx is a mxk matrix, PSDs(i).F is a kx1 vector, and PSDs(i).Pxx_mean is a 1xk vector


PSDs = struct('Pxx',[],'F',[],'Pxx_mean',[])
systoles_mod = cellfun(@transpose,systoles,'UniformOutput',false)

for i = 1:N 
    for j = 1:length(systoles(i))
        [PSDs(i).Pxx, PSDs(i).F] = pwelch(systoles_mod(i),[],[],[], FS)
    end
end

for i = 1:N 
    PSDs(i).Pxx = transpose(PSDs(i).Pxx)
    PSDs(i).Pxx_mean = mean(PSDs(i).Pxx)
end


