%Startup script to add most commonly used folders to the search path
%I recommend you either start in this folder [so Matlab runs this automatically],
% or make a shortcut to run this .m file.
%Do not move this .m file from the root Matlab folder, 
% as paths are constructed relative to this file

%This is a script, so use long names so we can create/delete them without 
% worry of overwriting workspace var.s
startupbasepath99 = fileparts(mfilename('fullpath')); %C:\... \MATLAB\
startupfolders99 = {...
    'RawDataProcessing/HiRes' ...
    'RawDataProcessing/HiRes/helperFunctions' ...
    'RawDataProcessing/HiRes/Calibration' ...
    'DataGUIs' ...
    'DataGUIs/StepFind_KV' ...
    'DataGUIs/StepFind_HMM' ...
    'DataGUIs/Velocity' ...
    'DataGUIs/Helpers' ...
    'DataGUIs/ForceExt' ...
    'DataGUIs/Plotting'};
cellfun(@(x)addpath([startupbasepath99 filesep x]), startupfolders99);
clear startupbasepath99 startupfolders99

%I like these formatting options, so also apply them here
format shortG %Allows for display of numbers with varying exponents, e.g. [1 1e99] displays instead of 1e99 x [0, 1]
format compact %Removes blank lines when the command window shows an output