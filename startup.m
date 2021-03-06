% Set all the paths to include functions from
format compact
d={ [pwd,'/src/fft'],...
    [pwd,'/src/fire'],...
    [pwd,'/src/interp'],...
    [pwd,'/src/netcdf'],...
    [pwd,'/src/optim'],...
    [pwd,'/src/plot'],...
    [pwd,'/src/setup'],...
    [pwd,'/src/utils'],...
};
for i=1:length(d),
    s=d{i};
    addpath(s)
    disp(s)
    ls(s)
end
clear d i s
