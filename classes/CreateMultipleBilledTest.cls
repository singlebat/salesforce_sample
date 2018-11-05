@isTest
public with sharing class CreateMultipleBilledTest {

    static testMethod void testCreateMultipleBilled() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        List<Agreement__c> agreement=TestDataFactory.getAgreements();
        agreement[0].Status__c = '契約済';
        update agreement[0];
        delete TestDataFactory.getBilledDetails();
        CreateMultipleBilled.createBilledByAgreementId(agreement[0].Id);
        agreement[0].Status__c = '契約解除待ち';
        update agreement[0];
        CreateMultipleBilled.createBilledByAgreementId(agreement[0].Id);
        system.debug(agreement);
        //CreateMultipleBilled.createBilledByBilledDate(Date.today());
        Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}