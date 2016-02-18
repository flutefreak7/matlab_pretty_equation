function pretty_equation(equation)
% Pops up a figure with a pretty latex-formatted equation for a Matlab
% expression. Works for previous line in a script, previous command at
% command prompt, or for equations passed inline:
%
% 1. In a script: Make a call to pretty_equation() on the following line.
%
%     Example:
%     y = exp(a^3 / b^2) * (x^2 + 2*x - sqrt(3))/(x^3 + 2*x^2 - 4* x + 12);
%     pretty_equation()
%
%     Note: Script execution will continue when the Equation Viewer dialog
%     is dismissed.
% 
% 2. Inline: just provide the expression as a string argument:
%
%     Example:
%     pretty_equation('y = exp(a^3 / b^2)')
%
% 3. Command Line: Just call pretty_equation() at the command line to
%    visualize the previous command.
%
%     Example:
%     >> y = x^2 + x;
%     >> pretty_equation()
%
% Consideration has been made for multi-line expressions and comments to
% make the utility robust for most use cases.  Expressions are parsed with
% Matlab's Symbolic Toolbox.  Not all Matlab expressions translate to valid
% symbolic equations (especially non-math functions, but also arrays for
% example).  Error handling exists to inform when expressions aren't
% parsable.  
    
    if nargin < 1
        % Get the line from the calling file above the pretty_equation call
        equation = get_line_above_caller();
    end
    % Show the user a latex pretty-printed version of the line
    fig = make_equation_figure(equation);
    % Hold the code until figure is dismissed
    uiwait(fig)
end

function line = get_a_line(filename, n)
% Grab the nth line from a file, or the nth previous call at the command
% prompt

    if strcmp(filename, '**MatlabCommandPrompt**')
        % Get the command history...
        historypath = com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory;
        % Get previous expression from history
        line = strtrim(char(historypath(end-n)));
    else
        % Open the file
        fid = fopen(filename, 'r');
        % Skip n-1 lines
        for i = 1:n-1
            fgetl(fid);
        end
        % grab the line
        line = fgetl(fid);
        % Close the file
        fclose(fid);
    end
end

function hist_len = history_length()
    historypath = com.mathworks.mlservices.MLCommandHistoryServices.getSessionHistory;
    hist_len = length(historypath);
end

function eqn = get_line_above_caller()
% Retrieve the line above the original call to pretty_equation
    [ST, ~] = dbstack('-completenames');
    
    % Find the current file in the call stack, then look 1 call above to
    % get the caller
    for i = 1:length(ST)
        if strcmp(ST(i).name, mfilename)
            caller = i+1;
            break
        end
    end
    
    % Handle empty Command Prompt calls
    if caller > numel(ST)
        filename = '**MatlabCommandPrompt**';
        prompt = true;
        n = 1;
    else
        % Extract the line above the call to pretty_equation
        filename = ST(caller).file;
        prompt = false;
        n = ST(caller).line-1;
        if n < 1
            error('Unable to find any lines above pretty_equation() call.')
        end
    end
    line = get_a_line(filename, n);

    % Strip simple trailing comment
    % (neglects valid % in strings, but strings in
    %  an expression would break the symbolic expression parser
    %  anyway, so it's not an edge case I care about)
    eqn = regexprep(line, '\s*%.*', '');
    
    % Check for '...' in preceding lines
    line_continuation = true;
    i = n;
    while line_continuation
        if prompt
            i = i + 1;
            valid = i <= history_length();
        else
            i = i - 1;
            valid = i > 0;
        end
        if valid
            % Get next line up
            line_above = strtrim(get_a_line(filename, i));
            % strip comments (neglects % in strings edge case)
            line_above = regexprep(line_above, '\s*%.*', '');
            
            % find trailing ellipses
            ellipses = regexp(line_above, '\.\.\.$', 'once');
            if ~isempty(ellipses)
                % remove the ellipses
                line_above = regexprep(line_above, '\s*\.\.\.$', ''); 
                % prepend the line to the equation
                eqn = sprintf('%s%s', line_above, eqn);
            else                
                line_continuation = false;
            end
        else
            line_continuation = false;
        end
    end
end

function fig = make_equation_figure(eqn)
% Make a figure with only a text object for rendering an equation with
% latex.
    
    % Make the figure (with minimal junk)
    fig = figure('Name', 'Equation Viewer', ...
        'NumberTitle', 'off', ...
        'MenuBar', 'none', ...
        'ToolBar', 'none', ...
        'Color', [1, 1, 1]);
    % Expand Axes to completely fill the figure (this is just a
    % canvas for a text box, so we don't care about axes label space)
    ax = axes('position', [0, 0, 1, 1], 'Units', 'Normalized');
    % Hide the axes
    axis off
    % Make the textbox with latex equation
    try
        htext = text(0.5, 0.5, ['$',latex(sym(eqn)),'$'], ...
            'interpreter','latex', ...
            'FontSize', 10, ...
            'HorizontalAlignment', 'center');
    catch
        msg = sprintf('Oops! I had trouble parsing the expression:\n "%s"', ...
            eqn);
        htext = text(0.5, 0.5, msg, ...
            'FontSize', 10, ...
            'HorizontalAlignment', 'center');
    end
    % Scale up the equation font to fill the figure
    fit_text_to_figure(htext)
    % Eliminate the dead space in the figure by pulling it in to match the
    % equation dimensions
    fit_figure_to_text(fig, htext)
end

function fit_text_to_figure(htext)
% Scales a text object's FontSize until it fills 95% of it's parent
    
    % Temporarily set the units to Normalized
    ax = htext.Parent;
    units = ax.Units;
    ax.Units = 'Normalized';
    
    while max(htext.Extent) < 0.95
        % Use ratio of current size to parent to scale up the font quickly
        size = max(htext.Extent);
        scale = 0.95 / size;
        htext.FontSize = htext.FontSize * scale;
    end
    
    % Reset the axes units to avoid causing side-effects
    ax.Units = units;
end

function fit_figure_to_text(fig, htext)
% Scale down the dimension of a figure that is creating dead space relative
% to the text box
    
    % Get the textbox dimensions
    pos_text = htext.Extent;
    w = pos_text(3);
    h = pos_text(4);
    
    if w > h
        % Equation is wide...
        pos = fig.Position;
        scale = h/w;
        % Scale down the figure's height
        fig.Position = [pos(1), pos(2), pos(3), pos(4)*scale];
    else
        % Equation is tall...
        pos = fig.Position;
        scale = w/h;
        % Scale down the figure's width
        fig.Position = [pos(1), pos(2), pos(3)*scale, pos(4)];
    end
end
