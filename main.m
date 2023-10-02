clear all; close all; clc
% Twitch and tetanus from human quadriceps
% source: https://pubmed.ncbi.nlm.nih.gov/1549641/

load('twitch_tetanus.mat')
parms.t = tx(:,1)/1000;
parms.FT = Fy(:,2)/100;
parms.Ft = Fy(:,1)/100;

%% redo optimization?
redo = 0;

%% optimize or load
parms.A = 1;
parms.u_func = @(t,parms) parms.A * (t < parms.tstop);

if redo 
    % fminsearch setting
    fopt = optimset('MaxIter',100);
    tau_max = .15; % maximum time constant considered (s)

    for i = 1:100
        disp(i)

        % generate random initial guess
        P0 = tau_max * rand(1,4);

        % find optimal time constant
        [P(i,:),FVAL(i),EXITFLAG,OUTPUT] = fminsearch(@(p) costfun(p, parms),P0,fopt);
    end
    
    % save
    save('P_opt.mat','P','FVAL')
else
    load('P_opt.mat','P','FVAL')
end

%% plot time constant vs. SSE
if ishandle(1), close(1); end; figure(1)
titles = {'\tau_{act}', '\tau_{deact}','\tau_{fac}', '\tau_{defac}'};

for i = 1:4
    subplot(2,2,i);     
    plot(P(FVAL==min(FVAL),i),FVAL(FVAL==min(FVAL)),'r.','markersize',10); hold on
    plot(P(:,i),FVAL,'.','color',[.5 .5 .5]); hold on
    plot(P(FVAL==min(FVAL),i),FVAL(FVAL==min(FVAL)),'r.','markersize',10); hold on
    
    axis([0 .15 0 .4]); box off
    title([titles{i}, ' (optimal: ', num2str(round(P(FVAL==min(FVAL),i)*1000)), ' ms)']); xlabel('Time constant (s)'); ylabel('SSE (model - data)');
end

disp(P(FVAL==min(FVAL),:))
P_opt = P(FVAL==min(FVAL),:);

set(gcf,'units','normalized')
set(gcf,'position', [.2 .2 .3 .4])

subplot(221)
legend('minimal SSE','local minimum','location','best'); legend box off
saveas(gcf, 'Fig1.jpg')

%% simulate optimal time constants
if ishandle(2), close(2); end; figure(2)
color = get(gca,'colororder');

% plot data
subplot(122);
plot([parms.t; parms.t], [parms.FT; parms.Ft],'o','color',[.5 .5 .5],'markerfacecolor',[.5 .5 .5],'markersize',4); hold on

% ODE settings
odeopt = odeset('maxstep',1e-4);

% choose optimal value
parms.tau = P_opt;

% simulate twitch
parms.tstop = .005;
[t_twitch,x_twitch] = ode113(@dXfunc, [0 1], [0 0], odeopt, parms);

% simulate tetanus
parms.tstop = 1;
[t_tetanus,x_tetanus] = ode113(@dXfunc, [0 1], [0 0], odeopt, parms);

% plot states
titles = {'Activation','Force'};
for i = 1:2
    subplot(1,2,i);
    plot(t_tetanus, x_tetanus(:,i),'-','linewidth',2,'color',color(1,:)); hold on; box off
    plot(t_twitch, x_twitch(:,i),'--','linewidth',2,'color',color(1,:));  box off
    axis([0 .3 0 1]); title(titles{i})
    xlabel('Time (s)'); ylabel(titles{i})
end

set(gcf,'units','normalized')
set(gcf,'position', [.5 .2 .3 .4])
legend('Data','Model','location','best'); legend boxoff
saveas(gcf, 'Fig2.jpg')

%% functions
function[dX] = dXfunc(t, X, parms)
    
    % excitation
    U = parms.u_func(t,parms);

    % activation-rate
    dX(1,1) = (U-X(1)) / (parms.tau(1) * (U>.5) + parms.tau(2) * (U<.5));
    
    % force-rate
    dX(2,1) = (X(1)-X(2)) / (parms.tau(3) * (X(1)>X(2)) + parms.tau(4) * (X(1)<=X(2)));

end

function[cost] = costfun(p,parms)

    odeopt = odeset('maxstep',1e-3);
    parms.tau = p;
    
    % twitch
    parms.tstop = .005;
    [t,x] = ode113(@dXfunc, [0 1], [0 0], odeopt, parms);  % run simulation
    
    Ft = interp1(t, x(:,2), parms.t); % interpolate force to data time points
    Ct = sum((Ft(:)-parms.Ft(:)).^2); % SSE
    
    % tetanus
    parms.tstop = 1;
    [t,x] = ode113(@dXfunc, [0 1], [0 0], odeopt, parms); % run simulation
    
    FT = interp1(t, x(:,2), parms.t); % interpolate force to data time points
    CT = sum((FT(:)-parms.FT(:)).^2);% SSE
     
    % total SSE (twitch + tetanus)
    cost = Ct + CT;
end
