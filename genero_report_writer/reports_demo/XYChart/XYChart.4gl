# FOURJS_START_COPYRIGHT(U,2003)
# Property of Four Js*
# (c) Copyright Four Js 2003, 2014. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples are
# accurate and suitable for your purposes.
# Their inclusion is purely for information purposes only.
# FOURJS_END_COPYRIGHT
IMPORT util

TYPE XYItemType RECORD
    series STRING,
    x FLOAT,
    y FLOAT
END RECORD

MAIN

    DEFINE handler om.SaxDocumentHandler
    DEFINE item XYItemType
    DEFINE i INTEGER

    LET handler = configureOutput()

    START REPORT xyReport TO XML HANDLER handler
    LET item.series = "sin(x)"
    FOR i = 1 TO 360 STEP 6
        LET item.x = i/180*util.Math.pi()
        LET item.y = util.Math.sin(item.x)
        OUTPUT TO REPORT xyReport(item.*)
    END FOR
    LET item.series = "cos(x)"
    FOR i = 1 TO 360 STEP 6
        LET item.x = i/180*util.Math.pi()
        LET item.y = util.Math.cos(item.x)
        OUTPUT TO REPORT xyReport(item.*)
    END FOR
    LET item.series = "sin(3*x+PI/4)/3"
    FOR i = 1 TO 360 STEP 6
        LET item.x = i/180*util.Math.pi()
        LET item.y = util.Math.sin(3*item.x+util.Math.pi()/4)/3
        OUTPUT TO REPORT xyReport(item.*)
    END FOR
    FINISH REPORT xyReport

END MAIN

FUNCTION configureOutput()
 
    IF NOT fgl_report_loadCurrentSettings("XYChart.4rp") THEN
        EXIT PROGRAM
    END IF
    CALL fgl_report_selectDevice("PDF")
    CALL fgl_report_selectPreview(true)
    RETURN fgl_report_commitCurrentSettings()
END FUNCTION

REPORT xyReport( item )
    DEFINE item XYItemType

    FORMAT

    ON EVERY ROW
        PRINTX item.*
END REPORT
