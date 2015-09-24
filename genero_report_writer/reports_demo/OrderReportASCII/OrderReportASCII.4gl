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

 TYPE OrderType RECORD
            orders    RECORD LIKE orders.*,
            billcountrydesc LIKE country.codedesc,
            shipcountrydesc LIKE country.codedesc,
            lineitem  RECORD LIKE lineitem.*,
            product   RECORD
                productid LIKE product.productid,
                prodname  LIKE product.prodname,
                proddesc  LIKE product.proddesc,
                prodpic   LIKE product.prodpic
            END RECORD,
            category  RECORD LIKE category.*,
            item      RECORD
                attr1 LIKE item.attr1,
                attr2 LIKE item.attr2,
                attr3 LIKE item.attr3,
                attr4 LIKE item.attr4,
                attr5 LIKE item.attr5
            END RECORD
        END RECORD

  -- set this constant to false if you prefer to run from the database
  -- In this case you will need an office store database up and running
CONSTANT runFromFile INTEGER = true
CONSTANT dataFile STRING = "OrderReportASCII.unl"

MAIN

     DEFINE handler om.SaxDocumentHandler
    LET handler = configureOutput()
    
    IF handler IS NULL THEN
        EXIT PROGRAM
    END IF

    IF runFromFile THEN
        DISPLAY "Running report from  file \"", dataFile.trim(), "\""
        CALL runReportFromFile(handler)
    ELSE
        DISPLAY "Running report from database"
        CALL runReportFromDatabase(handler)
    END IF
END MAIN

FUNCTION configureOutput()
    IF NOT fgl_report_loadCurrentSettings(NULL) THEN
        RETURN NULL
    END IF
    --CALL fgl_report_selectLogicalPageMapping("multipage")
    --CALL fgl_report_configureMultipageOutput(2, 4, TRUE)
    CALL fgl_report_setPageMargins("4.5cm","0.5cm","2.5cm","0.5cm")
    --CALL fgl_report_selectDevice("XLS")
    CALL fgl_report_selectDevice(getPreviewDevice())
    CALL fgl_report_selectPreview(TRUE)
    RETURN fgl_report_commitCurrentSettings()
END FUNCTION

FUNCTION getPreviewDevice()
    DEFINE fename String
    CALL ui.interface.frontcall("standard", "feinfo", ["fename"],[fename])
    RETURN iif(fename=="Genero Desktop Client","SVG","PDF")     
END FUNCTION
FUNCTION runReportFromDatabase(handler)
    DEFINE
    handler om.SaxDocumentHandler,
        orderline OrderType
    DATABASE officestore

    DECLARE c_orders CURSOR FOR
        SELECT  orders.*,
                billcountry.codedesc,
                shipcountry.codedesc,
                lineitem.*,
                product.productid, product.prodname, product.proddesc, product.prodpic,
                category.*,
                item.attr1,
                item.attr2,
                item.attr3,
                item.attr4,
                item.attr5
        FROM orders, lineitem, product, category, item, country billcountry, country shipcountry
        WHERE
            orders.orderid = lineitem.orderid
        AND lineitem.itemid = item.itemid
        AND item.productid = product.productid
        AND product.catid = category.catid
        AND billcountry.code = orders.billcountry
        AND shipcountry.code = orders.shipcountry
        ORDER BY orders.orderdate, orders.orderid, lineitem.linenum

    -- The DVM text output is ignored when XML is output
    START REPORT report_all_orders TO XML HANDLER handler
    FOREACH c_orders INTO orderline.*
        OUTPUT TO REPORT report_all_orders(orderline.*)
    END FOREACH
    FINISH REPORT report_all_orders
    
    CLOSE c_orders
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
   END WHILE
   FINISH REPORT report_all_orders
  
   CALL ch.close()
END FUNCTION

REPORT report_all_orders( orderline )
    DEFINE
        orderline  OrderType,
        totalprice LIKE lineitem.unitprice,
        pagenum INTEGER,
        char30  CHAR(30),
        state STRING,
        newGroup SMALLINT

    OUTPUT
        LEFT MARGIN    0
        RIGHT MARGIN   86
        TOP MARGIN     0
        BOTTOM MARGIN  0
        PAGE LENGTH    66

    FORMAT

    PAGE HEADER
        IF newGroup THEN
            LET newGroup = FALSE
            LET pagenum = 1
        ELSE
            -- NOTE: For the First page header: newGroup is FALSE and pagenum = 0 (default value)
            LET pagenum = pagenum + 1
        END IF

        PRINT "Account ID: ", orderline.orders.userid CLIPPED, COLUMN 45, "Order ID:   ", orderline.orders.orderid USING "<<<<<<<<<<"
        PRINT COLUMN 45, "Order Date: ", orderline.orders.orderdate
        PRINT

    BEFORE GROUP OF orderline.orders.orderid
        LET newGroup = TRUE
        SKIP TO TOP OF PAGE
        LET totalprice = 0
        PRINT "Bill To: ", orderline.orders.billfirstname CLIPPED, " ", orderline.orders.billlastname CLIPPED, COLUMN 45, "Ship To: ", orderline.orders.shipfirstname CLIPPED, " ", orderline.orders.shiplastname CLIPPED
        
        PRINT "         ", orderline.orders.billaddr1 CLIPPED,                                         COLUMN 45, "         ", orderline.orders.shipaddr1 CLIPPED
        -- PRINT "         ", orderline.orders.billaddr2 CLIPPED,                                         COLUMN 45, "         ", orderline.orders.shipaddr2 CLIPPED
        PRINT "         ", orderline.orders.billcity CLIPPED, ", ";
        LET state = orderline.orders.billstate CLIPPED
        IF state.getlength() <> 0 THEN
            PRINT state, " ";
        END IF
        PRINT orderline.orders.billzip CLIPPED;
        
        PRINT                                                                                  COLUMN 45, "         ", orderline.orders.shipcity CLIPPED, ", ";
        
        LET state = orderline.orders.shipstate CLIPPED
        IF state.getlength() <> 0 THEN
            PRINT state, " ";
        END IF
        PRINT orderline.orders.shipzip CLIPPED

        PRINT "         ", orderline.billcountrydesc CLIPPED,                                          COLUMN 45, "         ", orderline.shipcountrydesc CLIPPED
        SKIP 2 LINES
    
        PRINT "Item#      Description                       Quantity   Unit Price             Amount"
        PRINT "-------------------------------------------------------------------------------------"

    ON EVERY ROW
        -- If the group doesn't fit on page,
        -- Print a Sub-Total and continue on the next page
        -- On the new page, repeat a part of the header and
        -- display the previous page total
        IF LINENO > 60 THEN
            PRINT COLUMN 55, "                    -----------"
            PRINT COLUMN 55, "Sub total:         ", totalprice
            SKIP TO TOP OF PAGE

            PRINT "Item#      Description                       Quantity   Unit Price             Amount"
            PRINT "-------------------------------------------------------------------------------------"
            PRINT "Total from the previous page: ";
            PRINT COLUMN 55, "                   ", totalprice
            PRINT COLUMN 55, "                    -----------"
        END IF

        LET char30 = orderline.product.prodname   -- Truncate the product name to 30 chars
        PRINT orderline.lineitem.itemid, " ", char30, " ", orderline.lineitem.quantity, " ", orderline.lineitem.unitprice, " ", orderline.lineitem.quantity * orderline.lineitem.unitprice
        LET totalprice = totalprice + orderline.lineitem.quantity * orderline.lineitem.unitprice

    AFTER GROUP OF orderline.orders.orderid
        PRINT COLUMN 55, "                    -----------"
        PRINT COLUMN 55, "    Total:         ", totalprice
        SKIP 2 LINES
        PRINT "Please remit payment to: Office Supplies"
        PRINT "                         4 Avenue de Paris"
        PRINT "                         78000 Versailles"
        PRINT "                         FRANCE"

    PAGE TRAILER
        PRINT "_____________________________________________________________________________________"
        PRINT COLUMN 63, "Order Page: ", pagenum USING "##&" , ", Page:", PAGENO USING "<<"

END REPORT
