global with sharing class AgreementAutomaticallyUpdateBatch implements Database.Batchable<sObject>{
    //データ取得
    global Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'SELECT Id,Name,AutoOrManual__c,LeaseEndAgreementUpdate__c FROM Agreement__c ';
        query += ' WHERE LeaseEndAgreementUpdate__c <= TODAY';
        List<Agreement__c> scopes = Database.query(query);
        system.debug(scopes);
        return Database.getQueryLocator(query);
    }

    //開始
    global void execute(Database.BatchableContext BC, List<Agreement__c> scopes){
    	//契約更新対象リスト
    	List<Agreement__c> updateAgreements = new List<Agreement__c>();
        //バッチの処理を記述
        for (Agreement__c agreement : scopes) {
        	if (agreement.AutoOrManual__c == '自動') {
        	    //agreement.KeiyakuUpdateFlag__c = true;
        	    agreement.Status__c = '契約更新手続き中';
        	    updateAgreements.add(agreement);
        	}
        }
        //契約の更新、更新した後、リース満了期間通知書をプロセスビルダーより作成する。
        if (updateAgreements.size() > 0) {
            update updateAgreements;
        }
    }

    //完了
    global void finish(Database.BatchableContext BC)
    {
        //完了後の処理があれば
    }
}