@isTest
public with sharing class CreateAllMultipleBilledTest {
    static testMethod void testCreateMultipleBilled() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        List<Agreement__c> agreement=TestDataFactory.getAgreements();
        agreement[0].Status__c = '契約済';
        update agreement[0];
        CreateAllMultipleBilled.createAllBilled('2018','12','振込','一致する','20',TestDataFactory.getsalesHojinAccount()[0].Id,TestDataFactory.getAgreements()[0].Id);
        CreateAllMultipleBilled.createAllBilled('2018','12','振込','一致する','20','','');
        CreateAllMultipleBilled.getAllBilledDetailIds('2018','12','振込','一致する','20',TestDataFactory.getsalesHojinAccount()[0].Id,TestDataFactory.getAgreements()[0].Id);
        Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}