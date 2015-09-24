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
    DEFINE saxHandler om.SaxDocumentHandler,
    monthIndex INTEGER
    IF NOT fgl_report_loadCurrentSettings("Calendar.4rp") THEN
        EXIT PROGRAM
    END IF
    CALL fgl_report_selectDevice(getPreviewDevice())
    LET saxHandler = fgl_report_commitCurrentSettings()
    START REPORT calendarReport TO XML HANDLER saxHandler
    FOR monthIndex=1 TO 12
        OUTPUT TO REPORT calendarReport("Fred Bloggs", "Mon 08:00 - 16:00 Tue 08:00 - 16:00 Wed 08:00 - 16:00 Thu 08:00 - 16:00 Fri 08:00 - 16:00",2013,monthIndex)
    END FOR
    FINISH REPORT calendarReport
END MAIN
REPORT calendarReport(employeeName,workingHoursText,yearValue,monthValue)
DEFINE employeeName, workingHoursText STRING,
       yearValue, monthValue, i INTEGER,
       monDate, tueDate, wedDate, thuDate, friDate, satDate, sunDate DATE,
       monValue, tueValue, wedValue, thuValue, friValue, satValue, sunValue INTEGER,
       monState, tueState, wedState, thuState, friState, satState, sunState INTEGER,
       monDim, tueDim, wedDim, thuDim, friDim, satDim, sunDim BOOLEAN
FORMAT
    ON EVERY ROW
    PRINT employeeName, workingHoursText, yearValue, monthValue
    FOR i=1 TO 6
        LET monDate=getCalendarCellDate(yearValue,monthValue,i,1)
        LET tueDate=monDate+1
        LET wedDate=tueDate+1
        LET thuDate=wedDate+1
        LET friDate=thuDate+1
        LET satDate=friDate+1
        LET sunDate=satDate+1
        LET monValue=day(monDate)
        LET tueValue=day(tueDate)
        LET wedValue=day(wedDate)
        LET thuValue=day(thuDate)
        LET friValue=day(friDate)
        LET satValue=day(satDate)
        LET sunValue=day(sunDate)
        LET monState=getCalendarCellState(monDate)
        LET tueState=getCalendarCellState(tueDate)
        LET wedState=getCalendarCellState(wedDate)
        LET thuState=getCalendarCellState(thuDate)
        LET friState=getCalendarCellState(friDate)
        LET satState=4
        LET sunState=4 
        LET monDim=month(monDate)!=monthValue
        LET tueDim=month(tueDate)!=monthValue
        LET wedDim=month(wedDate)!=monthValue
        LET thuDim=month(thuDate)!=monthValue
        LET friDim=month(friDate)!=monthValue
        LET satDim=month(satDate)!=monthValue
        LET sunDim=month(sunDate)!=monthValue

        PRINT monValue, tueValue, wedValue, thuValue, friValue, satValue, sunValue, 
              monState, tueState, wedState, thuState, friState, satState, sunState,
              monDim, tueDim, wedDim, thuDim, friDim, satDim, sunDim
    END FOR
END REPORT
#Computes the date of a cell
#rowIndex: A value between 1 and 6
#columnIndex: A value between 1 (Mon) and 7 (Sun)
FUNCTION getCalendarCellDate(yearValue,monthValue,rowIndex,columnIndex)
    DEFINE yearValue, monthValue, rowIndex, columnIndex, shiftValue INTEGER,
        dt DATE
        
    LET dt=MDY(monthValue,1,yearValue)
    LET shiftValue=computeDayOfWeek(dt)-1
    LET dt=dt-shiftValue+(rowIndex-1)*7+columnIndex-1
    RETURN dt
END FUNCTION

#Returns 1 for Monday tru 7 for Sunday
FUNCTION computeDayOfWeek(d)
    DEFINE d DATE
    
    RETURN ((d+6) MOD 7)+1
END FUNCTION
#Retrieves the state for a given date. Values are 0=regular day, 1=Annual Leave, 2=Not Available to Work, 3=Staff Training
FUNCTION getCalendarCellState(dateValue)
    DEFINE dateValue DATE,
        monthValue, dayValue INTEGER

    LET monthValue=month(dateValue)
    LET dayValue=day(dateValue)
    CASE monthValue
         WHEN 1
             IF dayValue >= 10 AND dayValue <= 18 THEN
                 RETURN 2
             END IF
         WHEN 2
             IF dayValue>=11 AND dayValue<=15 THEN
                 RETURN 1
             END IF
         WHEN 4
             IF dayValue>=17 AND dayValue<=18 THEN
                 RETURN 2
             END IF
         WHEN 5
             IF dayValue>=21 AND dayValue<=25 THEN
                 RETURN 2
             END IF
         WHEN 7
             IF dayValue>=10 AND dayValue<=12 THEN
                 RETURN 2
             END IF
         WHEN 8
             IF dayValue>20 AND dayValue<=31 THEN
                 RETURN 1
             END IF
         WHEN 9
             IF dayValue>=26 AND dayValue<=27 THEN
                 RETURN 3
             END IF
         WHEN 11
             IF dayValue>=13 AND dayValue<=14 THEN
                 RETURN 2
             END IF
        END CASE
        RETURN 0
END FUNCTION
FUNCTION getPreviewDevice()
    DEFINE fename String
    CALL ui.interface.frontcall("standard", "feinfo", ["fename"],[fename])
    RETURN iif(fename=="Genero Desktop Client","SVG","PDF")     
END FUNCTION
