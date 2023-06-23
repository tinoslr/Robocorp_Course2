*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library    RPA.Archive


*** Variables ***
${URL_Order}                https://robotsparebinindustries.com/#/robot-order
${URL_CSV}                  https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}      10x
${GLOBAL_RETRY_INTERVAL}    0.5s


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    Ordering Process
    Embed the image to PDF
    Zip File the receipts


*** Keywords ***
Open the robot order website
#open the Browser
    Open Available Browser    ${URL_Order}

Close the annoying modal
#Close the cookie 
    Click Button    OK

Get orders
#Download the CSV file from the given Link and read the values to a table.
    Download    ${URL_CSV}    overwrite=True
    @{orders}=    Read table from CSV    orders.csv
    RETURN    @{orders}


#
Fill the Form and Submit the order
#Fill the Form with the matching value. Then preview the Robot, submit the order, return to the order menu and close the cookie modal.
    [Arguments]    ${order}
    Wait Until Element Is Visible    head
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Wait Until Keyword Succeeds    10x    0.5s    Preview the Robot    ${order}
    Click Button    order
    Export the receipt as PDF    ${order}
    Click Button    order-another
    Close the annoying modal  
    


# Preview the Robot and take a screenshot of it. Picture gets saved in the output directory
Preview the Robot
    [Arguments]    ${order}
    Click Button    Preview
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/image/robo_image_${order}[Order number].png


Ordering Process
#Ordering everything. Loop through the orders table and if the keyword fails retry it 10x times.
    @{orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds    10x    0.5s    Fill the Form and Submit the order    ${order}
    END

Export the receipt as PDF
# Get the receipt and add it to the output directory as a PDF file
    [Arguments]    ${order}
    #Wait Until Element Is Visible    id:order-completion    timeout:timedelta(seconds=1)
    ${receipt}=    Get Element Attribute    id:receipt     outerHTML
    Html To Pdf    ${receipt}    ${OUTPUT_DIR}/receipts/receipt_${order}[Order number].pdf

Embed the image to PDF
    @{orders}=    Get orders
    #[Arguments]    ${order}
    FOR    ${order}    IN    @{orders}
        Open Pdf    ${OUTPUT_DIR}/receipts/receipt_${order}[Order number].pdf
        Add Watermark Image To Pdf    image_path=${OUTPUT_DIR}/image/robo_image_${order}[Order number].png    output_path=${OUTPUT_DIR}/receipt+image/receipt_${order}[Order number].pdf
        #Close Pdf    ${OUTPUT_DIR}/receipts/receipt_${order}[Order number].pdf
    END

Zip File the receipts
    Archive Folder With Zip   ${OUTPUT_DIR}/receipt+image    receipts.zip     