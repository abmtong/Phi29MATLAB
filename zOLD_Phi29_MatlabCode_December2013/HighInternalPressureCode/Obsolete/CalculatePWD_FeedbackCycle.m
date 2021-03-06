function PWD = CalculatePWD_FeedbackCycle()
% This function calculates the pairwise distance distribution for each
% feedback cycle independently. You have to specify the Data Acquisition
% Bandwidth, the Filtering Frequency, and the width of the histogram bin
% (for plotting results at the end). The function saves the results of the
% calculation in the PWDData folder in the AnalysisFolder.
%
% USE: PWD = CalculatePWD_FeedbackCycle()
%
% Gheorghe Chistol 13 Sept 2010


%% Ask for parameters
Prompt = {'Data Acquisition Bandwidth (Hz)',...
          'Filtered Frequency (Hz)', ...
          'Histogram Bin Width (bp)'};
Title = 'Enter the Following Parameters';
Lines = 1;
Default = {'2500','50','0.5'};
Options.Resize='on'; Options.WindowStyle='normal'; Options.Interpreter='tex';
Answer = inputdlg(Prompt, Title, Lines, Default, Options);
Bandwidth     = str2num(Answer{1});
F             = str2num(Answer{2}); %this is the desired filter frequency
HistBinWidth  = str2num(Answer{3});
%%

Filter=round(Bandwidth/F); %filtering factor

global analysisPath; %set the analysis path if neccessary
if isempty(analysisPath)
    disp('analysisPath was not previously defined. Please define it and try again.');
    return;
end

%% Select the phage files of interest
File = uigetfile([ [analysisPath '\'] '*.mat'], 'MultiSelect', 'on');
if isempty(File) %if no files were selected
    disp('No *.mat phage files were selected');
    return;
end

if ~iscell(File) %if there is only one file, make it into a cell, for easier processing later
    temp=File; clear File; File{1}=temp;
end
    
for f=1:length(File)
    CropFile = [analysisPath '\CropFiles\' File{f}(6:end-4) '.crop']; % this is the complete address of the crop file that should 
                                                                      % correspond to the current phage *.mat file
    if exist(CropFile,'file') %check if the crop file exists, if it doesn't, don't process the phage file at all
        disp('--------------------');        
        disp([File{f} ' is being processed now']);
        StartT=tic;
        load([analysisPath '\' File{f}]); %load a single specified phage file
        Trace = stepdata; clear stepdata; %load the data and clear intermediate data
        FID   = fopen(CropFile); %open the *.crop file
        Tstart = sscanf( fgetl(FID),'%f'); %parse the first line, which is the start time
        Tstop  = sscanf( fgetl(FID),'%f'); %parse the second line, which is the stop time
        TimeLimits=[Tstart Tstop];
        Index=[]; %index of the feedback cycles that we're interested in
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for t=1:length(Trace.time);
            TempInd = (Trace.time{t}<Tstart)+(Trace.time{t}>Tstop);
            RemoveInd = find(TempInd==1);
            %clear the data that is outside the selected range
            Trace.time{t}(RemoveInd)    = [];
            Trace.contour{t}(RemoveInd) = [];
            Trace.force{t}(RemoveInd)   = [];
            if ~isempty(Trace.contour{t})
                Index=[Index t];
            end
        end
        for i=1:length(Index)
            Time   = Trace.time{Index(i)};
            Length = Trace.contour{Index(i)};
            %First of all, filter the data
            T = FilterAndDecimate(Time, Filter);
            L = FilterAndDecimate(Length, Filter);
            %figure; plot(T,L);
            %title(['File: ' File{f} '; Cell Used: ' num2str(Index(i))]);
            %xlabel('Time (sec)'); ylabel('Contour Length (bp)');
            [a b]=size(L); 
            if a>b 
                L=L'; %transpose for convenience
            end
            %define the bins for the data, later used to calculate the PWD
            HistogramBins = min(L):HistBinWidth:max(L);
            [N, D] = GhePairWiseDistribution(L,HistogramBins);
            PWD.Number{i}  = N;
            PWD.Distance{i}= D; 
            %to get the PWD, plot Number versus Distance
            PWD.Start(i)   = Length(1);
            PWD.Finish(i)  = Length(end);
            PWD.Segment(i) = abs(PWD.Start(i)-PWD.Finish(i)); %the length of the packaged DNA segment
            PWD.Location(i)= mean(Length); %where along DNA where this feedback cycle is located
            PWD.Time{i}    = Time;
            PWD.Contour{i} = Length;
            PWD.FilterFreq = F;
            PWD.Index(i)   = Index(i); %the index of the feedback cycle
            PWD.Tstart     = Tstart;
            PWD.Tstop      = Tstop;
            
            %figure;
            %plot(PWD.Distance{i},PWD.Number{i});
            %xlabel('Pairwise Distance (bp)');
            %ylabel('Occurence Number');
            %title(['File: ' File{f} '; Cell Used: ' num2str(Index(i)) ]);
        end
        %% Save the Velocity Data in a separate file in a separate folder
        Folder = [analysisPath '\' 'PWDData'];
        if ~exist(Folder,'dir') %if this folder doesn't exist, create it
            mkdir(Folder); %create it
        end        
        
        FilePWD = [Folder '\' File{f}(1:end-4) '_pwd.mat'];
        save (FilePWD, 'PWD'); %save data to a file
        disp(['Saved file ' FilePWD ]); %show message in terminal
        ElapsedT=toc(StartT);
        disp(['It took ' num2str(ElapsedT) ' sec to perform the PWD calculation']);
    else
        %the Crop *.crop file doesn't exist, skip the corresponding *.pro file
        disp([File{f} ' was skipped because it has no crop (*.crop) file']);
    end %end of IF
end %end of FOR
ElapsedT=toc(StartT);
disp(['It took ' num2str(ElapsedT) ' sec to perform the PWD calculation']);