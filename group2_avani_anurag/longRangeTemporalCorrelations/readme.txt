Essentially, I realised that we cannot do LRTC analysis on the segmented data that was provided. This is because we need continuous data for each condition.
We have 1 second trials for each condition instead, they can't be stiched together for obvious reasons. Moreover, the noise removal and other pre-processing
methodologies are entirely different for long form data. We cannot get meaningful data if we apply the LRTC DFA method within the 1-second trial intervals.

Instead, we can calcuate short-range temporal dynamics. See folder for short ranged temporal dynamics. 