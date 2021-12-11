*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library     RPA.Browser
Library     RPA.HTTP
Library     RPA.RobotLogListener
Library     RPA.Dialogs
Library     RPA.Robocorp.Vault
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.FileSystem

# +
*** Variables ****
${url} =                         https://robotsparebinindustries.com/
${url_download_input_file} =     https://robotsparebinindustries.com/orders.csv
# -

** Keywords ***
Open Website

    #Populate credential
    ${secretCredential} =     Get Secret    credential
    
    Open Chrome Browser    ${url}
    Maximize Browser Window
    Wait Until Element Is Visible    id:username    60s
    Click Element   css:li.nav-item:nth-child(2)

*** Keywords ***
Get Order List

    Download    ${url_download_input_file}      overwrite=True
    ${orderList}   Read table from CSV    orders.csv   header=True    dialect=excel
    [Return]    ${orderList}

*** Keywords ***
Close Popup
    
    ${isExist} =     Is Element Visible    id:head
    IF    ${isExist}
        Click Button    OK
        Wait Until Element Is Visible    id:head    10s
    END

*** Keywords ***
Input Form

    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    css:input.form-control:nth-child(3)    ${row}[Legs]
    Input Text    css:input.form-control:nth-child(2)    ${row}[Address]

*** Keywords ***
Click Preview Button

    Click Button    Preview

*** Keywords ***
Submit Order Form

    Click Button    id:order
    Wait Until Element Is Visible    id:receipt    10s

*** Keywords ***
Save Receipt

    [Arguments]     ${orderNumber}
    ${pdfFile} =    Join Path    ${CURDIR}    output    ${orderNumber}.pdf
    Wait Until Element Is Visible    id:receipt     10s
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${pdfFile}
    [Return]    ${pdfFile}

*** Keywords ***
Screenshot Order Robot

    [Arguments]     ${orderNumber}
    ${outputImage} =    Join Path    ${CURDIR}    output    ${orderNumber}.png
    ${screenshot}=    Screenshot     id:robot-preview-image      ${outputImage}
    [Return]    ${outputImage}

*** Keywords ***
Attach PDF File

    [Arguments]    ${screenshot}    ${pdf}
    ${file} =     Create List    ${screenshot}
    Add files to pdf    ${file}    ${pdf}    TRUE


*** Keywords ***
Click Another Order Button

    Click Button    id:order-another

*** Keywords ***
Archive Output PDF File

    ${outputFolder} =    Join Path    ${CURDIR}    output
    ${archiveFolder} =     Join Path    ${CURDIR}    output    output.zip
    Archive Folder With Zip    ${outputFolder}    ${archiveFolder}

*** Tasks ***
Create Robot Receipts from RobotSpareBin Industries Inc
    Open Website

    ${orderList} =    Get Order List
    
    FOR    ${row}    IN    @{orderList}
        Close Popup
        Input Form    ${row}
        Click Preview Button
        Wait Until Keyword Succeeds    5x    0.5s    Submit Order Form
        ${outputPdfFile} =    Save Receipt    ${row}[Order number]
        ${screenshot} =    Screenshot Order Robot    ${row}[Order number]
        Attach PDF File    ${screenshot}    ${outputPdfFile}
        Click Another Order Button
    END

    Archive Output PDF File