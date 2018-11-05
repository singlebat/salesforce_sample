@isTest
private class ContractPdfControllerTest {

    static testMethod void testContractPdfController() {
        // TO DO: implement unit test
         // TO DO: implement unit test
        Test.startTest();
        createData();
        List<BilledDetail__c> bm=TestDataFactory.getBilledDetails();
        
        system.debug('Agreement__c:'+bm[0].Agreement__c);
        ApexPages.currentPage().getParameters().put('id',bm[0].Agreement__c);
        ApexPages.currentPage().getParameters().put('type','ダメージ料金請求');
        ContractPdfController controller = new ContractPdfController();
        ApexPages.currentPage().getParameters().put('type','ダメージ料金請求以外');
        ContractPdfController controller1 = new ContractPdfController();
        
        Test.stopTest();
    }
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}