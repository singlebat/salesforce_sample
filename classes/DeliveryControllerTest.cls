@isTest
public with sharing class DeliveryControllerTest {
	static testMethod void testDeliveryController() {
        Test.startTest();
        createData();
        Delivery__c Delivery = new Delivery__c(DeliveryStatus__c = '依頼済',Estimate__c=TestDataFactory.getLeaseEstimate()[0].Id,Agreement__c = TestDataFactory.getAgreements()[0].Id);
        insert Delivery;
        List<User> u=[select Id from User ];
        DeliveryController.getDeliverys(TestDataFactory.getAgreements()[0].Id,'Agreement__c');
        DeliveryController.getDeliverys(TestDataFactory.getLeaseEstimate()[0].Id,'Estimate__c');
        DeliveryController.createDeliveryIn(TestDataFactory.getOppProducts(),'new',String.valueOf(Date.today()),true,u[0].Id,'');
        DeliveryController.createDeliveryOut(TestDataFactory.getInvOppProducts(),'new',String.valueOf(Date.today()),true,u[0].Id,'');
        DeliveryController.getDeliveryInfo(Delivery.Id);

        Test.stopTest();
    }
	
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}