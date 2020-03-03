function [wavelength, zStep, mag, dimensions, datasetName, numCams, mdstruct] = ParseXML(filePath)
    f = fopen(filePath,'r');
    fstring = '';
    found = false;
    while (~feof(f))
        curLine = fgets(f);
        pos = strfind(curLine,'&');
        newLine = curLine;
        if (~isempty(pos) && ~strcmpi(curLine(pos+1:pos+3),'amp'))
            newLine = [curLine(1:pos),'amp;',curLine(pos+1:end)];
            found = true;
        end
        fstring = [fstring,newLine];
    end
    fclose(f);
    
    if (found)
        f = fopen(filePath,'w');
        fprintf(f,fstring);
        fclose(f);
    end

    metadata = Utils.xml2struct(filePath);
    metadata = metadata.push_config.info;

    zStep = [];
    wavelength = [];
    mag = [];
    for i=1:length(metadata)
        att = metadata{i}.Attributes;
        if (isfield(att,'z_step'))
            zStep = str2double(att.z_step);
        end
        if (isfield(att,'wavelength'))
            wavelength = str2double(att.wavelength);
        end
        if (isfield(att,'detection_objective'))
            detection_objective = att.detection_objective;
            magStr = regexpi(detection_objective,'(\d+)x','tokens');
            magStr = magStr{1};
            mag = str2double(magStr);
            numCams = numel(strsplit(detection_objective,','));
        end
        if (isfield(att,'dimensions'))
            tok = regexpi(att.dimensions,'(\d+)x(\d+)x(\d+)','tokens');
            dimensions = cellfun(@(x)(str2double(x)),tok{1});
        end
        if (isfield(att,'data_header'))
            datasetName = att.data_header;
        end
    end
    
    % try to convert the cell array of structs to a single struct. This is
    % potentially breaking, so we print a warning if it fails
    mdstruct = struct;
    try
        for c = metadata
            for f = fieldnames(c{1}.Attributes)
                mdstruct = setfield(mdstruct, f{1}, getfield(c{1}.Attributes, f{1}));
            end
        end
    catch
        warning('Could not convert xml into a single structure. Returned structure will be empty');
    end
end
