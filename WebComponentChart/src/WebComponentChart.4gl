-- FOURJS_START_COPYRIGHT(U,2010)
-- Property of Four Js*
-- (c) Copyright Four Js 2010, 2014. All Rights Reserved.
-- * Trademark of Four Js Development Tools Europe Ltd
--   in the United States and elsewhere
-- 
-- Four Js and its suppliers do not warrant or guarantee that these samples are
-- accurate and suitable for your purposes.
-- Their inclusion is purely for information purposes only.
-- FOURJS_END_COPYRIGHT


PRIVATE DEFINE data DYNAMIC ARRAY OF INTEGER


# =============================================================================
# MAIN
# =============================================================================
MAIN
    DEFINE currvalue INT
    DEFINE wc STRING
    DEFINE ddIdx INT
    DEFINE propValue STRING

    CLOSE WINDOW SCREEN
    OPTIONS INPUT WRAP
    OPEN WINDOW w
        WITH FORM "WebComponentChart"
        ATTRIBUTES(TEXT="webComponentChart Demo")

    CALL initializeChartData()
    LET ddIdx = 1
    LET wc = "January"

    LET currvalue = data[ddIdx]
    DISPLAY wc TO currmonth

    DIALOG ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)

        INPUT BY NAME
            currvalue,
            wc
            ATTRIBUTES(WITHOUT DEFAULTS=TRUE)

            ON ACTION drilldown INFIELD wc
                LET ddIdx = chartDataStructureGetDrilledDown(wc)
                LET currvalue = data[ddIdx]
                DISPLAY wc TO currmonth

            ON CHANGE currvalue
                CALL setArrayPropertyElement("values", ddIdx, currvalue)
                LET data[ddIdx] = currvalue
        END INPUT

        ON ACTION Column3D
            CALL setProperty("type", "FColumn3D.swf")
        ON ACTION Column2D
            CALL setProperty("type", "FColumn2D.swf")
        ON ACTION Pie3D
            CALL setProperty("type", "FPie3D.swf")
        ON ACTION Pie2D
            CALL setProperty("type", "FPie2D.swf")
        ON ACTION Doughnut3D
            CALL setProperty("type", "FDoughnut3D.swf")
        ON ACTION Doughnut2D
            CALL setProperty("type", "FDoughnut2D.swf")
        ON ACTION RGraphPie
            CALL setProperty("type", "RPie")
        ON ACTION RGraphBar
            CALL setProperty("type", "RBar")
        ON ACTION JSChartPie
            CALL setProperty("type", "JPie")
        ON ACTION JSChartBar
            CALL setProperty("type", "JBar")

        ON ACTION changeCaption
            PROMPT "Change caption to..." FOR propValue ATTRIBUTES(WITHOUT DEFAULTS)
                ON ACTION accept
                    CALL setProperty("caption", propValue)
            END PROMPT

        ON ACTION close
            EXIT DIALOG
    END DIALOG

END MAIN


# =============================================================================
# initializeChartData
# =============================================================================
FUNCTION initializeChartData()
    DEFINE i INTEGER

    LET data[01]="17400"
    LET data[02]="19800"
    LET data[03]="21800"
    LET data[04]="23800"
    LET data[05]="29600"
    LET data[06]="27600"
    LET data[07]="31800"
    LET data[08]="39700"
    LET data[09]="37800"
    LET data[10]="21900"
    LET data[11]="32900"
    LET data[12]="39800"

    FOR i = 1 TO 12
      CALL setArrayPropertyElement("values", i, data[i])
    END FOR
END FUNCTION


# =============================================================================
# chartDataStructureToString
# =============================================================================
FUNCTION chartDataStructureGetDrilledDown(msg)
  DEFINE msg STRING
  DEFINE token STRING
  DEFINE st base.StringTokenizer

  DISPLAY msg

  LET st = base.StringTokenizer.create(msg, "\n")
  LET token = st.nextToken()

  CASE token
        WHEN "January"   RETURN 1
        WHEN "February"  RETURN 2
        WHEN "March"     RETURN 3
        WHEN "April"     RETURN 4
        WHEN "May"       RETURN 5
        WHEN "June"      RETURN 6
        WHEN "July"      RETURN 7
        WHEN "August"    RETURN 8
        WHEN "September" RETURN 9
        WHEN "October"   RETURN 10
        WHEN "November"  RETURN 11
        WHEN "December"  RETURN 12
  END CASE
  RETURN 1
END FUNCTION


# =============================================================================
# setArrayPropertyElement
# =============================================================================
FUNCTION setArrayPropertyElement(propName, elementIdx, value)
  DEFINE propName STRING
  DEFINE elementIdx INTEGER
  DEFINE value STRING
  DEFINE win ui.Window
  DEFINE prop om.DomNode

  LET win = ui.Window.getCurrent()
  LET prop = win.findNode("PropertyArray", propName)
  LET prop = prop.getChildByIndex(elementIdx)
  CALL prop.setAttribute("value",value)
END FUNCTION


# =============================================================================
# setProperty
# =============================================================================
FUNCTION setProperty(propName, value)
  DEFINE propName STRING
  DEFINE value STRING
  DEFINE win ui.Window
  DEFINE prop om.DomNode

  LET win = ui.Window.getCurrent()
  LET prop = win.findNode("Property", propName)
  CALL prop.setAttribute("value",value)
END FUNCTION

