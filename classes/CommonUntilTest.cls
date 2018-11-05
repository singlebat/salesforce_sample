@isTest
public with sharing class CommonUntilTest {
    static testMethod void testCommonUntilTest() {
        Test.startTest();
        createData();
        CommonUntil.getOwnerAccount();
        CommonUntil.getPicklist('InventoryProduct__c','Rank__c');
        CommonUntil.getCopiableFieldNames('Estimate__c');
        CommonUntil.getEstimateById(TestDataFactory.getLeaseEstimate()[0].Id);
        CommonUntil.getReportId('在庫');
        CommonUntil.getInvOppProduct(TestDataFactory.getOppProducts());
        CommonUntil.updateRelDelivery(TestDataFactory.getOppProducts(),TestDataFactory.getInvOppProducts(),TestDataFactory.getDeliverys()[0].Id);
        CommonUntil.cancelInvProductHold(CommonUntil.getZaikoId(TestDataFactory.getInvOppProducts()),TestDataFactory.getOpportunity()[0].Id);
        
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}