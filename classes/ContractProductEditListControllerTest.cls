@isTest
private class ContractProductEditListControllerTest {

    static testMethod void testContractProductEditListController() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        
        Agreement__c agreement = TestDataFactory.getAgreements()[0];
        ContractProductEditListController.getInitInfo(agreement.Id,'Agreement__c');
        
        
        
        Purchase__c pc=TestDataFactory.getPurchases()[0];
        List<InventoryOpportunityProduct__c> invOppProducts=TestDataFactory.getInvOppProducts();
        system.debug(pc.Id);
        
        
        ContractProductEditListController.storing(pc.Id,invOppProducts);
        
        Delivery__c dc=TestDataFactory.getDeliverys()[0];
        ContractProductEditListController.updateInvOppProduct(invOppProducts,dc.Id,'');
        ContractProductEditListController.updateInvOppProduct(invOppProducts,dc.Id,'メンテ済');
        ContractProductEditListController.deliveryTehai(dc.Id,invOppProducts);
        ContractProductEditListController.delivery(dc.Id,invOppProducts);
        
        dc.DeliveryType__c = '搬出';
        update dc;
        ContractProductEditListController.delivery(dc.Id,invOppProducts);
        
        Opportunity op=TestDataFactory.getOpportunity()[0];
        ContractProductEditListController.updateOpp(op.Id,'リース');
        Test.stopTest();
    }
    
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}