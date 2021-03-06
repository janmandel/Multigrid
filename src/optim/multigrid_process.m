function [um,Jg] = multigrid_process(setup)
% Call:
% [um,Jg] = multigrid_process(setup)
%
% Description:
% Run the Projected descent Multigrid method from a setup matlab structure
%
% Inputs:
%   setup    Matlab structure with
%           u  First approximation of fire arrival time
%           p  Structure with:
%                   dx, dy      fire mesh spacing
%                   H           structure of interpolation operator matrices (one for each perimeter)
%                   g           structure of right sides of Hu=b for each H
%                   bc          structure of boundary conditions for each case = fixed values of the level set function where mask is false
%                   nfuelcat    structure with all the fuel data necessary to compute ROS
%                   R           matrix, rate of spread, on same nodes as u
%                   ofunc       matlab function, objective function comparing x=||grad u||^2 and y=R^2 such that xy=1
%                   dfdG        matlab function, partial derivative of ofunc to respect to x=||grad u||^2
%                   dfdG        matlab function, partial derivative of ofunc to respect to y=R^2
%                   q           q norm of the computation of J
%                   h           the stepsize to compute the gradient
%                   stepsize    step size for minimization
%                   numsteps    number of steps to try
%                   max_iter    maximum number of iterations
%                   select      handle to upwinding function
%                   max_step    max size of the steps to search
%                   nmesh       number of mesh points in each search
%                   max_depth   max number of searchs
%                   min_depth   min number of searchs
%                   umax        array, maximal value of u
%                   umin        array, minimal value of u
%                   bi			    indeces to compute the first objective function (coordinate x)
%                   bj			    indeces to compute the first objective function (coordinate y)   
%                   exp         experiment type, string. The options are:
%                         1) 'ideal': Ideal case
%                         2) 'file': Ideal case from WRF-SFIRE simulation
%                         3) 'real': Real case from WRF-SFIRE simulation
%                   rec         boolean: if record the plots into a gif file
%                   ros         boolean: if compute the Rate of spread dynamically
%                   plt         boolean: if display the plots
%           s  Structure only necessary for the real cases and with:
%                   sdates      simulation dates
%                   stimes      simulation times from the simulation start
%                   tig         ignition time from the simulation start
%                   kml         structure with the real perimeters information
%                   pdates      perimeter dates
%                   ptimes      perimeter times from the simulation start
%                   sframes     simulation frames where the perimeters are from
%                   ignS        structure with all the important variables from
%                               the simulation in the ignition time
%                   perS        structure with all the important variables from
%                               the simulation in the perimeter times
%                   perlS       structure with all the important variables from
%                               the simulation a posteriori of the perimeter times
%                   dynS        the prognostic variables necessary at all the time 
%                               steps in order compute the dynamic ROS 
%                               (only necessary when p.ros=1)
% Outputs:
%       um          Fire arrival time resulting from the Multigrid method
%       Jm          
%
% Developed in Matlab 9.2.0.556344 (R2017a) on MACINTOSH. 
% Angel Farguell (angel.farguell@gmail.com), 2018-08-15
%-------------------------------------------------------------------------

%% Setting up the case
u=setup.u;
[m,n]=size(u);
p=setup.p;
if ismember(p.exp,['ideal','file'])
    [p.X,p.Y]=meshgrid(1:m,1:n);
    R=representant(p.H);
    [p.H,ro]=condense(R);
    p.g=p.g(ro);
    kk=1;
elseif strcmp(p.exp,'real')
    s=setup.s;
    p.ignS=s.ignS;
    if p.ros
        p.dynS=s.dynS;
    end
    clear s
    p.X=p.ignS.fxlong; 
    p.Y=p.ignS.fxlat;
    us=u;
    p.Rs=p.R;
    p.Hs=p.H;
    p.gs=p.g;
    p.bcs=p.bc;
    p.bis=p.bi;
    p.bjs=p.bj;
    kk=length(us);
else
  error('Error: The experiment type is not specified. \n p.exp has to be one of these three strings:\n 1) ideal: Ideal case. \n 2) file: Ideal case from WRF-SFIRE simulation. \n 3) real: Real case.');
end

um=cell(1,kk);
Jg=cell(1,kk);
for k=1:kk
    %% Configuration parameters
    if strcmp(p.exp,'real')
        u=us{k};
        p.R=p.Rs{k};
        H=[p.Hs{k};p.Hs{k+1}];
        g=[p.gs{k};p.gs{k+1}];
        R=representant(H);
        [Hn,ro]=condense(R);
        gn=g(ro);
        p.H=Hn;
        p.g=gn;
        uu=unique(p.g);
        p.per1_time=uu(1);
        p.per2_time=uu(2);
        p.bc=p.bcs{k};
        p.bi=p.bis;
        p.bj=p.bjs;
        p.mask=p.M{k};
        p.vmask=p.mask;
    end
    %% Starting graphics
    if p.plt || p.rec
        if p.plt
            fig=figure('units','normalized','outerposition',[0 0 1 1]);
        elseif p.rec
            fig=figure('units','normalized','outerposition',[0 0 1 1],'visible','off');
        end
        stitle={strcat('Multigrid using f(x,y)=',char(p.f));'';''};
        h=suptitle(stitle);
        set(h,'FontSize',20,'FontWeight','Bold');
        subplot(2,2,1)
        ui=u;
        ui(~p.vmask)=nan;
        plot_sol_mesh(p.X,p.Y,ui,p.H,p.g); view([0 1]), tit=title(['Initial approximation T, J(T)=',num2str(cJ(u,p.R,p))]); set(tit,'FontSize',20,'FontWeight','Bold'), axi=zlabel('Fire arrival time'); set(axi,'FontSize',20,'FontWeight','Bold')
        drawnow
        if p.rec
            record(['multi_',p.exp,'.gif'],fig);
        end
        p.fig=fig;
    end

    %% Multigrid method
    [um{k},Jg{k}]=multigrid(u,p);
end

if kk==1
    um=um{1};
    Jg=Jg{1};
end

end
