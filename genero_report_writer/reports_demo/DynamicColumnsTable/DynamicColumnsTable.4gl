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
IMPORT os
CONSTANT START_DIRECTORY=".."

MAIN
    DEFINE saxHandler om.SaxDocumentHandler
    IF NOT fgl_report_loadCurrentSettings("DynamicColumnsTable.4rp") THEN
        EXIT PROGRAM
    END IF
    CALL fgl_report_selectDevice(getPreviewDevice())
    LET saxHandler=fgl_report_commitCurrentSettings()
    START REPORT DynamicColumnTableReport TO XML HANDLER saxHandler
    OUTPUT TO REPORT DynamicColumnTableReport(1)
    FINISH REPORT DynamicColumnTableReport
END MAIN
REPORT DynamicColumnTableReport(k)
     DEFINE k INTEGER,
    path, directory, suffix, fileName STRING,
    suffixes DYNAMIC ARRAY OF STRING,
    i,handle INTEGER

    ORDER EXTERNAL BY k
FORMAT

BEFORE GROUP OF k
#Collect suffixes in a sorted set
    LET path=getNextFile(START_DIRECTORY)
    WHILE path IS NOT NULL
        IF os.Path.isFile(path) THEN
            LET suffix=getSuffix(path)
            IF suffix IS NOT NULL THEN
                CALL putSuffix(suffixes,suffix)
            END IF
        END IF     
        LET path=getNextFile(path)
    END WHILE
#Ship the suffixes for the purpose of creating COLDEFS
    FOR i=1 TO suffixes.getLength()
        LET suffix=suffixes[i]
        PRINT suffix
    END FOR
#Ship the suffixes once more the purpose of printing the titles
    FOR i=1 TO suffixes.getLength()
        LET suffix=suffixes[i]
        PRINT suffix
    END FOR
    LET directory=getNextFile(START_DIRECTORY)
#Loop over all directories and ship the direcory name (We create a row for each)
    WHILE NOT directory IS NULL
        IF os.Path.isDirectory(directory) THEN
            PRINT directory
#Ship the suffixes for the purpose of creating cells
            FOR i=1 TO suffixes.getLength()
                LET suffix=suffixes[i]
                PRINT suffix
                LET handle=os.Path.dirOpen(directory)
                LET path=os.Path.dirnext(handle)
#Ship all files in the current directory that have the current suffix
                WHILE path IS NOT NULL
                    LET suffix=getSuffix(path)
                    IF suffix==suffixes[i] THEN
                        LET fileName=path.substring(1,path.getLength()-suffix.getLength())
                        PRINT fileName #basename with neither directory nor suffix
                    END IF  
                    LET path=os.Path.dirnext(handle)
                END WHILE
                CALL os.Path.dirClose(handle)
            END FOR
        END IF  
        LET directory=getNextFile(directory)
    END WHILE

END REPORT
#Stateless, flat directory tree iterator. This is ridiculously slow.    
FUNCTION getNextFile(path)
DEFINE path, child, nextSibling, parent STRING

    LET child=getFirstChild(path)
    IF child IS NOT NULL THEN
       RETURN child
    END IF
    LET nextSibling=getNextSibling(path)
    IF nextSibling IS NOT NULL THEN
       RETURN nextSibling
    END IF
    LET parent=getParent(path)
    WHILE parent IS NOT NULL
        LET nextSibling=getNextSibling(parent)
        IF nextSibling IS NOT NULL THEN
            RETURN nextSibling
        END IF
        LET parent=getParent(parent)
    END WHILE
    RETURN NULL
END FUNCTION
FUNCTION getFirstChild(parent)
DEFINE parent, child STRING,
       handle INTEGER
   
    IF os.Path.isDirectory(parent) THEN
        LET handle=os.Path.dirOpen(parent)
        IF handle!=0 THEN
            LET child=os.Path.dirnext(handle)
            WHILE child=="." OR child==".."
                LET child=os.Path.dirnext(handle)
            END WHILE
            CALL os.Path.dirClose(handle)
            RETURN parent||"/"||child
        END IF
    END IF
    RETURN NULL
END FUNCTION
FUNCTION getParent(child)
DEFINE child, parent STRING

    LET parent=os.Path.dirname(child)
    IF parent IS NULL THEN
        RETURN NULL
    END IF
    IF parent == child THEN
        RETURN NULL
    END IF
    RETURN parent
END FUNCTION
FUNCTION getNextSibling(sibling)
DEFINE sibling, parent, fileName, s STRING,
       handle INTEGER

    LET parent=getParent(sibling)
    IF parent IS NULL THEN
        RETURN NULL
    END IF
    LET fileName=sibling.substring(parent.getLength()+2,sibling.getLength())
    LET handle=os.Path.dirOpen(parent)
    IF handle!=0 THEN
    WHILE TRUE
        LET s=os.Path.dirnext(handle)
        IF s IS NULL THEN
            EXIT WHILE
        END IF
        IF fileName==s THEN
            LET s=os.Path.dirnext(handle)
            WHILE s=="." OR s==".."
                LET s=os.Path.dirnext(handle)
            END WHILE
            CALL os.Path.dirClose(handle)
            RETURN parent||"/"||s
        END IF
    END WHILE
    CALL os.Path.dirClose(handle)
    RETURN NULL
    END IF
END FUNCTION
FUNCTION putSuffix(suffixes,suffix)
    DEFINE suffixes DYNAMIC ARRAY OF STRING,
    suffix STRING,
    i INTEGER

    FOR i=1 TO suffixes.getLength()
        IF suffixes[i]>=suffix THEN
             IF suffix==suffixes[i] THEN
                 RETURN
             END IF
             CALL suffixes.insertElement(i)
             LET suffixes[i]=suffix
             RETURN
        END IF
    END FOR
    LET suffixes[i]=suffix
END FUNCTION
FUNCTION getSuffix(s)
    DEFINE s STRING,
    i,len INTEGER
    LET len=s.getLength()
    FOR i=len TO 2 STEP -1
        IF s.getCharAt(i)=="." THEN
            RETURN s.subString(i,len)
        ELSE
            IF s.getCharAt(i)=="/" THEN
                RETURN NULL
            END IF
        END IF
    END FOR
    RETURN NULL    
END FUNCTION  
FUNCTION getPreviewDevice()
    DEFINE fename String
    CALL ui.interface.frontcall("standard", "feinfo", ["fename"],[fename])
    RETURN iif(fename=="Genero Desktop Client","SVG","PDF")     
END FUNCTION
