*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs
Library         RPA.Robocloud.Secrets

*** Keywords ***
Open the robot order website
	${secret}=	Get Secret	roboshop
    Open Available Browser              ${secret}[url]
    Maximize Browser Window

*** Keywords ***
Ask for orders file url
    Add Heading         Gimmie' ya url
    Add Text Input      URL   orders_URL   
    ${result}=          Run dialog
    [Return]            ${result.URL}

*** Keywords ***
Get orders
    [ARGUMENTS]     ${url}  
	Download		${url}		overwrite=True
    ${orders}=      Read Table From Csv	   orders.csv
    [Return]        ${orders}

*** Keywords ***
Close the annoying modal
    Wait Until Page Contains Element    //button[normalize-space()='OK']    3
    Click Button                        //button[normalize-space()='OK']

*** Keywords ***
Fill the form
    [ARGUMENTS]         ${row} 
    Wait Until Page Contains Element    //select[@id='head']    3
    Select From List By Value           //select[@id='head']    ${row}[Head]
    Select Radio Button                 body    ${row}[Body]
    Input Text                          css:body > div:nth-child(2) > div:nth-child(2) > div:nth-child(1) > div:nth-child(2) > div:nth-child(1) > form:nth-child(2) > div:nth-child(3) > input:nth-child(3)     ${row}[Legs]
    Input Text                          //input[@id='address']  ${row}[Address]
    Click Button                        //button[normalize-space()='Preview']


*** Keywords ***
Submit the order
    Click button                        //button[normalize-space()='Order']
    Wait Until Page Contains Element    //button[normalize-space()='Order another robot']   1

*** Keywords ***
Store the receipt as a PDF file
    [ARGUMENTS]    ${receipt#}
    Wait Until Element Is Visible       //div[@id='receipt']
    ${receipt}=  Get Element Attribute  //div[@id='receipt']    outerHTML 
    ${pdf}=      Set Variable           ${OUTPUT_DIR}${/}receipts${/}${receipt#}.pdf
    Html To Pdf     ${receipt}          ${pdf}
    [Return]        ${pdf}

*** Keywords ***
Take a screenshot of the robot
    [ARGUMENTS]    ${robot_image}
    Wait Until Element Is Visible       //div[@id='robot-preview-image'] 
    ${screenshot}=      Set Variable    ${OUTPUT_DIR}${/}images${/}${robot_image}.png
    Screenshot     //div[@id='robot-preview-image']     ${screenshot}
    [Return]        ${screenshot}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [ARGUMENTS]     ${screenshot}   ${pdf}
    Add Watermark Image To Pdf  ${screenshot}   ${pdf}    ${pdf}

*** Keywords ***
Create a ZIP file of the receipts
    [ARGUMENTS]     ${zip}
    Archive Folder With Zip     ${zip}      orders.zip      True

*** Keywords ***
Go to order another robot
    Click Button                        //button[normalize-space()='Order another robot']

*** Keywords ***
Close open browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders_url}=  Ask for orders file url
    ${orders}=    Get orders    ${orders_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds     5x  2s  Submit the order
        ${pdf}=    Store the receipt as a PDF file  ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts   ${pdf}
	[Teardown]  Close open browser


