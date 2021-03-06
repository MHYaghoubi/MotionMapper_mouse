function [vecs,vals,meanValue] = findPosturalEigenmodes(filePath,pixels,parameters)
%findPosturalEigenmodes finds postural eigenmodes based upon a set of
%aligned images within a directory.
%
%   Input variables:
%
%       filePath -> cell array of VideoReader objects or a directory 
%                       containing aligned .avi files
%       pixels -> radon-transform space pixels to use (Lx1 or 1xL array)
%       parameters -> struct containing non-default choices for parameters
%
%
%   Output variables:
%
%       vecs -> postural eignmodes (LxL array).  Each column (vecs(:,i)) is 
%                   an eigenmode corresponding to the eigenvalue vals(i)
%       vals -> eigenvalues of the covariance matrix
%       meanValue -> mean value for each of the pixels
%
% (C) Gordon J. Berman, 2016
%     Emory University

    
    addpath(genpath('./utilities/'));
    addpath(genpath('./PCA/'));
    
    if nargin < 3
        parameters = [];
    end
    parameters = setRunParameters(parameters);
    
    
    numProcessors = parameters.numProcessors;
    p = gcp('nocreate');
    c = parcluster;
    numAvailableProcessors = c.NumWorkers;
    
    if numProcessors > 1 && isempty(p)
     
        if numAvailableProcessors > numProcessors
            numProcessors = numAvailableProcessors;
            parameters.numProcessors = numAvailableProcessors;
        end
        
        if numProcessors > 1
            p = parpool(numProcessors);
        end
        
        
    else
        
        if numProcessors > 1
            currentNumProcessors = p.NumWorkers;
            numProcessors = min([numProcessors,numAvailableProcessors]);
            if numProcessors ~= currentNumProcessors
                delete(p);
                p = parpool(numProcessors); 
            end
        end
        
    end
    
    
    if iscell(filePath)
        
        vidObjs = filePath;
        
    else
        
        files = findAllImagesInFolders(filePath,'avi');
        N = length(files);
        vidObjs = cell(N,1);
        parfor i=1:N
           vidObjs{i} = VideoReader(files{i}); 
        end
        
    end
    
       
    numThetas = parameters.num_Radon_Thetas;
    spacing = 180/numThetas;
    thetas = linspace(0,180-spacing,numThetas);
    scale = parameters.rescaleSize;
    batchSize = parameters.pca_batchSize;
    numPerFile = parameters.pcaNumPerFile;
    
    [meanValue,vecs,vals] = ...
        onlineImagePCA_radon(vidObjs,batchSize,scale,pixels,thetas,numPerFile);
    
    
    if ~isempty(p) && parameters.closeMatPool
        delete(p);
    end
