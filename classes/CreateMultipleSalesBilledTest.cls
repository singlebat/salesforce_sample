@isTest
public with sharing class CreateMultipleSalesBilledTest {
    static testMethod void testCreateMultipleSalesBilled() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        List<Agreement__c> agreement=TestDataFactory.getAgreements();
        delete TestDataFactory.getBilledDetails();
        agreement[0].Status__c = '契約済';
        update agreement[0];
        CreateMultipleSalesBilled.createBilledByAgreementId(agreement[0].id,'');
        agreement[0].Status__c = '契約解除待ち';
        update agreement[0];
        CreateMultipleSalesBilled.createBilledByAgreementId(agreement[0].id,'保証金');
        Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}