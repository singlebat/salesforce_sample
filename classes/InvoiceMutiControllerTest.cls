@isTest
public with sharing class InvoiceMutiControllerTest {
    static testMethod void testInvoiceMutiController(){
        Test.startTest();
        TestDataFactory.createAllMstData();
        ApexPages.currentPage().getParameters().put('year','2018');
        ApexPages.currentPage().getParameters().put('month','12');
        ApexPages.currentPage().getParameters().put('PaywayValue','振込');
        ApexPages.currentPage().getParameters().put('localValue','一致する');
        ApexPages.currentPage().getParameters().put('day','20');
        ApexPages.currentPage().getParameters().put('request',TestDataFactory.getsalesHojinAccount()[0].Id);
        ApexPages.currentPage().getParameters().put('questionNO',TestDataFactory.getAgreements()[0].Id);
        InvoiceMutiController controller = new InvoiceMutiController();
        Test.stopTest();
    }
}