%%%     Find leaves using the binary-strel-lazysnapping method
%%%
%%%     Developed for LeafMachine.org
%%%
%%%     William Weaver
%%%     University of Colorado, Boulder
%%%     Department of Ecology and Evolutionary Biology

%%% This is the structural element method for finding individual leaves in
%%% an image. It is not designed to find one leaf in a group of overlapping
%%% leaves. The algorithm gets the masks from the ML segmentation and creates
%%% 7 structural elements (strel) - 4 line elements for finding long blades
%%% of grass etc. and 3 globular strels for rounder leaves. I take the 
%%% union of the line strels and the intersection of the globular. 


function [compositeGlobular,compositeLine,blobTable,globData,lineData,binaryMasks] = findLeavesBinaryStrel(img,imgSize,family,megapixels,C,feature,...
    radius,cirAprox,COLOR,netSVM,saveLeafCandidateMasks,processLazySnapping,filename,destinationDirectory)
    % Build strel size
    % Default: radius = 30, cirAprox = 4
    SE = setStrelSize(radius,cirAprox);
    % Get binaryMasks from C, which is from segmentation
    % binaryMasks{1:5} = {Leaf,Background,Stem,Text_Black,Fruit_Flower};
    binaryMasks = getBinaryMasks(C);
    
    
    %%% This is the initial check based on ONLY the semantic segmentation
    composite = bwareaopen(binaryMasks{feature},50);
    [label, n] = bwlabel(composite);
    % Pass candidate masks to SVM, those that fail send to runLazySnappingForBlobs
    sprintf("initialSVMcheckAndClean")
    timeB = tic();
    
    [blobTable,blobFails] = initialSVMcheckAndClean(label,n,img,family,megapixels,COLOR,netSVM,saveLeafCandidateMasks,filename,destinationDirectory);
    toc(timeB)
    
    sprintf("blobFails")
    timeC = tic();
    
    if ~isempty(blobFails)
        if processLazySnapping
            %%% Below code erodes binary masks to prep for lazysnapping
            % Get UNION of "line strel" imerode masks
            compositeLine = fuseLineBinary(blobFails,SE,feature);
            %figure,imshow(compositeLine)

            % Get INTERSECTION of globular imerode masks
            compositeGlobular = fuseGlobularBinary(blobFails,SE,feature);
            %figure,imshow(compositeGlobular)

            % Ignore areas smaller than 25 pixels
            compositeLine = bwareaopen(compositeLine,50);
            compositeGlobular = bwareaopen(compositeGlobular,50);

            % Count number of potential solitary leaves
            [labelGlob, nGlob] = bwlabel(compositeGlobular);
            [labelLine, nLine] = bwlabel(compositeLine);

            [globData,lineData] = runLazySnappingForBlobs(labelGlob,labelLine,nGlob,nLine,img,imgSize,family,megapixels,COLOR,netSVM,saveLeafCandidateMasks,filename,fullfile(destinationDirectory,'Leaf_LazySnapping'));
        else
            sprintf("blobFails is empty")
            compositeLine = [];
            compositeGlobular = [];
            globData = [];
            lineData = [];
        end
    else
        sprintf("blobFails is empty")
        compositeLine = [];
        compositeGlobular = [];
        globData = [];
        lineData = [];
    end
    toc(timeC);
end