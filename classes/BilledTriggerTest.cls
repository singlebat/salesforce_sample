@isTest
public with sharing class BilledTriggerTest {
    static testMethod void testBilledTrigger() {
        Test.startTest();
        createData();
        delete TestDataFactory.getBilleds();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}