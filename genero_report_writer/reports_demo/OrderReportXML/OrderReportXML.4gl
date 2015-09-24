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
MAIN
    IF NOT fgl_report_loadCurrentSettings("Table.4rp") THEN
        EXIT PROGRAM
    END IF
    -- display as svg
    CALL fgl_report_selectDevice(getPreviewDevice())
    CALL fgl_report_selectPreview(TRUE)
    
    IF NOT  fgl_report_runFromXML("OrderData.xml") THEN
        DISPLAY "RUN FAILED"
        EXIT PROGRAM
    END IF
END MAIN
FUNCTION getPreviewDevice()
    DEFINE fename String
    CALL ui.interface.frontcall("standard", "feinfo", ["fename"],[fename])
    RETURN iif(fename=="Genero Desktop Client","SVG","PDF")     
END FUNCTION
