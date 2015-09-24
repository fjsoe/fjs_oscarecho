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
SCHEMA officestore

GLOBALS "globals.4gl"

TYPE OrderType RECORD
    orders   RECORD LIKE orders.*,
    account  RECORD LIKE account.*,
    country  RECORD LIKE country.*,
    lineitem RECORD LIKE lineitem.*,
    product  RECORD LIKE product.*,
    category RECORD LIKE category.*,
    item     RECORD LIKE item.*
END RECORD

  -- set this constant to false if you prefer to run from the database
  -- In this case you will need an office store database up and running
CONSTANT runFromFile INTEGER = FALSE
CONSTANT dataFile STRING = "OrderReport.unl"


DEFINE controlBlock PivotControlBlock

MAIN

    DEFINE
        r_output STRING,
        r_filename STRING

    LET r_filename="OrderReport"
    IF isGDC() THEN
        LET r_output="SVG"
    ELSE
        LET r_output="PDF"
    END IF
    OPEN FORM f_configuration FROM "Configuration"
    DISPLAY FORM f_configuration
    INPUT BY NAME r_filename, r_output  ATTRIBUTES (UNBUFFERED, WITHOUT DEFAULTS, CANCEL=FALSE, ACCEPT=FALSE)
        ON ACTION preview
            CALL runReport(r_filename, r_output,"preview")
        ON ACTION saveOnDisk            
            CALL runReport(r_filename, r_output,"saveOnDisk")
        ON ACTION quit
            EXIT INPUT                    
        ON CHANGE r_output 
            CALL dialog.setActionActive("preview",r_output != "Image" AND (isGDC() OR r_output!="SVG"))                    
    END INPUT
END MAIN
FUNCTION isGDC()
    DEFINE fename String
    CALL ui.interface.frontcall("standard", "feinfo", ["fename"],[fename])
    RETURN fename == "Genero Desktop Client"
END FUNCTION
FUNCTION runReport(filename, output, action)
    DEFINE
        output STRING,
        action STRING,
        filename STRING,
        preview INTEGER,
        handler om.SaxDocumentHandler

    LET preview = FALSE
    IF action IS NOT NULL THEN
        IF action == "preview" THEN
            LET preview = TRUE
        END IF
    END IF
    INITIALIZE handler TO NULL
    IF filename IS NOT NULL AND output IS NOT NULL THEN
        LET handler = configureReport(filename || '.4rp', output, preview)
    END IF
    IF handler IS NULL THEN
        RETURN
    END IF
    
    IF filename =="MasterReport" THEN
        CALL runTwice(handler)
    ELSE 
        IF runFromFile THEN
            DISPLAY "Running report from  file \"", dataFile.trim(), "\""
            CALL runReportFromFile(handler)
        ELSE
            DISPLAY "Running report from database"
            CALL runReportFromDatabase(handler)
        END IF
    END IF
END FUNCTION
FUNCTION runReportFromDatabase(handler)
    DEFINE
        orderline OrderType,
        handler om.SaxDocumentHandler

   DATABASE officestore
   DECLARE c_order CURSOR FOR
        SELECT  orders.*,
                account.*,
                country.*,
                lineitem.*,
                product.*,
                category.*,
                item.*
        FROM orders, account, lineitem, product, category, item, country
        WHERE
            orders.orderid = lineitem.orderid
        AND orders.userid = account.userid
        AND lineitem.itemid = item.itemid
        AND item.productid = product.productid
        AND product.catid = category.catid
        AND country.code = orders.billcountry
        ORDER BY orders.userid, orders.orderid, lineitem.linenum

    START REPORT report_all_orders TO XML HANDLER handler
    FOREACH c_order INTO orderline.*
        OUTPUT TO REPORT report_all_orders(orderline.*)
        IF fgl_report_getErrorStatus() THEN
            DISPLAY "FGL: STOPPING REPORT, msg=\"",fgl_report_getErrorString(),"\""
            EXIT FOREACH
        END IF 
    END FOREACH
    FINISH REPORT report_all_orders

    CLOSE c_order
END FUNCTION

FUNCTION runReportFromFile(handler)
    DEFINE
        orderline OrderType,
        handler om.SaxDocumentHandler,
        ch base.channel

   LET ch = base.Channel.create()
   CALL ch.openFile(dataFile,"r")

   START REPORT report_all_orders TO XML HANDLER handler
   WHILE ch.read([orderline.*])
        OUTPUT TO REPORT report_all_orders(orderline.*)
        IF fgl_report_getErrorStatus() THEN
            DISPLAY "FGL: STOPPING REPORT, msg=\"",fgl_report_getErrorString(),"\""
            EXIT WHILE
        END IF 
   END WHILE
   FINISH REPORT report_all_orders

   CALL ch.close()
END FUNCTION

FUNCTION runTwice(handler)
    DEFINE
        handler om.SaxDocumentHandler
   START REPORT report_all_orders_twice  TO XML HANDLER HANDLER
   OUTPUT TO REPORT report_all_orders_twice()
   FINISH REPORT report_all_orders_twice
END FUNCTION

FUNCTION promptForFieldsToPrint(rddFile,reportName)
    DEFINE rddFile,reportName STRING
    DEFINE left DYNAMIC ARRAY OF STRING
    DEFINE right DYNAMIC ARRAY OF STRING
    DEFINE retval,i,leftFieldCount,rightFieldCount INTEGER
    DEFINE fieldNames DYNAMIC ARRAY OF STRING
    DEFINE fieldNamesString STRING
    
    CALL rdd_getEveryRowFields(rddFile,reportName) RETURNING fieldNames

    LET leftFieldCount=0
    LET rightFieldCount=0
    FOR i=1 TO fieldNames.getLength()
        IF fieldNames[i] MATCHES "orderline.lineitem.*" OR fieldNames[i] MATCHES "orderline.category.*" THEN
            LET rightFieldCount=rightFieldCount+1
            LET right[rightFieldCount]=fieldNames[i]
        ELSE
            LET leftFieldCount=leftFieldCount+1
            LET left[leftFieldCount]=fieldNames[i]
        END IF
    END FOR
    LET retval=promptForFieldSelectionDialog(left,right)
    IF retval THEN
        IF right.getLength()<=0 THEN
            RETURN TRUE,NULL
        ELSE
            LET fieldNamesString=right[1]
            FOR i=2 TO right.getLength()
                LET fieldNamesString=fieldNamesString||","||right[i]
            END FOR
            RETURN TRUE,fieldNamesString.toLowerCase()
        END IF
    ELSE
        RETURN FALSE,NULL
    END IF
END FUNCTION
FUNCTION configureReport(filename, outputformat, preview)
    DEFINE
        filename STRING,
        outputformat STRING,
        preview INTEGER,
        retval INTEGER,
        fieldNames STRING

    -- load the 4rp file
    IF filename == "Generic List.4rp" THEN
        IF NOT fgl_report_loadCurrentSettings(NULL) THEN
            EXIT PROGRAM
        END IF
        CALL promptForFieldsToPrint("OrderReport.rdd","report_all_orders") RETURNING retval,fieldNames
        IF NOT retval THEN
            RETURN NULL
        END IF
        CALL fgl_report_setAutoformatType("FLAT LIST")
        CALL fgl_report_configureAutoformatOutput(NULL,8,NULL,"Order List",fieldNames,NULL)
        CALL fgl_report_configurePageSize("a4length","a4width")
        CALL fgl_report_configureXLSDevice(NULL,NULL,FALSE,NULL,NULL,NULL,TRUE) #preserve spaces and merge pages in XLS output
        CALL fgl_report_setTitle("Order List")
    ELSE
        CALL promptForPivotDialogIfAny(filename,"6,2","4,0,2") RETURNING retval, controlBlock.* #Zip code, Unitprice and Unitcost by Product category and Shipping area
        IF NOT retval THEN
            RETURN NULL
        END IF
        IF NOT fgl_report_loadCurrentSettings(filename) THEN
            EXIT PROGRAM
        END IF
    END IF

    -- change some parameters
    IF filename == "OrderLabels.4rp" THEN
        CALL fgl_report_selectLogicalPageMapping("labels")
        CALL fgl_report_setPaperMargins("5mm", "5mm", "4mm", "4mm")
        CALL fgl_report_configureLabelOutput("a4width", "a4length", NULL, NULL, 2, 6)
    END IF
    CALL fgl_report_selectDevice(outputformat)
    CALL fgl_report_selectPreview(preview)

    -- use the report
    RETURN fgl_report_commitCurrentSettings()
END FUNCTION

REPORT report_all_orders( orderline )
    DEFINE
        orderline OrderType,
        lineitemprice LIKE lineitem.unitprice,
        overalltotal LIKE orders.totalprice,
        usertotal LIKE orders.totalprice,
        ordertotal LIKE orders.totalprice

    ORDER EXTERNAL BY orderline.orders.userid, orderline.orders.orderid, orderline.lineitem.linenum

    FORMAT
        FIRST PAGE HEADER
            LET overalltotal = 0
            PRINT controlBlock.*

        BEFORE GROUP OF orderline.orders.userid
            DISPLAY "USER " || orderline.orders.userid
            LET usertotal = 0

        BEFORE GROUP OF orderline.orders.orderid
            DISPLAY "    ORDER " || orderline.orders.orderid
            LET ordertotal = 0



        ON EVERY ROW
            DISPLAY "        EVERY ROW " || orderline.lineitem.linenum
            LET lineitemprice = orderline.lineitem.unitprice * orderline.lineitem.quantity
            LET overalltotal = overalltotal + lineitemprice
            LET usertotal = usertotal + lineitemprice
            LET ordertotal = ordertotal + lineitemprice
            PRINT orderline.*, lineitemprice, overalltotal, usertotal, ordertotal

END REPORT

REPORT report_all_orders_twice()
    DEFINE
        orderline OrderType,
        ch base.channel

    FORMAT  
        ON EVERY ROW
 
            LET ch = base.Channel.create()
            CALL ch.openFile(dataFile,"r")
            DISPLAY "MASTER ITERATION 1 " 
            START REPORT report_all_orders 
            WHILE ch.read([orderline.*])
                OUTPUT TO REPORT report_all_orders(orderline.*)
                IF fgl_report_getErrorStatus() THEN
                    DISPLAY "FGL: STOPPING REPORT, msg=\"",fgl_report_getErrorString(),"\""
                    EXIT WHILE
                END IF 
            END WHILE
            FINISH REPORT report_all_orders
            CALL ch.close()

            DISPLAY "MASTER ITERATION 2 " 
            LET ch = base.Channel.create()
            CALL ch.openFile(dataFile,"r")

            START REPORT report_all_orders 
            WHILE ch.read([orderline.*])
                OUTPUT TO REPORT report_all_orders(orderline.*)
                IF fgl_report_getErrorStatus() THEN
                    DISPLAY "FGL: STOPPING REPORT, msg=\"",fgl_report_getErrorString(),"\""
                    EXIT WHILE
                END IF

            END WHILE
            FINISH REPORT report_all_orders
            CALL ch.close()
    
END REPORT

