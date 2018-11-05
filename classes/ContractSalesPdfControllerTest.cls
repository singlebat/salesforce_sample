@isTest
public with sharing class ContractSalesPdfControllerTest {
    static testMethod void testCreateMultipleSalesBilled() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        
        ApexPages.currentPage().getParameters().put('id',TestDataFactory.getAgreements()[0].Id);
        ContractSalesPdfController controller = new ContractSalesPdfController();
        Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}