function [outProtocol, outraw, acrs, kit, ki, trapposraw] = getProtocol(indat, inOpts)
%Probably defer to using the output in _protocol.txt from the labVIEW script, but this could still be useful

%OH LV uses L-M fitting, while Matlab defaults to TRR. Consider checking swapping from TRR to L-M in optimoptions

if nargin < 1 || isempty(indat)
    [f, p]= uigetfile('*.mat');
    if ~p
        return
    end
    load(fullfile(p, f))
    indat = eldata;
elseif ischar(indat)
    load(indat)
    indat = eldata;
end

opts.cropt = [0 inf];
opts.cropstr = '';
opts.toff = 0; %s, offset between data and transition
opts.ttrim = [.05 0]; %s, time to trim from each side
% opts.circacorr = 0; %whether to use circular acorr or not
opts.verbose = 1; %wether to plot the output or not
opts.outrottime = 1; %s, use 1 for easy scaling to higher times
% opts.zetafitexp = 1; %whether to fit the acorr to an exp or just sum
opts.zetafittmax = 0.01; %maximum t to fit/sum to in acorr

if nargin > 1 && ~isempty(inOpts)
    opts = handleOpts(opts, inOpts);
end

%extract for easiness
tim = indat.time;
rot = -indat.rotlong;
Fs = indat.inf.FramerateHz;

params = procparams(indat.inf.Mode, indat.inf.Parameters);
opts.tdwell = params.tdwell;
opts.stepsz = params.stepsz;
opts.rotdir = 2*strncmp('S', params.dir,1) -1; %+ for syn, - for hy

dwlen = floor(Fs * opts.tdwell);

%make start, end indicies for dwells
len = length(tim);
indSta = (ceil(opts.toff *Fs):dwlen:len) + ceil(opts.ttrim(1) * Fs);
%cut first and last, bc first has a big move, last might be incomplete
indSta = indSta(2:end-1);
slen = length(indSta);

%Gather dwells, and their resulting acorr and zetas (frictions)
dws = cell(1,slen);
acrs = cell(1, slen);
zetas = zeros(1, slen);

dwlencr = floor((opts.tdwell - sum(opts.ttrim)) * Fs);
fitpts = ceil(Fs*opts.zetafittmax);

for i = 1:slen
    dws{i} = rot(indSta(i):indSta(i) +dwlencr-1);
    [acrs{i}, zetas(i)] = acrlv(dws{i}-mean(dws{i}),fitpts);
end

%Get positions of dwells
rotpos = cellfun(@mean, dws);
%Get positions of trap, in rev.s
trappos = (1:length(rotpos)) * opts.rotdir * opts.stepsz /360;
%The bead can slip and then be in the other side of the trap: account for this
%Check which side of the trap the bead is closer to
% Subtract bead pos and trap pos, see if this is an integer or half-integer
isodd = logical(mod( round((rotpos - trappos) * 2) , 2));
trappos(isodd) = trappos(isodd) + 0.5;
trapposraw = trappos;

%keep those in cropt
tcropind = opts.cropt * Fs;
kit = indSta > tcropind(1) & indSta + dwlencr < tcropind(2);
dws = dws(kit);
rotpos = rotpos(kit);
trappos = trappos(kit);
isodd = isodd(kit);
zetas = zetas(kit);

%Reject dwells where it's moving
rngs = cellfun(@range, dws);
ki = rngs<100/360; %Max allowable devation = 100 deg.
dws = dws(ki);
rotpos = rotpos(ki);
trappos = trappos(ki);

isodd = isodd(ki);
zetas = zetas(ki);

% sds = cellfun(@std, dws);
% rts = zetas ./ sds;

%Average by spin
[trappos1, zetas1, zetas1sd, zetas1n] = splitbymodn(trappos, zetas, 1);
% [~, prot1, prot1sd, prot1n] = splitbymodn(trappos, zetas.^-.5, 1);
prot1 = zetas1.^-.5;
prot1sd = sqrt(zetas1sd.^2 ./ zetas1.^2).*zetas1;
prot1n = zetas1n;

% %Average by triad - probably a bad idea
% [trappos3, zetas3, zetas3sd, zetas3n] = splitbymodn(trappos, zetas, 1/3);

%Calculate protocol
outProtocol = vel2prot(trappos1, 1./sqrt(zetas1), 2);
outProtocol(:,1) = outProtocol(:,1)*opts.outrottime;

outraw.zetas = zetas;
outraw.trappos = trappos;
outraw.rotpos = rotpos;
outraw.zetas1 = zetas1;
outraw.trappos1 = trappos1;
outraw.isodd = isodd;
outraw.prot1 = prot1;
outraw.prot1sd = prot1sd;
outraw.prot1n = prot1n;

%Plot if verbose
if opts.verbose
    %{
%     %plot raw data
%     figure('Name', 'Raw Data')
%     %plot full trace
%     subplot(1,2,1)
%     plot(tim, rot)
%     %Add lines showing boundaries
%     yl = ylim;
%     for i = 1:slen
%         line(tim(indSta(i)) * ones(1,2), yl, 'Color', 'g')
%         line(tim(indSta(i)+dwlencr) * ones(1,2), yl, 'Color', 'r')
%     end
%     %plot sections
%     subplot(1,2,2)
%     hold on
%     cellfun(@(x)plot((0:dwlencr-1) / Fs, x), dws)
    
    %plot acorrs
%     figure('Name', 'Acorrs')
%     hold on
%     cellfun(@(x)plot((0:dwlencr-1) / Fs, x), acrs(ki))
%     xlim([0 opts.zetafittmax])
    
    %plot gammas as a fnc of 
    
%     %plot protocol velocities and then protocol(theta) mod 1/3
%     figure('Name', 'Protocol')
%     ax=subplot(2,2,[1 2]);
%     set(ax, 'YScale', 'log')
%     hold on
%     %plot three quadrants as different colors
%     tol = eps(max(rotpos));
%     mrp = mod(rotpos(si),1)+tol;
%     ki1 = mrp > 0 & mrp < 1/3;
%     scatter(mod(rotpos(ki1), 1/3), 1./sqrt(zetas(ki1)), 'r');
%     ki2 = mrp > 1/3 & mrp < 2/3;
%     scatter(mod(rotpos(ki2),1/3), 1./sqrt(zetas(ki2)), 'g');
%     ki3 = mrp > 2/3 & mrp < 1;
%     scatter(mod(rotpos(ki3),1/3), 1./sqrt(zetas(ki3)), 'b');
%     %plot averaged together
%     errorbar(rotpos3, 1./sqrt(zetas3), zetas3sd, 'k', 'LineWidth', 1)
%     ax1= axes('Position', [.075 .975-.225 .9 .225]);
%     hold on
%     %separate by isodd and by triad
%     triad = mod(floor(trappos * 3),3);
%     scatter(mod(trappos(isodd&triad == 0), 1), (zetas(isodd&triad == 0)), 'r');
%     scatter(mod(trappos(~isodd&triad == 0), 1),(zetas(~isodd&triad == 0)), 'r*');
%     errorbar(trappos1, zetas1, zetas1sd./sqrt(zetas1n), 'k', 'LineWidth', .5)
%     ax2= axes('Position', [.075 .975-2*.225 .9 .225]);
%     hold on
%     scatter(mod(trappos(isodd&triad == 1), 1)-1/3, (zetas(isodd&triad == 1)), 'g');
%     scatter(mod(trappos(~isodd&triad == 1), 1)-1/3, (zetas(~isodd&triad == 1)), 'g*');
%     errorbar(trappos1-1/3, zetas1, zetas1sd./sqrt(zetas1n), 'k', 'LineWidth', .5)
%     ax3= axes('Position', [.075 .975-3*.225 .9 .225]);
%     hold on
%     scatter(mod(trappos(isodd&triad == 2), 1)-2/3, (zetas(isodd&triad == 2)), 'b');
%     scatter(mod(trappos(~isodd&triad == 2), 1)-2/3, (zetas(~isodd&triad == 2)), 'b*');
%     errorbar(trappos1-2/3, zetas1, zetas1sd./sqrt(zetas1n), 'k', 'LineWidth', .5)
%     
%     ax4= axes('Position', [.075 .975-4*.225 .9 .225]);
%     hold on
%     scatter(mod(trappos(isodd&triad == 0), 1/3), (zetas(isodd&triad == 0)), 'r');
%     scatter(mod(trappos(~isodd&triad == 0), 1/3), (zetas(~isodd&triad == 0)), 'r*');
%     scatter(mod(trappos(isodd&triad == 1), 1/3), (zetas(isodd&triad == 1)), 'g');
%     scatter(mod(trappos(~isodd&triad == 1), 1/3), (zetas(~isodd&triad == 1)), 'g*');
%     scatter(mod(trappos(isodd&triad == 2), 1/3), (zetas(isodd&triad == 2)), 'b');
%     scatter(mod(trappos(~isodd&triad == 2), 1/3), (zetas(~isodd&triad == 2)), 'b*');
%     errorbar(trappos3, zetas3, zetas3sd./sqrt(zetas3n), 'k', 'LineWidth', 1)
% 
%     axs = [ax1 ax2 ax3 ax4];
%     arrayfun(@(x)axis(x, 'tight'), axs)
%     arrayfun(@(x)set(x, 'YScale', 'log'), axs)
%     arrayfun(@(x)set(x, 'XLim', [0 1/3]), axs)
%     linkaxes(axs, 'x')
    %}
    figure('Name', 'Protocol all')
    %plot together
    ax= subplot(2,1,1);
    hold on
    scatter(mod(trappos(isodd), 1), zetas(isodd).^-.5, 'MarkerEdgeColor', [0    0.4470    0.7410]);
    scatter(mod(trappos(~isodd), 1), zetas(~isodd).^-.5,'*', 'MarkerEdgeColor', [0    0.4470    0.7410]);
	errorbar(trappos1, circsmooth(prot1,3), prot1sd ./ prot1n, 'k');

    %     errorbar(trappos1, zetas1.^-.5, zetas1sd.^-.5./sqrt(zetas1n), 'k');
    xlim(ax, [0 1])
    %Plot angular histogram, taken from @ElRoGUI
    ax=subplot(2,1,2);
    
    thbin = 4; %thbin must divide 120
    [p, x] = angularhist(indat.x, indat.y, thbin);
    plot(x/2/pi,p/max(p))
    hold on
    p2 = histcounts(mod(rot,1), [0 (x+thbin/2/180*pi)/2/pi]);
    plot(x/2/pi,p2/max(p2))
    axis(ax, 'tight')
    %Find most probable 3-fold rotation axis
    p2sm = circsmooth(p2, 5);
    p2sm = sum(reshape(p2sm, [], 3), 2);
    [~, maxi] = max(p2sm);
    yl = ylim;
    xs = x(maxi);
    xs = xs/2/pi + [0 1/3 2/3];
    arrayfun(@(x)line( x * [1 1], yl, 'Color', [0.8500 0.3250 0.0980] ), xs); %Second color of @lines
    
    %Plot zetas, too; they should coincide
    plot(trappos1, rescale(circsmooth(prot1,3), yl), 'k');
    %Plot zeta from lv program, as sanity check
    if isfield(indat,'prot')
        plot(indat.prot(:,1)/360,rescale(circsmooth(indat.prot(:,2),3),yl))
    end
    
    %Does e.g. gamma correspond to places of residence? Should plot that also.
    %For not exactly 3-fold symmetric, can I rescale to squish some / enlarge other triads?
end
