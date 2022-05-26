% add_back_ICs.m
% Sarah West
% 4/29/22

% A script to add back ICs that you think are real but were taken out by
% regularize_ICs.

% Wil run as a script, saves to end of list of artifact_removed sources
% so it doesn't disrupt any previously saved artifact
% removals.


% Mouse 1087
% Notes:
% Right rostral medial M2 (in same IC as left rostral medial M2, artifacts 
% removed IC #20). 
% Left caudal M2 (in same IC as right caudal M2, artifacts removed IC # 4)
% Right medial parietal (to match artifacts removed IC #1, haven't found
% where it might be yet).
% More of left lateral M1(or S1?) (to add to artifacts removed IC #12)


% Mouse 1088
% Notes: 
% Right caudal M2 (to go with left caudal M2, artifacts removed IC 31)
% See if there's more of artifacts removed IC 4 (might be more of it in the
% medial direction, to match similar ICs in other mice). Also see if
% corresponding ICs on the left (13 & 26) have more area between them.
% Find more of IC 12 (cut off by blood vessels) 
% Find more of IC 38 (potentially cut off by gunk)
% Fnd more of IC 2 
% See if there's a matching on left for IC 25 (would let me confidently
% count those as retrosplenial & throw out 27 & 28, which might be gunk)
% See if there are corresponding ICs in other mice to 36 & 37

% Mouse 1096
% Notes:
% Right lateral M2, is part of IC 16 
% IC 25 is part of IC 24 (medial rostral M2s, I think), so should be
% combined with IC22
