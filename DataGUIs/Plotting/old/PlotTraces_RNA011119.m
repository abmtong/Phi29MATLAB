function lns = PlotTraces_RNA011119(varargin)
%First input is FilterRank (optional), rest are NVP's

%Handle NVPs with InputParser
p = inputParser();
%Validation fcns
isBool = @(x) islogical(x) || isnumeric(x) && (x==1 || x==0);
isInt = @(x) isnumeric(x) && rem(x,1) == 0;
%InputParser parameters
addOptional(p, 'FilterRank', 10, isInt )
addParameter(p, 'PlotUncropped', 0, isBool )
addParameter(p, 'SelectFiles', 0, isBool )
addParameter(p, 'NormContour', 0, isBool )
addParameter(p, 'TimeShift', 3, isInt )
addParameter(p, 'Name','', @ischar)
addParameter(p, 'Axis', [], @(x)isgraphics(x,'axes'))
addParameter(p, 'Path', [], @ischar)
%Parse inputs, assign to var.s
parse(p, varargin{:})
res = p.Results;

selFiles = res.SelectFiles;
normCon = res.NormContour;
dT = res.TimeShift;
plotUncropped = res.PlotUncropped;
filterRank = res.FilterRank;
name = res.Name;
ax = res.Axis;
path = res.Path;

thispath = fileparts(which('PlotTraces'));
addpath([thispath filesep 'StepFind_KV']);

if selFiles
    [files, path] = uigetfile('C:\Data\phage*.mat','MultiSelect','on');
    if ~path
        return
    end
    if ~iscell(files)
        files = {files};
    end
else    
    if isempty(path)
        path = uigetdir('C:\Data\');
        if ~path
            return
        end
    end
    files = dir([path filesep 'phage*.mat']);
    files = {files.name};
end
if isempty(files)
    fprintf('No traces found in %s\n',path);
    return
end
if isempty(ax)
    figure('Name',sprintf('PlotTraces %s', name))
    ax = gca;
end
hold(ax, 'on')

colfun = @(i) hsv2rgb( rem(i/10+17/30,1), 1, .6);

nums = str2double(strrep(strrep(files, files{1}(1:12),''),'.mat',''));
[~, sortind] = sort(nums);
files = files(sortind);
%files = fliplr(files); %if you want to reverse the order

cellfindfirst = @(stT)(@(times)(find(times > stT,1)));
cellfindlast =  @(enT)(@(times)(find(times < enT,1,'last')));
lns = cell(1,length(files));

numPlotted = 0;
for i = 1:length(files);
    if plotUncropped
        crop = [0 inf];
    else %Load crop
        name = files{i}(6:end-4); %Extracts * from phage*.mat
        cropfp = sprintf('%s\\CropFiles\\%s.crop', path, name);
        fid = fopen(cropfp);
        if fid == -1
            fprintf('Crop not found for %s\n', name)
            continue
        else
            crop = textscan(fid, '%f');
            fclose(fid);
            crop = crop{1};
        end
    end
    numPlotted = numPlotted + 1;
    
    %Load the file, extract the trace
    load([path filesep files{i}],'stepdata');
    con = stepdata.contour;
    tim = stepdata.time;
    
    %Find the cropped start/stop index of each segment of the trace (outside crop -> empty index)
    stInd = cellfun(cellfindfirst(crop(1)), tim,'UniformOutput',false);
    enInd = cellfun(cellfindlast (crop(2)), tim,'UniformOutput',false);
    
    col = colfun(numPlotted);
    plotText = 1;
    firstSeg = 1;
    dCon = 0;
    lntmp = gobjects(1,length(con));
    for j = 1:length(con)
        conf = con{j}(stInd{j}:enInd{j});
        timf = tim{j}(stInd{j}:enInd{j});
        if isempty(timf)
            continue
        end
        if firstSeg
            offsetT = timf(1);
            if normCon
%                 lastseg = find(cellfun(@isempty, enInd) == 0, 1, 'last');
%                 offsetCon = stepdata.contour{lastseg}(enInd{lastseg});
                
                offsetCon = conf(1);
            end
            firstSeg = 0;
        end
        if normCon
            dCon = 3000+(numPlotted-ceil(length(files)/2))*100*0-offsetCon;
        end
        conf = windowFilter(@mean, conf, [], filterRank) + dCon;
        timf = windowFilter(@mean, timf, [], filterRank) +numPlotted*dT-offsetT;
        if plotText
            text(double(timf(1)),double(conf(1)),files{i}(6:end-4))
            plotText = 0;
        end
        lntmp(j)=plot(ax, timf, conf,'Color',col);
    end
    lns{i} = lntmp;
    drawnow
end