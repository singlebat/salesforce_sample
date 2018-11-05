global with sharing class DeliveryCompletedUpdateBatch implements Database.Batchable<sObject>{
    //データ取得
    global Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'SELECT Id,Name,InventoryProduct__c';
        query += ' FROM InventoryOpportunityProduct__c WHERE OpportunityProduct__r.PurchaseYoteiDate__c = TODAY AND HaisouType__c = \'顧客直送\'';
        return Database.getQueryLocator(query);
    }
  
    //開始
    global void execute(Database.BatchableContext BC, List<InventoryOpportunityProduct__c> scopes){
    	//在庫商品のD/L（搬入）完了用リスト
        List<InventoryProduct__c> invProducts = new List<InventoryProduct__c>();
        //バッチの処理を記述
        for (InventoryOpportunityProduct__c invOppProduct : scopes) {
            //在庫案件商品のステータスを「リース中」に更新する。且   在庫商品のステータスを「リース中」に更新する。
        	invOppProduct.Status__c = 'リース中';
        	if (invOppProduct.InventoryProduct__c != null) {
        	    //在庫商品のステータス
        	    InventoryProduct__c invProduct = new InventoryProduct__c();
        	    invProduct.Id = invOppProduct.InventoryProduct__c;
        	    invProduct.CurrentStatus__c = 'リース中';
        	    invProduct.CurrentStatusAuxiliary__c = null;
                invProducts.add(invProduct);
        	}

        }
        update scopes;
        update invProducts;
    }
  
    //完了
    global void finish(Database.BatchableContext BC)
    {
        //完了後の処理があれば
    }
}