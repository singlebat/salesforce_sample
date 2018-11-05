@isTest
public with sharing class EditMitumoriControllerTest {
    static testMethod void testEditMitumoriController() {
        Test.startTest();
        createData();
        
        EditMitumoriController.init(TestDataFactory.getLeaseEstimate()[0].Id);
        Object rate = 6;
        
        Estimate__c quoteNew = TestDataFactory.getLeaseEstimate()[0].clone(false, false, false, false);
        insert quoteNew;
        EditMitumoriController.updateOther(quoteNew.Id , rate, String.valueOf(Date.today()), String.valueOf(Date.today()));
        EditMitumoriController.getLeaseRateMasterInfo(TestDataFactory.getLeaseRateMaster()[0].Id);
        EditMitumoriController.updateOpportunity(TestDataFactory.getOpportunity()[0].Id,'プロセス確認',String.valueOf(Date.today()),'','','101室');
        
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}