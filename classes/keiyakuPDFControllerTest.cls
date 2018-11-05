@isTest
public with sharing class keiyakuPDFControllerTest {
    static testMethod void testKeiyakuPDFController() {
        Test.startTest();
        TestDataFactory.createAllMstData();
        ApexPages.currentPage().getParameters().put('id',TestDataFactory.getAgreements()[0].Id);
        keiyakuPDFController controller = new keiyakuPDFController();
        Test.stopTest();
    }
}