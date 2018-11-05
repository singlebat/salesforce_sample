@isTest
public with sharing class ContractHosyoukinPDfControllerTest {
    static testMethod void testContractHosyoukinPDfController(){
        Test.startTest();
        TestDataFactory.createAllMstData();
        Billed__c Billed = TestDataFactory.getBilleds()[0];
        Billed.Type__c = '保証金返金';
        update Billed;
        ApexPages.currentPage().getParameters().put('id',TestDataFactory.getAgreements()[0].Id);
        ContractHosyoukinPDfController controller = new ContractHosyoukinPDfController();
         
        Test.stopTest();
    }
}