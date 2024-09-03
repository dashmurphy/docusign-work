public without sharing class RevelOnboardingPprDocGen {

    public class JSONGeneratorSafe 
    {
        public JSONGenerator Internal
        {
            get;
            set;
        }

        public void writeStringField(string field, string value) { 
            try { Internal.writeStringField(field, value); } catch (Exception ex) { }
        }

        public void writeDateField(string field, Date value) { 
            try { Internal.writeDateField(field, value); } catch (Exception ex) { }
        }

        public void writeDateTimeField(string field, DateTime value) {
            try { Internal.writeDateTimeField(field, value); } catch (Exception ex) { }
        }

        public void writeBooleanField(string field, boolean value) {
            try { Internal.writeBooleanField(field, value); } catch (Exception ex) { }
        }

        public void writeNumberField(string field, decimal value) {
            try { Internal.writeNumberField(field, value); } catch (Exception ex) { }
        }

        public JSONGeneratorSafe(JSONGenerator myLocalGenerator)
        {
            this.Internal = myLocalGenerator;
        }
    }

    /** START --- DOCUSIGN APIS **/
    // Must be a list in order to be called via Flow, this isn't necessary if Flow is not used
    @InvocableMethod(label='docusignGen_And_API')
    public static List<String> sendEnvelope(List<String> record) {
        System.debug(record);  
        Id recordId = record[0];
        System.debug(recordId);
        genAndConvertRaxtPdf(recordId);
        return Null;
    }    

    public static void genAndConvertRaxtPdf(Id recordId) {
        if(test.isRunningTest())
        return;
        
        // Example opportunity record Id 006Ho00000Ra4e1IAB = Burlington Textile
        System.debug('genAndConvertRaxtPdf running');
        String jsonBody = createBodyJSON(recordId);  // Create the message body for DocuSign endpoint /restapi/v2.1/accounts/{accountId}/envelopes/generate_and_convert
        System.debug(jsonBody);
        HttpRequest req = new HttpRequest();

        Organization org = [SELECT IsSandbox FROM Organization WHERE Id =:UserInfo.getOrganizationId()];
        string prefix = org.IsSandbox ? 'DocuSignAuthProviderDemo' : 'DocuSignAuthProviderProd';
        string accountId = org.IsSandbox ? '16356130' : '43615542';

        req.setEndpoint('callout:' + prefix + '/restapi/v2.1/accounts/'  + accountId + '/envelopes/generate_and_convert'); // API call to DocuSign endpoint 
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setBody(jsonBody); // Grab record data and template for API call
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String responseBody = res.getBody(); // Generated document as base64
        System.debug(responseBody);
        Blob blobContent;
        try {
            blobContent = EncodingUtil.base64Decode(responseBody);
        } catch (StringException e) {
            System.debug(e);
            throw e;
        }
        DateTime now = System.now();
        String s = string.valueof(now); // Get current date/time  
        String accountName = getAccountName(recordId);
        
        // Save generated document to Files
        ContentVersion v = new ContentVersion();
        v.VersionData = blobContent;
        v.Title = 'Payment Processing Application_' + accountName + '_' + s;
        v.PathOnClient ='docusignGen_And_API.PDF';
        insert v;
        v = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =: v.Id];
        ContentDocumentLink objCDL = new ContentDocumentLink(
            ContentDocumentId = v.ContentDocumentId,
            LinkedEntityId = recordId,
            Visibility = 'AllUsers'
        );
        insert objCDL;
    }  

    private static String getAccountName(Id recordId) {
        Payment_Processing_NEW__c pprRec = [
            SELECT Entity_Name__c
            FROM Payment_Processing_NEW__c 
            WHERE Id = : recordId 
            LIMIT 1
        ];

        return pprRec.Entity_Name__c;
    }

    public static String createBodyJSON(Id recordId){
        
        // Grab the template document and convert into base64 Blob for document generation body
        Id templateContentDocId =  Revel_Onboarding_Automation_Controls__c.getOrgDefaults().Revel_Advantage_XT_PDF_Document_ID__c;

        ContentVersion file = [SELECT VersionData, Id FROM ContentVersion WHERE IsLatest = TRUE AND ContentDocumentId  = :templateContentDocId LIMIT 1];
        Blob fileBlob = file.VersionData;           
        String fileBase64 = EncodingUtil.base64Encode(fileBlob);
        
        String pprRecord = createPprRecordJSON(recordId);
        
        // Create the JSON body for the Document Generation API call
        JSONGenerator jsGen = SYSTEM.JSON.createGenerator(true);
        jsGen.writeStartObject();  
        jsGen.writeFieldName('generateProperties');
            jsGen.writeStartArray();
                jsGen.writeStartObject();
                jsGen.writeStringField('dataJson', pprRecord);  // Record Data
                jsGen.writeBlobField('base64GenerateTemplateDocument', fileBlob);  // Template Document
                jsGen.writeStringField('archiveDocumentType', 'PDF');  // Response document type which can be XHTML, PDF, or DOCX
                jsGen.writeEndObject(); 
            jsGen.writeEndArray(); 
        jsGen.writeEndObject();
        String jsonData = jsGen.getAsString();
        return jsonData;
    }      

    // Create Opportunity record to JSON
    public static String createPprRecordJSON(Id recordId) {

        // SOQL Opportunity fields you would like to make accessible creating the JSON
        Payment_Processing_NEW__c pprRec = [
            SELECT Entity_Name__c,
            (SELECT 
                Id, 
                PPR_App_Contact__r.Name, 
                PPR_App_Contact__r.Email, 
                PPR_App_Contact__r.Phone,
                Date_Time_PPR_Status_updated__c,
                IP_address__c
                FROM Onboardings__r
            ),
            Business_Legal_Structure__c,
            Account_Name__c,
            Account_Description__c,
            Federal_Tax_Information_number__c,
            Entity_Primary_URL__c,
            Entity_Phone__c,
            Business_Email__c,
            Date_Founded__c,
            Public_Company__c,
            DBA_Street_1__c,
            DBA_CIty__c,
            DBA_State__c,
            DBA_Postal_Code__c,
            DBA_Country__c,
            Industry_Category__c,
            Bank_Name__c, 
            Direct_Deposit_Account_Type__c, 
            Bank_Account_Type_WorldPay__c,
            Accounting_Number1__c, Routing_Number1__c,
            Percentage_of_Card_swipe_transactions__c,
            Percentage_of_Manual_transactions__c,
            eCommerce_Transaction_Percent__c,
            Are_you_a_seasonal_business__c,
            Months_in_Business__c,
            Average_credit_debit_transaction_amount__c,
            Total_yearly_credit_debit_sales_volume__c,
            How_many_Ben_Owners_own_25_or_more__c, 
            Is_Controller_Beneficial_Owner__c,
            Controller_Name__c,
            Controller_Job_Title__c,
            Controller_SSN__c,
            Controller_Date_of_Birth__c,
            Controller_Email__c,
            Controller_Phone_Number__c,
            Controller_Street_1__c,
            Controller_Street_2__c,
            Controller_City__c,
            Controller_State__c,
            Controller_Postal_Code__c,
            Controller_Country__c,
            Controller_Ownership_Percentage__c,
            Representative_1_Name__c,
            Rep_1_Ownership_Percentage__c,
            Rep_1_Job_Title__c,
            Rep1_SSN__c,
            Rep_1_Date_of_Birth__c,
            Rep_1_Email__c,
            Rep_1_Phone_Number__c,
            Rep_1_Address_street_1__c,
            Rep_1_address_street_2__c,
            Rep_1_City__c,
            Rep_1_State__c,
            Rep_1_Postal_Code__c,
            Ben_Owner_1_Country__c,
            Representative_2_Name__c,
            Rep_2_Ownership_Percentage__c,
            Rep_2_Job_Title__c,
            Rep2_SSN__c,
            Rep_2_Date_of_Birth__c,
            Rep_2_Email__c,
            Rep_2_Phone_Number__c,
            Rep_2_address_street_1__c,
            Rep_2_address_street_2__c,
            Rep_2_City__c,
            Rep_2_State__c,
            Rep_2_Postal_Code__c,
            Ben_Owner_2_Country__c,
            Representative_3_Name__c,
            Rep_3_Ownership_Percentage__c,
            Rep_3_Job_Title__c,
            Rep3_SSN__c,
            Rep_3_Date_of_Birth__c,
            Rep_3_Email__c,
            Rep_3_Phone_Number__c,
            Rep_3_address_street_1__c,
            Rep_3_address_street_2__c,
            Rep_3_City__c,
            Rep_3_State__c,
            Rep_3_Postal_Code__c,
            Ben_Owner_3_Country__c,
            Representative_4_Name__c,
            Rep_4_Ownership_Percentage__c,
            Rep_4_Job_Title__c,
            Rep4_SSN__c,
            Rep_4_Date_of_Birth__c,
            Rep_4_Email__c,
            Rep_4_Phone_Number__c,
            Rep_4_address_street_1__c,
            Rep_4_address_street_2__c,
            Rep_4_City__c,
            Rep_4_State__c,
            Rep_4_Postal_Code__c,
            Ben_Owner_4_Country__c,
            Signer__c,
            Agree_to_payment_processing_fees__c,
            I_Agree__c,
            I_Attest_To_The_Information__c,
            Agree_to_Visa_Disclosure_Acknowledgement__c,
            Agreed_Personal_Guarantee__c,
            I_agree_to_the_Personal_Guarantor__c,
            I_agree_to_the_Transaction_Risk_Fee__c,
            Agree_to_Network_Processor_Access_Fee__c,
            I_agree_to_the_PCI_Non_Validation_Fee__c,
            Payrix_Personal_Guarantor_Disclaimer__c,
            Pricing_Model_formula__c,
            Rate_formula__c,
            Payment_Per_Transaction__c,
            Visa_Rate__c,
            Visa_Per_Transaction__c,
            AMEX_Rate__c,
            AMEX_Per_Transaction__c,
            Discover_Rate__c,
            Discover_Per_Transaction__c,
            Mastercard_Rate__c,
            Mastercard_Per_Transaction__c,
            Semi_Annual_Compliance_Fee__c,
            Chargeback_Per_Occurrence__c,
            Account_Maintenance_Fee_F__c,
            Safer_Payments__c,
            Monthly_Statement_Fee_F__c,
            Annual_Membership_Fee_F__c,
            Minimum_Monthly_Discount_F__c,
            ACH_Batch_Fee_F__c,
            Non_Sufficient_Funds_F__c,
            Application_Fee_F__c,
            Pin_Debit_Fee__c,
            Transaction_Risk_Fee__c,
            PCI_Non_Validation_Fee__c,
            Network_and_Processor_Access_Fee__c,
            No_Personal_Guarantor_Approved__c,
            Billing_Schedule__c,
            Enroll_in_Next_Day_Funding__c
            FROM Payment_Processing_NEW__c 
            WHERE Id = : recordId 
            LIMIT 1
        ];
        Id userId  = UserInfo.getUserId();
        pprRec.Onboardings__r[0].IP_address__c = RevelOnboardingController.getCurrentIPAddress();
        pprRec.Onboardings__r[0].Date_Time_PPR_Status_updated__c = SYSTEM.now();
        JSONGeneratorSafe jsGen = new JSONGeneratorSafe(SYSTEM.JSON.createGenerator(true));
        System.debug('pprRec output');
        System.debug(pprRec);
        System.debug(pprRec.Onboardings__r[0]);
        jsGen.Internal.writeStartObject();    
        jsGen.Internal.writeFieldName('Payment_Processing_NEW__c');
        jsGen.Internal.writeStartObject();
        // Create JSON data for Gen and call

                jsGen.writeStringField('Id', pprRec.Id);
                //start PPR fields ( pprRec.Onboardings__r[0].Payment_Processing_Submitter__r.Phone != null ? pprRec.Onboardings__r[0].Payment_Processing_Submitter__r.Phone : '' )
                jsGen.writeStringField('Onboarding__r.Payment_Processing_Submitter__r.Name', pprRec.Onboardings__r[0].PPR_App_Contact__r.Name);
                jsGen.writeStringField('Onboarding__r.Payment_Processing_Submitter__r.Email', pprRec.Onboardings__r[0].PPR_App_Contact__r.Email);
                jsGen.writeStringField('Onboarding__r.Payment_Processing_Submitter__r.Phone', ( pprRec.Onboardings__r[0].PPR_App_Contact__r.Phone != null ? pprRec.Onboardings__r[0].PPR_App_Contact__r.Phone : '' ));
                jsGen.writeDateTimeField('Onboarding__r.Date_Time_PPR_Status_updated__c', pprRec.Onboardings__r[0].Date_Time_PPR_Status_updated__c);
                jsGen.writeStringField('Onboarding__r.IP_address__c', pprRec.Onboardings__r[0].IP_address__c);
                jsGen.writeStringField('Entity_Name__c', pprRec.Entity_Name__c);
                jsGen.writeStringField('Business_Legal_Structure__c', pprRec.Business_Legal_Structure__c);
                jsGen.writeStringField('Account_Name__c', pprRec.Account_Name__c);
                jsGen.writeStringField('Account_Description__c', pprRec.Account_Description__c);
                jsGen.writeStringField('Federal_Tax_Information_number__c', pprRec.Federal_Tax_Information_number__c);
                jsGen.writeStringField('Entity_Primary_URL__c', pprRec.Entity_Primary_URL__c);
                jsGen.writeStringField('Entity_Phone__c', pprRec.Entity_Phone__c);
                jsGen.writeStringField('Business_Email__c', pprRec.Business_Email__c);
                jsGen.writeDateField('Date_Founded__c', pprRec.Date_Founded__c);
                jsGen.writeBooleanField('Public_Company__c', pprRec.Public_Company__c);
                jsGen.writeStringField('DBA_Street_1__c', pprRec.DBA_Street_1__c);
                jsGen.writeStringField('DBA_CIty__c', pprRec.DBA_CIty__c);
                jsGen.writeStringField('DBA_State__c', pprRec.DBA_State__c);
                jsGen.writeStringField('DBA_Postal_Code__c', pprRec.DBA_Postal_Code__c);
                jsGen.writeStringField('DBA_Country__c', pprRec.DBA_Country__c);
                jsGen.writeStringField('Industry_Category__c', pprRec.Industry_Category__c);
                jsGen.writeStringField('Bank_Name__c', pprRec.Bank_Name__c);
                jsGen.writeStringField('Direct_Deposit_Account_Type__c', pprRec.Direct_Deposit_Account_Type__c);
                if (pprRec.Direct_Deposit_Account_Type__c == 'Checking') {
                    jsGen.writeStringField('Bank_Account_Type_WorldPay__c', pprRec.Bank_Account_Type_WorldPay__c);
                } else {
                    jsGen.writeStringField('Bank_Account_Type_WorldPay__c', '');
                }
                jsGen.writeStringField('Accounting_Number1__c', 'XXXX' + (pprRec.Accounting_Number1__c != null ? pprRec.Accounting_Number1__c.right(4) : ''));
                jsGen.writeStringField('Routing_Number1__c', 'XXXX' + (pprRec.Routing_Number1__c != null ? pprRec.Routing_Number1__c.right(4) : ''));
                jsGen.writeNumberField('Percentage_of_Card_swipe_transactions__c', pprRec.Percentage_of_Card_swipe_transactions__c);
                jsGen.writeNumberField('Percentage_of_Manual_transactions__c', pprRec.Percentage_of_Manual_transactions__c);
                jsGen.writeNumberField('eCommerce_Transaction_Percent__c', pprRec.eCommerce_Transaction_Percent__c);
                jsGen.writeNumberField('Average_credit_debit_transaction_amount__c', pprRec.Average_credit_debit_transaction_amount__c);
                jsGen.writeNumberField('Total_yearly_credit_debit_sales_volume__c', pprRec.Total_yearly_credit_debit_sales_volume__c);
                jsGen.writeStringField('How_many_Ben_Owners_own_25_or_more__c', pprRec.How_many_Ben_Owners_own_25_or_more__c);
                jsGen.writeStringField('Controller_Name__c', pprRec.Controller_Name__c);
                jsGen.writeStringField('Controller_Job_Title__c', pprRec.Controller_Job_Title__c);
                jsGen.writeStringField('Controller_SSN__c', 'XXX-XX-' + (pprRec.Controller_SSN__c != null ? pprRec.Controller_SSN__c.right(4) : ''));
                jsGen.writeDateField('Controller_Date_of_Birth__c', pprRec.Controller_Date_of_Birth__c);
                jsGen.writeStringField('Controller_Email__c', pprRec.Controller_Email__c);
                jsGen.writeStringField('Controller_Phone_Number__c', pprRec.Controller_Phone_Number__c);
                jsGen.writeStringField('Controller_Street_1__c', pprRec.Controller_Street_1__c);
                jsGen.writeStringField('Controller_Street_2__c', ( pprRec.Controller_Street_2__c != null ? pprRec.Controller_Street_2__c : '' ));
                jsGen.writeStringField('Controller_City__c', pprRec.Controller_City__c);
                jsGen.writeStringField('Controller_State__c', pprRec.Controller_State__c);
                jsGen.writeStringField('Controller_Postal_Code__c', pprRec.Controller_Postal_Code__c);
                jsGen.writeStringField('Controller_Country__c', pprRec.Controller_Country__c);
                if (Integer.valueOf(pprRec.How_many_Ben_Owners_own_25_or_more__c) != 0) {
                    jsGen.writeStringField('Is_Controller_Beneficial_Owner__c', pprRec.Is_Controller_Beneficial_Owner__c);
                    if (pprRec.Is_Controller_Beneficial_Owner__c == 'Yes') {
                        jsGen.writeNumberField('Controller_Ownership_Percentage__c', pprRec.Controller_Ownership_Percentage__c);
                    } else {
                        jsGen.writeStringField('Controller_Ownership_Percentage__c', '');
                    }
                } else {
                    jsGen.writeStringField('Is_Controller_Beneficial_Owner__c', '');
                    jsGen.writeStringField('Controller_Ownership_Percentage__c', '');
                }
                if (pprRec.Is_Controller_Beneficial_Owner__c == 'No' &&
                Integer.valueOf(pprRec.How_many_Ben_Owners_own_25_or_more__c) >= 1) {
                    jsGen.writeStringField('Representative_1_Name__c', pprRec.Representative_1_Name__c);
                    jsGen.writeNumberField('Rep_1_Ownership_Percentage__c', pprRec.Rep_1_Ownership_Percentage__c);
                    jsGen.writeStringField('Rep_1_Job_Title__c', pprRec.Rep_1_Job_Title__c);
                    jsGen.writeStringField('Rep1_SSN__c', 'XXX-XX-' + (pprRec.Rep1_SSN__c != null ? pprRec.Rep1_SSN__c.right(4) : ''));
                    jsGen.writeDateField('Rep_1_Date_of_Birth__c', pprRec.Rep_1_Date_of_Birth__c);
                    jsGen.writeStringField('Rep_1_Email__c', pprRec.Rep_1_Email__c);
                    jsGen.writeStringField('Rep_1_Phone_Number__c', pprRec.Rep_1_Phone_Number__c);
                    //( pprRec.Rep_1_address_street_2__c != null ? pprRec.Rep_1_address_street_2__c : '' )
                    jsGen.writeStringField('Rep_1_Address_street_1__c', pprRec.Rep_1_Address_street_1__c);
                    jsGen.writeStringField('Rep_1_address_street_2__c', ( pprRec.Rep_1_address_street_2__c != null ? pprRec.Rep_1_address_street_2__c : '' ));
                    jsGen.writeStringField('Rep_1_City__c', pprRec.Rep_1_City__c);
                    jsGen.writeStringField('Rep_1_State__c', pprRec.Rep_1_State__c);
                    jsGen.writeStringField('Rep_1_Postal_Code__c', pprRec.Rep_1_Postal_Code__c);
                    jsGen.writeStringField('Ben_Owner_1_Country__c', pprRec.Ben_Owner_1_Country__c);
                } else {
                    jsGen.writeStringField('Representative_1_Name__c', '');
                    jsGen.writeStringField('Rep_1_Ownership_Percentage__c', '');
                    jsGen.writeStringField('Rep_1_Job_Title__c', '');
                    jsGen.writeStringField('Rep1_SSN__c', '');
                    jsGen.writeStringField('Rep_1_Date_of_Birth__c', '');
                    jsGen.writeStringField('Rep_1_Email__c', '');
                    jsGen.writeStringField('Rep_1_Phone_Number__c', '');
                    jsGen.writeStringField('Rep_1_Address_street_1__c', '');
                    jsGen.writeStringField('Rep_1_address_street_2__c', '');
                    jsGen.writeStringField('Rep_1_City__c', '');
                    jsGen.writeStringField('Rep_1_State__c', '');
                    jsGen.writeStringField('Rep_1_Postal_Code__c', '');
                    jsGen.writeStringField('Ben_Owner_1_Country__c', '');
                }
                if (Integer.valueOf(pprRec.How_many_Ben_Owners_own_25_or_more__c) >= 2) {
                    jsGen.writeStringField('Representative_2_Name__c', pprRec.Representative_2_Name__c);
                    jsGen.writeNumberField('Rep_2_Ownership_Percentage__c', pprRec.Rep_2_Ownership_Percentage__c);
                    jsGen.writeStringField('Rep_2_Job_Title__c', pprRec.Rep_2_Job_Title__c);
                    jsGen.writeStringField('Rep2_SSN__c', 'XXX-XX-' + (pprRec.Rep2_SSN__c != null ? pprRec.Rep2_SSN__c.right(4) : ''));
                    jsGen.writeDateField('Rep_2_Date_of_Birth__c', pprRec.Rep_2_Date_of_Birth__c);
                    jsGen.writeStringField('Rep_2_Email__c', pprRec.Rep_2_Email__c);
                    jsGen.writeStringField('Rep_2_Phone_Number__c', pprRec.Rep_2_Phone_Number__c);
                    jsGen.writeStringField('Rep_2_address_street_1__c', pprRec.Rep_2_address_street_1__c);
                    jsGen.writeStringField('Rep_2_address_street_2__c', ( pprRec.Rep_2_address_street_2__c != null ? pprRec.Rep_2_address_street_2__c : '' ));
                    jsGen.writeStringField('Rep_2_City__c', pprRec.Rep_2_City__c);
                    jsGen.writeStringField('Rep_2_State__c', pprRec.Rep_2_State__c);
                    jsGen.writeStringField('Rep_2_Postal_Code__c', pprRec.Rep_2_Postal_Code__c);
                    jsGen.writeStringField('Ben_Owner_2_Country__c', pprRec.Ben_Owner_2_Country__c);
                } else {
                    jsGen.writeStringField('Representative_2_Name__c', '');
                    jsGen.writeStringField('Rep_2_Ownership_Percentage__c', '');
                    jsGen.writeStringField('Rep_2_Job_Title__c', '');
                    jsGen.writeStringField('Rep2_SSN__c', '');
                    jsGen.writeStringField('Rep_2_Date_of_Birth__c', '');
                    jsGen.writeStringField('Rep_2_Email__c', '');
                    jsGen.writeStringField('Rep_2_Phone_Number__c', '');
                    jsGen.writeStringField('Rep_2_address_street_1__c', '');
                    jsGen.writeStringField('Rep_2_address_street_2__c', '');
                    jsGen.writeStringField('Rep_2_City__c', '');
                    jsGen.writeStringField('Rep_2_State__c', '');
                    jsGen.writeStringField('Rep_2_Postal_Code__c', '');
                    jsGen.writeStringField('Ben_Owner_2_Country__c', '');
                }
                if (Integer.valueOf(pprRec.How_many_Ben_Owners_own_25_or_more__c) >= 3) {
                    jsGen.writeStringField('Representative_3_Name__c', pprRec.Representative_3_Name__c);
                    jsGen.writeNumberField('Rep_3_Ownership_Percentage__c', pprRec.Rep_3_Ownership_Percentage__c);
                    jsGen.writeStringField('Rep_3_Job_Title__c', pprRec.Rep_3_Job_Title__c);
                    jsGen.writeStringField('Rep3_SSN__c', (pprRec.Rep3_SSN__c != null ? pprRec.Rep3_SSN__c.right(4) : ''));
                    jsGen.writeDateField('Rep_3_Date_of_Birth__c', pprRec.Rep_3_Date_of_Birth__c);
                    jsGen.writeStringField('Rep_3_Email__c', pprRec.Rep_3_Email__c);
                    jsGen.writeStringField('Rep_3_Phone_Number__c', pprRec.Rep_3_Phone_Number__c);
                    jsGen.writeStringField('Rep_3_address_street_1__c', pprRec.Rep_3_address_street_1__c);
                    jsGen.writeStringField('Rep_3_address_street_2__c', ( pprRec.Rep_3_address_street_2__c != null ? pprRec.Rep_3_address_street_2__c : '' ));
                    jsGen.writeStringField('Rep_3_City__c', pprRec.Rep_3_City__c);
                    jsGen.writeStringField('Rep_3_State__c', pprRec.Rep_3_State__c);
                    jsGen.writeStringField('Rep_3_Postal_Code__c', pprRec.Rep_3_Postal_Code__c);
                    jsGen.writeStringField('Ben_Owner_3_Country__c', pprRec.Ben_Owner_3_Country__c);
                } else {
                    jsGen.writeStringField('Representative_3_Name__c', '');
                    jsGen.writeStringField('Rep_3_Ownership_Percentage__c', '');
                    jsGen.writeStringField('Rep_3_Job_Title__c', '');
                    jsGen.writeStringField('Rep3_SSN__c', '');
                    jsGen.writeStringField('Rep_3_Date_of_Birth__c', '');
                    jsGen.writeStringField('Rep_3_Email__c', '');
                    jsGen.writeStringField('Rep_3_Phone_Number__c', '');
                    jsGen.writeStringField('Rep_3_address_street_1__c', '');
                    jsGen.writeStringField('Rep_3_address_street_2__c', '');
                    jsGen.writeStringField('Rep_3_City__c', '');
                    jsGen.writeStringField('Rep_3_State__c', '');
                    jsGen.writeStringField('Rep_3_Postal_Code__c', '');
                    jsGen.writeStringField('Ben_Owner_3_Country__c', '');
                }
                if (Integer.valueOf(pprRec.How_many_Ben_Owners_own_25_or_more__c) == 4) {
                    jsGen.writeStringField('Representative_4_Name__c', pprRec.Representative_4_Name__c);
                    jsGen.writeNumberField('Rep_4_Ownership_Percentage__c', pprRec.Rep_4_Ownership_Percentage__c);
                    jsGen.writeStringField('Rep_4_Job_Title__c', pprRec.Rep_4_Job_Title__c);
                    jsGen.writeStringField('Rep4_SSN__c', (pprRec.Rep4_SSN__c != null ? pprRec.Rep4_SSN__c.right(4) : ''));
                    jsGen.writeDateField('Rep_4_Date_of_Birth__c', pprRec.Rep_4_Date_of_Birth__c);
                    jsGen.writeStringField('Rep_4_Email__c', pprRec.Rep_4_Email__c);
                    jsGen.writeStringField('Rep_4_Phone_Number__c', pprRec.Rep_4_Phone_Number__c);
                    jsGen.writeStringField('Rep_4_address_street_1__c', pprRec.Rep_4_address_street_1__c);
                    jsGen.writeStringField('Rep_4_address_street_2__c', ( pprRec.Rep_4_address_street_2__c != null ? pprRec.Rep_4_address_street_2__c : '' ));
                    jsGen.writeStringField('Rep_4_City__c', pprRec.Rep_4_City__c);
                    jsGen.writeStringField('Rep_4_State__c', pprRec.Rep_4_State__c);
                    jsGen.writeStringField('Rep_4_Postal_Code__c', pprRec.Rep_4_Postal_Code__c);
                    jsGen.writeStringField('Ben_Owner_4_Country__c', pprRec.Ben_Owner_4_Country__c);
                } else {
                    jsGen.writeStringField('Representative_4_Name__c', '');
                    jsGen.writeStringField('Rep_4_Ownership_Percentage__c', '');
                    jsGen.writeStringField('Rep_4_Job_Title__c', '');
                    jsGen.writeStringField('Rep4_SSN__c', '');
                    jsGen.writeStringField('Rep_4_Date_of_Birth__c', '');
                    jsGen.writeStringField('Rep_4_Email__c', '');
                    jsGen.writeStringField('Rep_4_Phone_Number__c', '');
                    jsGen.writeStringField('Rep_4_address_street_1__c', '');
                    jsGen.writeStringField('Rep_4_address_street_2__c', '');
                    jsGen.writeStringField('Rep_4_City__c', '');
                    jsGen.writeStringField('Rep_4_State__c', '');
                    jsGen.writeStringField('Rep_4_Postal_Code__c', '');
                    jsGen.writeStringField('Ben_Owner_4_Country__c', '');
                }
                jsGen.writeStringField('Pricing_Model_formula__c', pprRec.Pricing_Model_formula__c);
                jsGen.writeNumberField('Rate_formula__c', pprRec.Rate_formula__c);
                jsGen.writeStringField('Payment_Per_Transaction__c', pprRec.Payment_Per_Transaction__c);
                jsGen.writeNumberField('Visa_Rate__c', pprRec.Visa_Rate__c);
                jsGen.writeNumberField('Visa_Per_Transaction__c', pprRec.Visa_Per_Transaction__c);
                jsGen.writeNumberField('AMEX_Rate__c', pprRec.AMEX_Rate__c);
                jsGen.writeNumberField('AMEX_Per_Transaction__c', pprRec.AMEX_Per_Transaction__c);
                jsGen.writeNumberField('Discover_Rate__c', pprRec.Discover_Rate__c);
                jsGen.writeNumberField('Discover_Per_Transaction__c', pprRec.Discover_Per_Transaction__c);
                jsGen.writeNumberField('Mastercard_Rate__c', pprRec.Mastercard_Rate__c);
                jsGen.writeNumberField('Mastercard_Per_Transaction__c', pprRec.Mastercard_Per_Transaction__c);
                jsGen.writeNumberField('Semi_Annual_Compliance_Fee__c', pprRec.Semi_Annual_Compliance_Fee__c);
                jsGen.writeNumberField('Chargeback_Per_Occurrence__c', pprRec.Chargeback_Per_Occurrence__c);
                jsGen.writeNumberField('Account_Maintenance_Fee_F__c', pprRec.Account_Maintenance_Fee_F__c);
                jsGen.writeNumberField('Safer_Payments__c', pprRec.Safer_Payments__c);
                jsGen.writeNumberField('Monthly_Statement_Fee_F__c', pprRec.Monthly_Statement_Fee_F__c);
                jsGen.writeNumberField('Annual_Membership_Fee_F__c', pprRec.Annual_Membership_Fee_F__c);
                jsGen.writeNumberField('Minimum_Monthly_Discount_F__c', pprRec.Minimum_Monthly_Discount_F__c);
                jsGen.writeNumberField('ACH_Batch_Fee_F__c', pprRec.ACH_Batch_Fee_F__c);
                jsGen.writeNumberField('Non_Sufficient_Funds_F__c', pprRec.Non_Sufficient_Funds_F__c);
                jsGen.writeNumberField('Application_Fee_F__c', pprRec.Application_Fee_F__c);
                jsGen.writeNumberField('Pin_Debit_Fee__c', pprRec.Pin_Debit_Fee__c);
                jsGen.writeStringField('Transaction_Risk_Fee__c', pprRec.Transaction_Risk_Fee__c);
                jsGen.writeNumberField('PCI_Non_Validation_Fee__c', pprRec.PCI_Non_Validation_Fee__c);
                jsGen.writeNumberField('Network_and_Processor_Access_Fee__c', pprRec.Network_and_Processor_Access_Fee__c);
                jsGen.writeBooleanField('No_Personal_Guarantor_Approved__c', pprRec.No_Personal_Guarantor_Approved__c);
                jsGen.writeStringField('Billing_Schedule__c', pprRec.Billing_Schedule__c);
                jsGen.writeStringField('Enroll_in_Next_Day_Funding__c', pprRec.Enroll_in_Next_Day_Funding__c);
            jsGen.Internal.writeEndObject(); 
        jsGen.Internal.writeEndObject();
        
        String jsonData = jsGen.Internal.getAsString();
        System.debug('JSON Data: ' + jsonData);
        return jsonData;
    }
/** END --- DOCUSIGN APIS **/
}