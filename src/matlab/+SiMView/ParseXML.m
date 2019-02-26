function [wavelength, zStep, mag, dimensions] = ParseXML(filePath)
    f = fopen(filePath,'r');
    fstring = '';
    while (~feof(f))
        curLine = fgets(f);
        pos = strfind(curLine,'&');
        newLine = curLine;
        if (~isempty(pos))
            newLine = [curLine(1:pos),'amp;',curLine(pos+1:end)];
        end
        fstring = [fstring,newLine];
    end
    fclose(f);
    f = fopen(filePath,'w');
    fprintf(f,fstring);
    fclose(f);

    metadata = xml2struct(filePath);
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
        end
        if (isfield(att,'dimensions'))
            tok = regexpi(att.dimensions,'(\d+)x(\d+)x(\d+)','tokens');
            dimensions = cellfun(@(x)(str2double(x)),tok{1});
        end
    end
end
