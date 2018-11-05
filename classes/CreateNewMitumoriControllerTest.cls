@isTest
public with sharing class CreateNewMitumoriControllerTest {
    static testMethod void testCreateNewMitumori() {
        Test.startTest();
        createData();
        CreateNewMitumoriController.getLeaseRateMasterInfo(TestDataFactory.getLeaseRateMaster()[0].Id);
        Account account = CreateNewMitumoriController.getAccountInfo(TestDataFactory.getOpportunity()[0].Id,'Opportunity');
        //CreateNewMitumoriController.updateEstimateName(TestDataFactory.getLeaseEstimate()[0].Id);
        CreateNewMitumoriController.createOpportunity(account.Id , '案件' , String.valueOf(Date.today()) , null,null,'101室');
        CreateNewMitumoriController.Request re= new CreateNewMitumoriController.Request();
		re.oppId=TestDataFactory.getOpportunity()[0].Id;
		re.estimateId=TestDataFactory.getLeaseEstimate()[0].Id;
		re.leaseStart=Date.today();
		re.leaseStartEnd=Date.today();
		re.monthlyLeaseRate=6;
		List<CreateNewMitumoriController.Request> requests =new List<CreateNewMitumoriController.Request>();
		requests.add(re);
		CreateNewMitumoriController.createDeliveryAndAgreement(requests);
		
		
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}