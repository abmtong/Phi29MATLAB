function [Nmin DwellTimes]=MonteCarlo_SimulatingMixedMutantSubunits(Tatp_on,Tatp_on_Mutant,Tatp_off,Tadp_on,Tadp_off,Tadp_off_Mutant,Tatp_tight,Tatp_tight_Mutant,AlphaT,AlphaD,AlphaTb,Nrounds)
% This function generates the dwell-time distribution for the following
% model: The Cycle starts with 5 ADPs, the ADPs are released one by one
% with ATP binding and ADP release interlaced. Here we assume that
% hydrolysis and translocation are fast, so we don't worry about that.
%
% AlphaT - how much slower is the first subunit at ATP loose binding
% AlphaD - how much slower is the first subunit at ADP release
%
% USE: [Nmin DwellTimes]=MonteCarlo_Simulating5Subunits(Tatp_on,Tatp_off,Tadp_on,Tadp_off,Tatp_tight,AlphaT,AlphaD,Nrounds)
%
% Gheorghe Chistol, 02 Aug 2011

if nargin==5
    PlotOption='Plot';
end

ActiveSubunits=4; %here we assume that only 4 subunits are active in one cycle, feel free to change this to 5

%T = MonteCarlo_ADP_Empty_ATP_TightATP(Tatp_off,Tatp_on,Tadp_off,Tadp_on,Tatp_tight)

DwellTimes=[]; %initialize the vector that contains all dwell times
for r=1:Nrounds
    CurrentCycleT = 0; %start with fully ATP loaded motor    
    %now we have a ring loaded with ADP
    n=1; %start with the first subunit
    while n<=ActiveSubunits 
        %let all subunits release ADP then bind ATP one at a time
        if n==1 %the first subunit: ADP-release and ATP-binding are special
            temp = MonteCarlo_ADP_Empty_ATP_ADP(Tatp_off,AlphaT*Tatp_on,AlphaD*Tadp_off,Tadp_on,AlphaTb*Tatp_tight);
        elseif n==2
            temp = MonteCarlo_ADP_Empty_ATP_ADP(Tatp_off,Tatp_on,Tadp_off,Tadp_on,Tatp_tight);
        elseif n==3 % this is the mutant subunit (noted in the rate)
            temp = MonteCarlo_ADP_Empty_ATP_ADP(Tatp_off,Tatp_on,Tadp_off,Tadp_on,Tatp_tight);
        elseif n==4
            temp = MonteCarlo_ADP_Empty_ATP_ADP(Tatp_off,Tatp_on,Tadp_off,Tadp_on,Tatp_tight);
        elseif n==5 % this is the mutant subunit (noted in the rate)
            temp = MonteCarlo_ADP_Empty_ATP_ADP(Tatp_off,Tatp_on,Tadp_off,Tadp_on,Tatp_tight);
        end
        CurrentCycleT = CurrentCycleT+temp;
        n=n+1; %move on to the next subunit
    end
    DwellTimes(end+1)=CurrentCycleT; %#ok<AGROW> %add the current dwell time to the list
end

Nmin = MonteCarlo_CalculateNminConfInt(DwellTimes, 1000, 0.68);

% if strcmp(PlotOption,'Plot')
%     figure;
%     hist(DwellTimes,20);
%     legend(['Nmin=' num2str(Nmin)]);
%     xlabel('Dwell Time (arbitrary)');
%     ylabel('Probability Density (arbitrary)')
%     title(['<ADP Release T>=' num2str(AdpReleaseT) '; <ATP Binding T>=' num2str(AtpBindingT) '; Nrounds=' num2str(Nrounds)]);
% end