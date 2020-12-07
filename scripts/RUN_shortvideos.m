clear all;
Screen('Close');
clearvars;
sca;

% 1. grab participant number ___________________________________________________

sub_prompt = 'PARTICIPANT (in raw number form, e.g. 1, 2,...,98): ';
sub_num = input(sub_prompt);
b_prompt = 'BIOPAC YES=1 NO=0 : ';
biopac = input(b_prompt);

debug = 1; %DEBUG_MODE = 1, Actual_experiment = 0


shortvideos(sub_num, biopac, debug)
