function [display_onset, trajectory, RT, response_onset, biopac_displayonset, biopac_response] = judgement_rating(p, duration, rating_texture, biopac, channel)
% *************************************************************************
%   Program Name: self_other_video_judgement_rating.m
%   Original Programmer: Phil Kragel
%   Appropriated by: Luke Slipski 7/11/2019
%   Project: Spacetop
%   Created: 6/20/2019
%   This function takes a judgement type ('self_other', 'likeability', or
%   'mentalizing') and a rating duration (number of seconds) as parameters.
%   It displays the specified rating scale, collects continuous trajectory,
%   Reaction Time, and response_onset values using mouse position.
%
%  Input:
%   1.) judgement_type: use keywords 'self_other', 'likeability', or
%   'mentalizing' to choose the rating image
%   2.) movie_playing: the main self_other_video_task will pass in the video
%   name such that if it is a mentalizing video, the correct mentalizing
%   rating scale is diplayed
%   3.) p: specifies the name of the PsychToolBox Screen that the
%   judgement rating screen should appear on
%   4.) duration: the number of seconds for which the rating scale should
%   be displayed
%
%   Output:
%    1.) trajectory: The movement of the trackball (mouse) across the rating scale
%       recorded as: n samples x 2 matrix (x coord, y coord)
%    2.) RT: Reaction Time from when screen is displayed until current
%    measurement of mouse location in seconds recorded as n samples x 1
%    matrix (elapsed time)
%    3.) response_onset: the time at which each measurement is taken
%     recorded as: n samples x 1 matrix (time)
%
%
%
%
%
% *************************************************************************
%----------------------------------------------------------------------
%                       Variables and Output Values
%----------------------------------------------------------------------
SAMPLERATE = .001; % used in continuous ratings
TRACKBALL_MULTIPLIER=1;
display_onset= NaN;
trajectory= NaN;
RT= NaN;
response_onset= NaN;
biopac_displayonset= NaN;
biopac_response= NaN;

HideCursor;

% Here we call some default settings  for setting up Psychtoolbox
PsychDefaultSetup(2)

try


%%% configure screen
dspl.screenWidth = p.ptb.rect(3);
dspl.screenHeight = p.ptb.rect(4);
dspl.xcenter = dspl.screenWidth/2;
dspl.ycenter = dspl.screenHeight/2;

dspl.cscale.width = 964;
dspl.cscale.height = 480;
dspl.cscale.w = Screen('OpenOffscreenWindow',p.ptb.screenNumber);
% paint black
Screen('FillRect',dspl.cscale.w,0)
% assign scale image
%dspl.cscale.imagefile = scale_image;
%rating_texture = Screen('MakeTexture',p.ptb.window, imread(dspl.cscale.imagefile));

% placement
dspl.cscale.rect = [...
    [dspl.xcenter dspl.ycenter]-[0.5*dspl.cscale.width 0.5*dspl.cscale.height] ...
    [dspl.xcenter dspl.ycenter]+[0.5*dspl.cscale.width 0.5*dspl.cscale.height]];
%Screen('DrawTexture',dspl.cscale.w,dspl.cscale.texture,[],dspl.cscale.rect);
Screen('DrawTexture',dspl.cscale.w,rating_texture,[],dspl.cscale.rect);


% add title
Screen('TextSize',dspl.cscale.w,40);

% determine cursor parameters for all scales
cursor.xmin = dspl.cscale.rect(1);
cursor.xmax = dspl.cscale.rect(3);
cursor.ymin = dspl.cscale.rect(2);
cursor.ymax = dspl.cscale.rect(4);

cursor.size = 8;
% cursor.xcenter = ceil(cursor.xmax - cursor.xmin);
% cursor.ycenter = ceil(cursor.ymax - cursor.ymin);

cursor.xcenter = ceil(dspl.cscale.rect(1) + (dspl.cscale.rect(3) - dspl.cscale.rect(1))*0.5) + 20;
cursor.ycenter = ceil(dspl.cscale.rect(2) + (dspl.cscale.rect(4)-dspl.cscale.rect(2))*0.847);

RATINGTITLES = {'INTENSITY'};
biopac_linux_matlab(biopac, channel, channel.rating, 0);

% initialize
Screen('TextSize',p.ptb.window,72);
DrawFormattedText(p.ptb.window,'.','center','center',255);
display_onset = Screen('Flip',p.ptb.window);
biopac_displayonset = biopac_linux_matlab(biopac, channel, channel.rating, 1);


cursor.x = cursor.xcenter;
cursor.y = cursor.ycenter;

sample = 1;
SetMouse(cursor.xcenter,cursor.ycenter);
nextsample = GetSecs;

buttonpressed  = false;
rlim = 250;
xlim = cursor.xcenter;
ylim = cursor.ycenter;

% while loops to show scale and record output measurements for specified
% duration
while GetSecs < display_onset + duration

    loopstart = GetSecs;

    % sample at SAMPLERATE
    if loopstart >= nextsample
        ctime(sample) = loopstart;
        trajectory(sample,1) = cursor.x;
        trajectory(sample,2) = cursor.y;
        nextsample = nextsample+SAMPLERATE;
        sample = sample+1;
    end

    if ~buttonpressed
    % measure mouse movement
    [x, y, buttonpressed] = GetMouse;

    % reset mouse position
    SetMouse(cursor.xcenter,cursor.ycenter);


    % calculate displacement
    cursor.x = (cursor.x + x-cursor.xcenter) * TRACKBALL_MULTIPLIER;
    cursor.y = (cursor.y + y-cursor.ycenter) * TRACKBALL_MULTIPLIER;
    [cursor.x, cursor.y, xlim, ylim] = limit(cursor.x, cursor.y, cursor.xcenter, cursor.ycenter, rlim, xlim, ylim);


    % check bounds
    if cursor.x > cursor.xmax
        cursor.x = cursor.xmax;
    elseif cursor.x < cursor.xmin
        cursor.x = cursor.xmin;
    end

    if cursor.y > cursor.ymax
        cursor.y = cursor.ymax;
    elseif cursor.y < cursor.ymin
        cursor.y = cursor.ymin;
    end

    % produce screen
    Screen('CopyWindow',dspl.cscale.w,p.ptb.window);
    % add rating indicator ball
    Screen('FillOval',p.ptb.window,[255 0 0],[[cursor.x cursor.y]-cursor.size [cursor.x cursor.y]+cursor.size]);
    Screen('Flip',p.ptb.window);

    elseif any(buttonpressed)

       response_onset = GetSecs;
       RT = response_onset - display_onset;
       buttonpressed = [0 0 0];
       biopac_response = biopac_linux_matlab(biopac, channel, channel.rating, 0);
       WaitSecs(0.5);


       Screen('DrawLines', p.ptb.window, p.fix.allCoords,...
          p.fix.lineWidthPix, p.ptb.white, [p.ptb.xCenter p.ptb.yCenter], 2);
       % fStart1 = GetSecs;
       % Flip to the screen
       Screen('Flip', p.ptb.window);
       remainder_time = duration-0.5-RT;
       WaitSecs('UntilTime', display_onset + duration);

    disp('got here')
    end
end

catch e
    fprintf(1,'The identifier was:\n%s',e.identifier);
    fprintf(1,'There was an error! The message was:\n%s',e.message);
    Screen('CloseAll');
end

end

%-------------------------------------------------------------------------------
%                            function Limit cursor
%-------------------------------------------------------------------------------
% Function by Xiaochun Han
function [x, y, xlim, ylim] = limit(x, y, xcenter, ycenter, r, xlim,ylim)
if (y<=ycenter) && (((x-xcenter)^2 + (y-ycenter)^2) <= r^2)
   xlim = x;
   ylim = y;
elseif (y<=ycenter) && (((x-xcenter)^2 + (y-ycenter)^2) > r^2)
   x = xlim;
   y = ylim;
elseif y>ycenter && (((x-xcenter)^2 + (y-ycenter)^2) <= r^2)
   xlim = x ;
   y = ycenter;
elseif y>ycenter && (((x-xcenter)^2 + (y-ycenter)^2) > r^2)
   x = xlim;
   y = ycenter;
end
end
