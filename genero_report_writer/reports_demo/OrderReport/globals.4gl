# FOURJS_START_COPYRIGHT(U,2011)
# Property of Four Js*
# (c) Copyright Four Js 2011, 2014. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples are
# accurate and suitable for your purposes.
# Their inclusion is purely for information purposes only.
# FOURJS_END_COPYRIGHT

GLOBALS

TYPE PivotControlBlock RECORD
    title STRING,
    drawAs STRING,
    dimensionsDisplaySelection STRING,
    measuresDisplaySelection STRING,
    outputOrder STRING,
    topN INTEGER,
    displayFactRows BOOLEAN,
    displayRecurringValues BOOLEAN,
    computeAggregatesOnInnermostDimension BOOLEAN,
    computeTotal BOOLEAN,
    computeCount BOOLEAN,
    computeDistinctCount BOOLEAN,
    computeAverage BOOLEAN,
    computeMinimum BOOLEAN,
    computeMaximum BOOLEAN
END RECORD

END GLOBALS
