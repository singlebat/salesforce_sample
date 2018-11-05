@isTest
public with sharing class KikankanryouControllerTest {
    static testMethod void testKikankanryouController() {
        Test.startTest();
        TestDataFactory.createAllMstData();
        ApexPages.currentPage().getParameters().put('id',TestDataFactory.getAgreements()[0].Id);
        KikankanryouController controller = new KikankanryouController();
        Test.stopTest();
    }
}