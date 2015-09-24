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

IMPORT FGL libpivottypes
IMPORT FGL libpivot
GLOBALS "globals.4gl"

DEFINE globalPathTo4rp STRING
DEFINE globalControlBlock PivotControlBlock

TYPE AvailableMeasuresScreenRecord RECORD
    title STRING,
    isNumeric BOOLEAN
END RECORD
TYPE SortByScreenRecord RECORD
    title STRING,
    sortDescending BOOLEAN
END RECORD

#The dialog pops up if the 4rp contains exactly one pivot table and the dimension selection is a RTL expression
#The dialog maintains its state if called more than once for the same .4rp file
#The selection values defaultDimensionSelection and defaultMeasuresSelection are used to populate the respective lists
#in the dialog on the first display for a particular .4rp file. The values can be NULL or a comma separated lists of integers where 0 denotes the first item.
#In case of NULL the corresponding listbox will be empty. 
#The function returns false if the dialog was canceled or if an error ocurred and true in all other cases.
FUNCTION promptForPivotDialogIfAny(pathTo4rp,defaultDimensionsSelection,defaultMeasuresSelection)
    DEFINE pathTo4rp,defaultDimensionsSelection,defaultMeasuresSelection STRING,
    pivotTables DYNAMIC ARRAY OF pivotPivotTable,
    ok BOOLEAN,
    availableDimensions DYNAMIC ARRAY OF STRING,
    availableMeasures DYNAMIC ARRAY OF AvailableMeasuresScreenRecord,
    selectedDimensions DYNAMIC ARRAY OF STRING,
    selectedMeasures DYNAMIC ARRAY OF STRING,
    sortBy DYNAMIC ARRAY OF SortByScreenRecord,
    controlBlock PivotControlBlock,
    dnd ui.DragDrop,
    drag_source STRING,
    drop_index INT,
    retval INTEGER,
    tokenizer base.StringTokenizer,
    sortDescending BOOLEAN,
    s STRING,
    i,j,index INTEGER

    CALL pivot_load4rpAndGetPivotTables(pathTo4rp) RETURNING ok,pivotTables
    #CALL pivot_debugPivotTables(pivotTables)

    IF NOT ok OR pivotTables.getLength() != 1 THEN
        RETURN TRUE,controlBlock.*
    END IF

    IF pivotTables[1].hierarchiesDisplaySelection IS NULL THEN
        RETURN TRUE,controlBlock.*
    END IF

    IF NOT startsWithChar(pivotTables[1].hierarchiesDisplaySelection,"{") THEN
        RETURN TRUE,controlBlock.*
    END IF

#populate available dimensions and measures list
    FOR i=1 TO pivotTables[1].hierarchies.getLength()
        LET availableDimensions[i]=pivotTables[1].hierarchies[i].title
    END FOR
    FOR i=1 TO pivotTables[1].measures.getLength()
        LET availableMeasures[i].title=pivotTables[1].measures[i].title
        IF pivotTables[1].measures[i].isNumeric IS NULL THEN
            LET availableMeasures[i].isNumeric=FALSE
        ELSE
            LET availableMeasures[i].isNumeric=pivotTables[1].measures[i].isNumeric=="true"
        END IF
    END FOR

#are we called a second time for the same report?
    IF equals(globalPathTo4rp,pathTo4rp) THEN
#if yes then restore the dialog as left by the user
        LET controlBlock.*=globalControlBlock.*
    ELSE
#otherwise initialize the dialog

        LET controlBlock.title=NULL
        LET controlBlock.drawAs="Table"

        LET controlBlock.dimensionsDisplaySelection=defaultDimensionsSelection
        LET controlBlock.measuresDisplaySelection=defaultMeasuresSelection
        LET controlBlock.outputOrder=NULL
        LET controlBlock.topN=NULL
        LET controlBlock.displayFactRows=TRUE
        LET controlBlock.displayRecurringValues=FALSE
        LET controlBlock.computeAggregatesOnInnermostDimension=TRUE
        LET controlBlock.computeTotal=TRUE
        LET controlBlock.computeCount=FALSE
        LET controlBlock.computeDistinctCount=FALSE
        LET controlBlock.computeAverage=FALSE
        LET controlBlock.computeMinimum=FALSE
        LET controlBlock.computeMaximum=FALSE
    END IF
#restore from record
    IF NOT controlBlock.dimensionsDisplaySelection IS NULL THEN
        LET tokenizer=base.StringTokenizer.create(controlBlock.dimensionsDisplaySelection,",")
#copy all selected dimensions to the selected dimension array (not removing yet so that the indexes don't shift)
        WHILE tokenizer.hasMoreTokens()
            LET index=tokenizer.nextToken()
            IF index>=0 AND index<availableDimensions.getLength() THEN
                LET selectedDimensions[selectedDimensions.getLength()+1]=availableDimensions[index+1]
            END IF
        END WHILE
#removed them from the available dimension array
        FOR i=1 TO selectedDimensions.getLength()
            FOR j=1 TO availableDimensions.getLength()
                IF selectedDimensions[i]==availableDimensions[j] THEN
                    CALL availableDimensions.deleteElement(j)
                    EXIT FOR
                END IF
            END FOR
        END FOR
    END IF
#Now the measures
    IF NOT controlBlock.measuresDisplaySelection IS NULL THEN
        LET tokenizer=base.StringTokenizer.create(controlBlock.measuresDisplaySelection,",")
        WHILE tokenizer.hasMoreTokens()
            LET index=tokenizer.nextToken()
            IF index>=0 AND index<availableMeasures.getLength() THEN
                LET selectedMeasures[selectedMeasures.getLength()+1]=availableMeasures[index+1].title
            END IF
        END WHILE
#sorting
        IF NOT controlBlock.outputOrder IS NULL THEN
            LET tokenizer=base.StringTokenizer.create(controlBlock.outputOrder,",")
            WHILE tokenizer.hasMoreTokens()
                LET s=tokenizer.nextToken()
                LET index=s
                IF startsWithChar(s,"-") THEN
                    LET sortDescending=TRUE
                    LET index=0-index
                ELSE
                    LET sortDescending=FALSE
                END IF
                IF index>=0 AND index<availableMeasures.getLength() THEN
                    LET i=sortBy.getLength()+1
                    LET sortBy[i].title=availableMeasures[index+1].title
                    LET sortBy[i].sortDescending=sortDescending
                END IF
            END WHILE
        END IF
        FOR i=1 TO selectedMeasures.getLength()
            FOR j=1 TO availableMeasures.getLength()
                IF selectedMeasures[i]==availableMeasures[j].title THEN
                    CALL availableMeasures.deleteElement(j)
                    EXIT FOR
                END IF
            END FOR
        END FOR
        DISPLAY "DEBUG 0 dim=",controlBlock.dimensionsDisplaySelection,", mea=",controlBlock.measuresDisplaySelection
    END IF    


    
            
    TRY
        OPEN WINDOW pivotdialog
        WITH FORM "pivotdialog"
    CATCH
        RETURN FALSE,controlBlock.*
    END TRY
    
    DIALOG
    ATTRIBUTES (UNBUFFERED)
    

        INPUT BY NAME controlBlock.* ATTRIBUTES(WITHOUT DEFAULTS)
            AFTER FIELD topN
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE displayFactRows
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE displayRecurringValues
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeAggregatesOnInnermostDimension
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeTotal
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeCount
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeDistinctCount
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeAverage
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeMinimum
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON CHANGE computeMaximum
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
        END INPUT

        DISPLAY ARRAY availableDimensions TO availabledimensionsrecord.*
            ON DRAG_START(dnd)
                LET drag_source = "availabledimensionsrecord"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR drag_source != "selecteddimensionsrecord" THEN 
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                FOR i = selectedDimensions.getLength() TO 1 STEP -1
                    IF DIALOG.isRowSelected("selecteddimensionsrecord",i) THEN
                        CALL DIALOG.insertRow("availabledimensionsrecord", drop_index)
                        CALL DIALOG.setSelectionRange("availabledimensionsrecord", drop_index, drop_index, TRUE)
                        LET availableDimensions[drop_index] = selectedDimensions[i]
                        CALL DIALOG.deleteRow("selecteddimensionsrecord",i)
                    END IF
                END FOR
                CALL updateDrawAsCombobox(ui.ComboBox.forName("formonly.drawas"),selectedDimensions.getLength(),selectedMeasures.getLength())
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON ACTION doubleClick
        END DISPLAY
    
        DISPLAY ARRAY selectedDimensions TO selecteddimensionsrecord.*
            ON DRAG_START(dnd)
                LET drag_source = "selecteddimensionsrecord"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR ( drag_source != "availabledimensionsrecord" AND drag_source != "selecteddimensionsrecord") THEN
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                IF drag_source == "availabledimensionsrecord" THEN
                    FOR i = availableDimensions.getLength() TO 1 STEP -1
                        IF DIALOG.isRowSelected("availabledimensionsrecord",i) THEN
                            CALL DIALOG.insertRow("selecteddimensionsrecord",drop_index)
                            CALL DIALOG.setSelectionRange("selecteddimensionsrecord", drop_index, drop_index, TRUE)
                            LET selectedDimensions[drop_index] = availableDimensions[i]
                            CALL DIALOG.deleteRow("availabledimensionsrecord",i)
                        END IF
                    END FOR
                ELSE
                    FOR i = selectedDimensions.getLength() TO 1 STEP -1
                        IF DIALOG.isRowSelected("selecteddimensionsrecord",i) THEN
                            CALL DIALOG.insertRow("selecteddimensionsrecord",drop_index)
                            IF drop_index>=i THEN
                                LET selectedDimensions[drop_index] = selectedDimensions[i]
                                CALL DIALOG.deleteRow("selecteddimensionsrecord",i)
                                LET drop_index=drop_index-1
                            ELSE
                                LET selectedDimensions[drop_index] = selectedDimensions[i+1]
                                CALL DIALOG.deleteRow("selecteddimensionsrecord",i+1)
                            END IF
                        END IF
                    END FOR
                    CALL DIALOG.setSelectionRange("selecteddimensionsrecord", drop_index, drop_index, TRUE)
                END IF
                CALL updateDrawAsCombobox(ui.ComboBox.forName("formonly.drawas"),selectedDimensions.getLength(),selectedMeasures.getLength())
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON ACTION doubleClick
        END DISPLAY

        DISPLAY ARRAY availableMeasures TO availablemeasuresrecord.*
            ON DRAG_START(dnd)
                LET drag_source = "availablemeasuresrecord"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR drag_source != "selectedmeasuresrecord" THEN 
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                FOR i = selectedMeasures.getLength() TO 1 STEP -1
                    IF DIALOG.isRowSelected("selectedmeasuresrecord",i) THEN
                        CALL DIALOG.insertRow("availablemeasuresrecord", drop_index)
                        CALL DIALOG.setSelectionRange("availablemeasuresrecord", drop_index, drop_index, TRUE)
                        LET availableMeasures[drop_index].title = selectedMeasures[i]
                        CALL DIALOG.deleteRow("selectedmeasuresrecord",i)
                    END IF
                END FOR
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON ACTION doubleClick
        END DISPLAY

        DISPLAY ARRAY selectedMeasures TO selectedmeasuresrecord.*
            ON DRAG_START(dnd)
                LET drag_source = "selectedmeasuresrecord"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR (drag_source != "availablemeasuresrecord" AND drag_source != "selectedmeasuresrecord" AND drag_source != "sortbyrecord" ) THEN
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                IF drag_source=="availablemeasuresrecord" THEN
                    FOR i = availableMeasures.getLength() TO 1 STEP -1
                        IF DIALOG.isRowSelected("availablemeasuresrecord",i) THEN
                            CALL DIALOG.insertRow("selectedmeasuresrecord",drop_index)
                            CALL DIALOG.setSelectionRange("selectedmeasuresrecord", drop_index, drop_index, TRUE)
                            LET selectedMeasures[drop_index] = availableMeasures[i].title
                            CALL DIALOG.deleteRow("availablemeasuresrecord",i)
                        END IF
                    END FOR
                ELSE
                    IF drag_source=="selectedmeasuresrecord" THEN
                        FOR i = selectedMeasures.getLength() TO 1 STEP -1
                            IF DIALOG.isRowSelected("selectedmeasuresrecord",i) THEN
                                CALL DIALOG.insertRow("selectedmeasuresrecord",drop_index)
                                IF drop_index>=i THEN
                                    LET selectedMeasures[drop_index] = selectedMeasures[i]
                                    CALL DIALOG.deleteRow("selectedmeasuresrecord",i)
                                    LET drop_index=drop_index-1
                                ELSE
                                    LET selectedMeasures[drop_index] = selectedMeasures[i+1]
                                    CALL DIALOG.deleteRow("selectedmeasuresrecord",i+1)
                                END IF
                            END IF
                        END FOR
                        CALL DIALOG.setSelectionRange("selectedmeasuresrecord", drop_index, drop_index, TRUE)
                    ELSE
                        FOR i = sortBy.getLength() TO 1 STEP -1
                            IF DIALOG.isRowSelected("sortbyrecord",i) THEN
                                CALL DIALOG.deleteRow("sortbyrecord",i)
                            END IF
                        END FOR
                   END IF
               END IF
               CALL updateDrawAsCombobox(ui.ComboBox.forName("formonly.drawas"),selectedDimensions.getLength(),selectedMeasures.getLength())
               LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON ACTION doubleClick
        END DISPLAY

        DISPLAY ARRAY sortBy TO sortbyrecord.*
            ON UPDATE
                INPUT sortBy[arr_curr()].* WITHOUT DEFAULTS FROM sortbyrecord[scr_line()].*
                    AFTER INPUT
                        LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
                END INPUT
            ON DRAG_START(dnd)
                LET drag_source = "sortbyrecord"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR ( drag_source != "selectedmeasuresrecord" AND drag_source != "sortbyrecord" ) THEN 
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                IF drag_source=="selectedmeasuresrecord" THEN
                    FOR i = selectedMeasures.getLength() TO 1 STEP -1
                        IF DIALOG.isRowSelected("selectedmeasuresrecord",i) THEN
                            CALL DIALOG.insertRow("sortbyrecord", drop_index)
                            CALL DIALOG.setSelectionRange("sortbyrecord", drop_index, drop_index, TRUE)
                            LET sortBy[drop_index].title = selectedMeasures[i]
                            LET sortBy[drop_index].sortDescending = FALSE
                        END IF
                    END FOR
                ELSE
                    FOR i = sortBy.getLength() TO 1 STEP -1
                        IF DIALOG.isRowSelected("sortbyrecord",i) THEN
                            CALL DIALOG.insertRow("sortbyrecord",drop_index)
                            IF drop_index>=i THEN
                                LET sortBy[drop_index].* = sortBy[i].*
                                CALL DIALOG.deleteRow("sortbyrecord",i)
                                LET drop_index=drop_index-1
                            ELSE
                                LET sortBy[drop_index].* = sortBy[i+1].*
                                CALL DIALOG.deleteRow("sortbyrecord",i+1)
                            END IF
                        END IF
                    END FOR
                    CALL DIALOG.setSelectionRange("sortbyrecord", drop_index, drop_index, TRUE)
                END IF
                CALL updateDrawAsCombobox(ui.ComboBox.forName("formonly.drawas"),selectedDimensions.getLength(),selectedMeasures.getLength())
                LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            ON ACTION doubleClick
        END DISPLAY

        BEFORE DIALOG -- Activate multi-selection on both arrays
            CALL DIALOG.setSelectionMode("availabledimensionsrecord",1)
            CALL DIALOG.setSelectionMode("selecteddimensionsrecord",1)
            CALL DIALOG.setSelectionMode("availablemeasuresrecord",1)
            CALL DIALOG.setSelectionMode("selectedmeasuresrecord",1)
            CALL DIALOG.setSelectionMode("sortbyrecord",1)
            CALL updateDrawAsCombobox(ui.ComboBox.forName("formonly.drawas"),selectedDimensions.getLength(),selectedMeasures.getLength())
            LET controlBlock.title=composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock.*)
            
        ON ACTION accept
            LET retval = TRUE
            EXIT DIALOG
        ON ACTION cancel
            LET retval = FALSE
            EXIT DIALOG

    END DIALOG

    WHENEVER ERROR CONTINUE
        CLOSE WINDOW pivotdialog
    WHENEVER ERROR STOP

    LET controlBlock.dimensionsDisplaySelection=emptyString()
    FOR i=1 TO selectedDimensions.getLength()
        FOR j=1 TO pivotTables[1].hierarchies.getLength()
            IF selectedDimensions[i]==pivotTables[1].hierarchies[j].title THEN
                IF i>1 THEN
                    LET controlBlock.dimensionsDisplaySelection=controlBlock.dimensionsDisplaySelection,","
                END IF
                LET controlBlock.dimensionsDisplaySelection=controlBlock.dimensionsDisplaySelection||(j-1)
                EXIT FOR
            END IF
        END FOR
    END FOR
    LET controlBlock.measuresDisplaySelection=emptyString()
    FOR i=1 TO selectedMeasures.getLength()
        FOR j=1 TO pivotTables[1].measures.getLength()
            IF selectedMeasures[i]==pivotTables[1].measures[j].title THEN
                IF i>1 THEN
                    LET controlBlock.measuresDisplaySelection=controlBlock.measuresDisplaySelection,","
                END IF
                LET controlBlock.measuresDisplaySelection=controlBlock.measuresDisplaySelection||(j-1)
                EXIT FOR
            END IF
        END FOR
    END FOR
    LET controlBlock.outputOrder=emptyString()
    FOR i=1 TO sortBy.getLength()
        FOR j=1 TO pivotTables[1].measures.getLength()
            IF sortBy[i].title==pivotTables[1].measures[j].title THEN
                IF i>1 THEN
                    LET controlBlock.outputOrder=controlBlock.outputOrder,","
                END IF
                IF sortBy[i].sortDescending THEN
                    LET controlBlock.outputOrder=controlBlock.outputOrder,"-"
                END IF
                LET controlBlock.outputOrder=controlBlock.outputOrder||(j-1)
                EXIT FOR
            END IF
        END FOR
    END FOR

    LET globalPathTo4rp=pathTo4rp
    LET globalControlBlock.*=controlBlock.*
    IF controlBlock.topN IS NULL THEN
        LET controlBlock.topN=-1
    END IF
    RETURN retval,controlBlock.*
    
END FUNCTION

FUNCTION updateDrawAsCombobox(cb,numberOfDimensions,numberOfMeasures)
    DEFINE cb ui.ComboBox,
           numberOfDimensions INTEGER,
           numberOfMeasures INTEGER
    CALL cb.clear()
    IF numberOfDimensions>=2 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Area","Area");
    END IF
    IF numberOfDimensions>=1 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Bar","Bar");
        CALL cb.addItem("Bar3D","Bar3D");
    END IF
    IF numberOfDimensions>=2 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Line","Line");
        CALL cb.addItem("Line3D","Line3D");
    END IF
    IF numberOfDimensions>=1 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Pie","Pie");
        CALL cb.addItem("Pie3D","Pie3D");
    END IF
    IF numberOfMeasures>=2 THEN
        CALL cb.addItem("Polar","Polar");
    END IF
    IF numberOfDimensions>=1 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Ring","Ring");
    END IF
    IF numberOfMeasures>=2 THEN
        CALL cb.addItem("Scatter","Scatter");
    END IF
    IF numberOfDimensions>=2 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("StackedArea","StackedArea");
        CALL cb.addItem("StackedBar","StackedBar");
    END IF
    IF numberOfMeasures>=2 THEN
        CALL cb.addItem("Step","Step");
        CALL cb.addItem("StepArea","StepArea");
    END IF
    CALL cb.addItem("Table","Table");
    IF numberOfMeasures>=2 THEN
        CALL cb.addItem("TimeSeries","TimeSeries");
    END IF
    IF numberOfDimensions>=2 AND numberOfMeasures>=1 THEN
        CALL cb.addItem("Waterfall","Waterfall");
    END IF
    IF numberOfMeasures>=2 THEN
        CALL cb.addItem("XYArea","XYArea");
        CALL cb.addItem("XYLine","XYLine");
        CALL cb.addItem("XYStackedArea","XYStackedArea");
    END IF
END FUNCTION
FUNCTION composeTitle(selectedDimensions,selectedMeasures,sortBy,controlBlock)
    DEFINE selectedDimensions DYNAMIC ARRAY OF STRING,
    selectedMeasures DYNAMIC ARRAY OF STRING,
    sortBy DYNAMIC ARRAY OF SortByScreenRecord,
    sortByItem SortByScreenRecord,
    controlBlock PivotControlBlock,
    title STRING,
    i INTEGER,
    aggregateText STRING

    LET title=emptyString();

    IF controlBlock.computeTotal THEN
        LET aggregateText="Total "
    ELSE
        IF controlBlock.computeCount THEN
            LET aggregateText="Count "
        ELSE
            IF controlBlock.computeDistinctCount THEN
                LET aggregateText=" Distinct count "
            ELSE
                IF controlBlock.computeAverage THEN
                    LET aggregateText="Average "
                ELSE
                    IF controlBlock.computeMinimum THEN
                        LET aggregateText="Miniumum "
                    ELSE
                        IF controlBlock.computeMaximum THEN
                            LET aggregateText="Maximum "
                        ELSE
                            LET aggregateText=emptyString()
                        END IF
                    END IF
                END IF
            END IF
        END IF
    END IF

    FOR i=1 TO selectedMeasures.getLength()
        LET title=title,getSeparator(i,selectedMeasures.getLength()),aggregateText,selectedMeasures[i]
    END FOR
    IF selectedDimensions.getLength()>0 THEN
        LET title=title," grouped by "
        FOR i=1 TO selectedDimensions.getLength()
            LET title=title,getSeparator(i,selectedDimensions.getLength()),selectedDimensions[i]
        END FOR
    END IF
    IF sortBy.getLength()>0 THEN
        LET title=title," sorted by "
        FOR i=1 TO sortBy.getLength()
            LET sortByItem.*=sortBy[i].*
            LET title=title,getSeparator(i,sortBy.getLength()),sortByItem.title
            IF sortByItem.sortDescending THEN
                LET title=title," descending"
            END IF
        END FOR
        IF NOT controlBlock.topN IS NULL THEN
            LET title=title," showing top "||controlBlock.topN
        END IF
    END IF
    RETURN title
END FUNCTION
FUNCTION getSeparator(i,len)
    DEFINE i,len INTEGER
    IF i==1 THEN 
        RETURN emptyString()
    END IF
    IF i==len THEN
        RETURN " and "
    END IF
    RETURN ", "
END FUNCTION
FUNCTION emptyString()
    DEFINE s STRING
    LET s=" "
    RETURN s.trim()
END FUNCTION
FUNCTION equals(s1,s2)
    DEFINE s1,s2 STRING
    IF s1 IS NULL THEN
        RETURN s2 IS NULL
    ELSE
        IF s2 IS NULL THEN
            RETURN FALSE
        ELSE
            RETURN s1==s2
        END IF
    END IF
END FUNCTION
FUNCTION startsWithChar(s,c)
    DEFINE s,c STRING
    IF s IS NULL THEN
        RETURN FALSE
    END IF
    IF c IS NULL THEN
        RETURN FALSE
    END IF
    IF c.getLength()<1 THEN
        RETURN FALSE
    END IF
    IF s.getLength()<1 THEN
        RETURN FALSE
    END IF
    RETURN s.getCharAt(1)==c.getCharAt(1)
END FUNCTION
