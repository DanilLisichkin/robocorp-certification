*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Robocorp.Vault
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.Tables
Library           RPA.RobotLogListener
Library           RPA.Dialogs
Library           Telnet
Library           RPA.FileSystem
Library           RPA.PDF
Library           RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${secrets}=    Get Secret    secrets
    Open the robot order website    ${secrets}
    ${orders}=    Get orders    ${secrets}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    [Arguments]    ${secrets}
    Open Available Browser    ${secrets}[url]

Get orders
    [Arguments]    ${secrets}
    Download    ${secrets}[csv]    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=True
    [Return]    ${table}

Close the annoying modal
    ${modalExist}=    Is Element Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Log    ${modalExist}
    IF    ${modalExist}==${True}
        Click Button    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    END

Fill the form
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[4]/input    ${row}[Address]

Preview the robot
    Click Button When Visible    id:preview
    Wait Until Element Is Visible    id:robot-preview-image

Submit the order
    Click Button When Visible    id:order
    Wait Until Element Is Visible    id:receipt    1s

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${file}=    Join Path    ${CURDIR}    output    ${order_num}.pdf
    Wait Until Element Is Visible    id:receipt
    ${sales_results_html}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf    ${sales_results_html}    ${file}
    [Return]    ${file}

Take a screenshot of the robot
    [Arguments]    ${order_num}
    ${file_pdf}=    Join Path    ${CURDIR}    output    ${order_num}.png
    Screenshot    id:robot-preview-image    ${file_pdf}
    [Return]    ${file_pdf}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    TRUE

Go to order another robot
    Wait Until Element Is Visible    id:receipt
    Click Button    id:order-another

Create a ZIP file of the receipts
    ${outputFolder} =    Join Path    ${CURDIR}    output
    ${archiveFolder} =    Join Path    ${CURDIR}    output    output.zip
    Archive Folder With Zip    ${outputFolder}    ${archiveFolder}
