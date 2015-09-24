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

FUNCTION promptForFieldSelectionDialog(leftList,rightList)
    DEFINE leftList DYNAMIC ARRAY OF STRING,
            rightList DYNAMIC ARRAY OF STRING,
            dnd ui.DragDrop,
            drag_source STRING,
            drop_index INT,
            retval INTEGER

    DEFINE i INTEGER
            

    WHENEVER ERROR CONTINUE
        OPEN WINDOW fieldselectiondialog
        WITH FORM "fieldselectiondialog"
    WHENEVER ERROR STOP
    IF STATUS THEN
        RETURN FALSE
    END IF
    
    DIALOG
    ATTRIBUTES (UNBUFFERED)
    
        DISPLAY ARRAY leftList TO scr_left_content.*
            ON DRAG_START(dnd)
                LET drag_source = "scr_left_content"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR drag_source != "scr_right_content" THEN 
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                FOR i = rightList.getLength() TO 1 STEP -1
                    IF DIALOG.isRowSelected("scr_right_content",i) THEN
                        CALL DIALOG.insertRow("scr_left_content", drop_index)
                        CALL DIALOG.setSelectionRange("scr_left_content", drop_index, drop_index, TRUE)
                        LET leftList[drop_index] = rightList[i]
                        CALL DIALOG.deleteRow("scr_right_content",i)
                    END IF
                END FOR
                CALL action_control(DIALOG)
        END DISPLAY
    
        DISPLAY ARRAY rightList TO scr_right_content.*
            ON DRAG_START(dnd)
                LET drag_source = "scr_right_content"
            ON DRAG_FINISHED(dnd)
                INITIALIZE drag_source TO NULL
            ON DRAG_ENTER(dnd)
                IF drag_source IS NULL OR drag_source != "scr_left_content" THEN
                    CALL dnd.setOperation(NULL)
                END IF
            ON DROP(dnd)
                LET drop_index = dnd.getLocationRow()
                FOR i = leftList.getLength() TO 1 STEP -1
                    IF DIALOG.isRowSelected("scr_left_content",i) THEN
                        CALL DIALOG.insertRow("scr_right_content",drop_index)
                        CALL DIALOG.setSelectionRange("scr_right_content", drop_index, drop_index, TRUE)
                        LET rightList[drop_index] = leftList[i]
                        CALL DIALOG.deleteRow("scr_left_content",i)
                    END IF
                END FOR
                CALL action_control(DIALOG)
        END DISPLAY

        BEFORE DIALOG -- Activate multi-selection on both arrays
            CALL DIALOG.setSelectionMode("scr_left_content",1)
            CALL DIALOG.setSelectionMode("scr_right_content",1)
            CALL action_control(DIALOG)

        ON ACTION move_right
            FOR i = DIALOG.getArrayLength("scr_left_content") TO 1 STEP -1
                IF DIALOG.isRowSelected("scr_left_content", i) THEN
                    CALL DIALOG.appendRow("scr_right_content")
                    LET rightList[DIALOG.getArrayLength("scr_right_content")] = leftList[i]
                    CALL DIALOG.deleteRow("scr_left_content",i)
                END IF
            END FOR
            CALL action_control(DIALOG)

        ON ACTION move_left
            FOR i = DIALOG.getArrayLength("scr_right_content") TO 1 STEP -1
                IF DIALOG.isRowSelected("scr_right_content", i) THEN
                    CALL DIALOG.appendRow("scr_left_content")
                    LET leftList[DIALOG.getArrayLength("scr_left_content")] = rightList[i]
                    CALL DIALOG.deleteRow("scr_right_content",i)
                END IF
            END FOR
            CALL action_control(DIALOG)
            
        ON ACTION ACCEPT
            LET retval = TRUE
            EXIT DIALOG
        ON ACTION CANCEL
            LET retval = FALSE
            EXIT DIALOG

    END DIALOG

    WHENEVER ERROR CONTINUE
        CLOSE WINDOW fieldselectiondialog
    WHENEVER ERROR STOP

    RETURN retval
    
END FUNCTION


FUNCTION action_control(d)
    DEFINE d ui.Dialog
    CALL d.setActionActive("move_right", d.getArrayLength("scr_left_content")>0)
    CALL d.setActionActive("move_left", d.getArrayLength("scr_right_content")>0)
END FUNCTION
